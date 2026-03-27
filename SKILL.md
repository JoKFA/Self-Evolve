---
name: self-evolve
description: >
  Persistent learning loop that makes Claude better across sessions by logging
  errors, corrections, and decisions to structured memory files, then reading
  them back before future tasks to prevent repeated mistakes. Use when session
  is ending, after completing significant work, when user says "evolve",
  "learn from this", "update your memory", "current process is complete",
  "this phase is done", or "/self-evolve". Also act on <read-triggers> and
  <error-detected> hook blocks. Make sure to use this skill whenever a session
  involved tool calls, code changes, errors, or user corrections, even if the
  user doesn't explicitly ask to evolve.
---

# Self-Evolve

A persistent learning loop that makes Claude genuinely better across sessions. Not just logging — ensuring learnings get read, applied, and verified. Two phases: **pre-task** (consult memory before acting) and **post-session** (capture what happened).

## When to Use

- Session ending after significant work
- User says "evolve", "learn from this", "current process is complete", "this phase is done"
- `<read-triggers>` block appears (Phase 0 only)
- `<error-detected>` block appears (log immediately)

**When NOT to use:** Trivial Q&A, sub-agent tasks, sessions with no tool calls or code changes. If concurrent sessions on the same project, use timestamps in entry IDs to avoid collisions.

## Quick Reference

| Step | What | When |
|---|---|---|
| **Phase 0** | Check Read Triggers, read relevant entries, scaffold if missing | Before significant tasks |
| **Route** | Pick level (project/codebase/global) + file | Before each entry |
| **Review** | Scan session + Executability Gate + update Prevention-Counts | Session end |
| **Dedup** | Search existing entries, bump Recurrence-Count if match | Before writing |
| **Promote** | Pipeline: LOGGED > TESTED > ESCALATED > PROMOTED > MONITORED | After writing |
| **Report** | Output summary with metrics | Session end |

---

## Phase 0 — Pre-Task Check

Run BEFORE starting significant tasks, not at session end. Triggered by `<read-triggers>` hook.

1. Locate current project's memory directory (`~/.claude/projects/<project-hash>/memory/`). Claude Code derives the project hash from the working directory path — run `ls ~/.claude/projects/` to discover existing hashes, or check the auto-loaded MEMORY.md path in your conversation context.
2. **If memory files are missing or malformed** — scaffold them first (see below)
3. Check **Read Triggers** section in MEMORY.md
4. If task matches a trigger, read the specified file/section
5. List relevant entries (max 3): "Known risks: [X, Y]"
6. Note which entries were consulted (update Prevention-Count in Review step if they helped)

### Scaffolding Missing Memory Files

Do NOT silently skip Phase 0 because files are missing. Create what's needed:

| What's missing | Action |
|---|---|
| No memory directory | Create `~/.claude/projects/<hash>/memory/` and `memory/learnings/` |
| No MEMORY.md | Create with `## Read Triggers` table (empty) |
| MEMORY.md exists, no Read Triggers section | Append the section |
| No `learnings/` directory | Create with empty ERRORS.md, LEARNINGS.md, DECISIONS.md, FEATURE_REQUESTS.md |
| Learnings file exists but wrong format | Migrate entries into correct template format (see `references/templates.md`), preserving content |
| Learnings file has no domain sections | Add section headers (see `references/templates.md` for examples) |

After scaffolding, continue Phase 0 normally (there just won't be entries yet).

**Maintaining Read Triggers**: When promoting or escalating entries, check if a Read Trigger should be added. When scaffolding new MEMORY.md, always include an empty Read Triggers section.

---

## Route — Pick the Right Target

**Level:**

| Scope | Level |
|---|---|
| Only this project's code/stack/domain | Project |
| 2+ projects or workspace tooling | Codebase |
| Any Claude session outside this workspace | Global |

Quick test: "Different project tomorrow — would I want this?" Yes = codebase+. No = project.

**File:**

| Type | Target |
|---|---|
| Facts, preferences, triggers | `MEMORY.md` |
| Rule for all AI tools | Propose `AGENTS.md` edit (3+ sessions + user confirm) |
| Claude-specific behavior | Propose `CLAUDE.md` edit (3+ sessions + user confirm) |

**MEMORY.md line vs full entry:** If a one-liner changes behavior, put it in MEMORY.md only. If reasoning is needed to apply it, write a full entry in the learnings files.

---

## Review — Scan and Log

Scan conversation for things worth logging. **For entry templates**, read `references/templates.md` in this skill directory.

**Prevention-Count update**: Check entries consulted in Phase 0 — did consulting them actually change behavior and prevent an error? If yes, increment `Prevention-Count` and update `Last-Seen`. The increment happens here (not in Phase 0) because you can only know if an entry helped after the task is done.

### Executability Gate (apply to every entry)

1. **EXECUTABLE**: Phrased as "When [condition], do [action]"? If no, rewrite or don't log.
2. **UNAMBIGUOUS**: Same condition always leads to same action? If context-dependent, add sub-conditions. Too complex, route to DECISIONS.md.
3. **TESTABLE**: How to verify it was applied? Write Resolution Criteria.
4. **NON-OBVIOUS**: Would Claude do the wrong thing without this? If no, don't log.

**Examples:**
```
Bad:  "Be more careful with config files"          -> not executable
Good: "When editing any settings/config file, first check ERRORS.md for known issues with that file"

Bad:  "Remember to test"                           -> not specific
Good: "When fixing a bug, run the failing test before and after the fix"

Bad:  "Handle errors better"                       -> vague
Good: "When a bash command fails with non-zero exit, log to ERRORS.md before retrying"
```

### Dedup

Before writing, search existing entries (use the Grep tool, not bash grep). Match on summary/Pattern-Key. If similar exists, bump `Recurrence-Count`, update `Last-Seen`, add `See Also`.

---

## Promotion Pipeline

```
LOGGED (RC=1,PC=0) --consulted+helped--> TESTED (PC>=1) --RC>=2 or PC>=3--> REVIEW --> PROMOTED --> MONITOR
       |                                                                      ^                        |
       +--recurred, never read--> ESCALATED (RC>=2,PC=0) --add trigger--------+                  revised 2+
                                         |                                                        or stale 30d
                                         +--not executable--> DELETE <------------------------------+
```

**ESCALATED** (RC>=2, PC=0): Entry exists but nobody reads it. Add `Escalated: YYYY-MM-DD` and pick: (a) add Read Trigger, (b) promote to MEMORY.md, (c) convert to CLAUDE.md rule, (d) delete. If already escalated and another session passes, force resolution NOW.

**REVIEW**: Determine target using Route rules. If target is CLAUDE.md or AGENTS.md, run the **CLAUDE.md Promotion Quality Gate** (below) before proposing. Note: reaching REVIEW requires RC>=2 in the pipeline, but CLAUDE.md/AGENTS.md promotion additionally requires the 3+ session threshold from the Route rules — REVIEW is where routing decides the target, not automatic approval. Skill extraction to `superpowers:writing-skills`.

**PROMOTED**: Write to target. Collapse original (keep heading + Status: promoted + Promoted: [target]). Add Read Trigger if applicable. If promoting to a higher level, check lower-level files for narrower versions of the same rule — remove or collapse them with `Superseded-By: [target path]`.

**MONITOR**: User corrects promoted rule? Revise. Revised 2+ times means `Status: unstable`, consider removing. PC=0 for 30+ days, check Read Trigger or mark resolved.

### Pruning

- **Stale**: Last-Seen > 30 days, RC=1, not promoted. Mark stale, delete next session.
- **Useless**: "Would this change behavior?" No, then delete.
- **Conflicting**: Merge into one context-qualified entry.
- **Unstable**: Revised 2+ times. Hold, do NOT promote until stable 2+ sessions.
- **MEMORY.md**: Keep under 150 lines. Prune promoted/resolved first.
- **Learnings files**: Over 100 entries? Aggressively prune stale/resolved. Large files degrade read performance — the system works best when entries are few and high-signal.

---

## CLAUDE.md Promotion Quality Gate

CLAUDE.md is part of every future prompt — every line costs tokens and shapes behavior. Before proposing a rule for CLAUDE.md (or AGENTS.md), run this gate to ensure the addition is worth the space and actually helps.

### Step 1: Read the target file and its neighboring levels

Read the entire CLAUDE.md (or AGENTS.md) that you're proposing to update. Also check the levels above and below — a rule already inherited from global CLAUDE.md doesn't need repeating at codebase level, and promoting to a higher level should supersede narrower versions below. The level hierarchy and paths are documented in the global CLAUDE.md's File Hierarchy section.

### Step 2: Check for similar or conflicting rules

Search the file for rules that cover the same topic, condition, or behavior:

- **Exact duplicate**: The rule already exists. Don't add — just bump the learning's Recurrence-Count.
- **Overlapping**: An existing rule covers a broader or adjacent case. **Enhance** the existing rule rather than adding a new one — combine the conditions or widen the scope.
- **Conflicting**: An existing rule says the opposite or a different action for the same condition. Resolve: either the old rule is outdated (replace it) or the new learning needs a qualifying condition to coexist. Never leave two contradictory rules in the file.
- **No match**: Proceed to Step 3.

### Step 3: Write for Claude, not for humans

CLAUDE.md instructions work best when they're concise, specific, and actionable. Apply these quality checks:

| Check | Bad | Good |
|-------|-----|------|
| **Executable** | "Be careful with configs" | "When editing settings files, read ERRORS.md first" |
| **Concise** | 3-sentence explanation of why | One line: rule + brief reason |
| **Non-obvious** | "Run tests before committing" | "Run `pytest -x tests/integration` — unit tests won't catch migration issues" |
| **Specific** | "Handle errors properly" | "When a Bash command fails, log to ERRORS.md before retrying" |
| **Scoped** | Applies to one file in one project | Applies broadly enough to justify prompt space |

**Format target**: One line per rule when possible. Use `command` - `description` format for commands. Use "When [condition], [action]" for behavioral rules. Add a brief "because [reason]" only if the reason isn't obvious from the rule itself.

### Step 4: Draft the change as a diff

Show the exact proposed edit:

```
### Proposed update: [path/to/CLAUDE.md]

**Learning source:** [entry ID, e.g. LRN-20260327-001]
**Action:** add | enhance existing | replace existing | combine with [rule]

\```diff
  ## [existing section header]
+ [the new or modified line]
\```

**Why this earns its space:** [one sentence — what goes wrong without it]
```

If enhancing or combining, show both the old rule and the new version so the user can compare.

### Step 5: Get explicit user approval

Present the diff and wait. Never auto-edit CLAUDE.md — the user must confirm. If the user rejects, log the rejection reason back to the learning entry's `Revised` field so future sessions don't re-propose the same thing.

---

## Correction-of-Correction Flow

When user corrects behavior CAUSED by an existing entry:

1. Identify the source entry
2. Classify the correction:
   - **Wrong**: The action itself was incorrect. Update action, reset Prevention-Count to 0, add `Revised: date -- reason`. PC resets because the old action was tracking a broken rule.
   - **Incomplete**: The action was right but missed a sub-condition. Add qualifying condition. PC stays because the core learning was sound.
   - **Misapplied**: The action is correct in its original context but was applied where it shouldn't be. Add exclusion condition only.
3. If revised 2+ times, set `Status: unstable`, do NOT promote. Two revisions means the learning hasn't stabilized.
4. If already promoted, update promoted version too. Revised 2+ post-promotion, consider removing from the promotion target entirely.

---

## Report

Output the session report (format in `references/templates.md`). Key signals:
- `reads: 0` on significant session = system not being consulted
- `recurrence bumps > 0` = learning failed, escalate
- `executable rules: 0/N` = writing useless entries

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Logging obvious things Claude would do anyway | Apply NON-OBVIOUS gate — skip if Claude gets it right naturally |
| Vague actions like "be more careful" | Must pass Executability Gate — "When [X], do [Y]" |
| Writing but never reading memory | Phase 0 + Read Triggers enforce reads. If reads: 0, system is broken |
| Same error logged 3 times, never prevented | Stage 3 forces escalation — add Read Trigger or promote or delete |
| Over-logging trivial sessions | "Clean session -- nothing to evolve." is a valid output |
| Auto-editing CLAUDE.md | Never. Always propose + wait for explicit user confirmation |
| Logging entry that conflicts with existing one | Dedup first. If conflict, merge into context-qualified entry |
| Promoting unstable learning | Revised 2+ times = unstable. Hold until stable 2+ sessions |
| Skipping Phase 0 because files don't exist | Scaffold the files first (see Phase 0), then proceed |

---

## Rules

- Log immediately — context decays fast; details you remember now will be gone next session.
- One entry per distinct event — combined entries are harder to track, promote, and prune individually.
- Be honest. Fabricated learnings pollute memory and degrade future sessions.
- Check for duplicates before writing — redundant entries create noise that makes real learnings harder to find.
- If nothing worth logging: "Clean session -- nothing to evolve." Silence is better than filler.
- Never auto-edit CLAUDE.md — these files shape every future session, so the user must approve changes.
- RC >= 2 with PC == 0 must be escalated or deleted — an entry that recurs but is never consulted proves the learning isn't reaching future sessions.

---

## Skill Integration (Optional)

If these skills are installed, self-evolve delegates to them. If not, perform the action manually.

| Self-evolve needs to... | Delegate to (if available) |
|---|---|
| Promote to CLAUDE.md | Run built-in Quality Gate (above). Optionally invoke `claude-md-management:claude-md-improver` for a full file audit if multiple rules are being promoted at once. |
| Extract as new skill | `superpowers:writing-skills` |
| Debug before logging | `superpowers:systematic-debugging` |
| Verify before resolving | `superpowers:verification-before-completion` |

For bidirectional integration (other skills triggering self-evolve), add rules to your global CLAUDE.md.
