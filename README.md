# Self-Evolve

A persistent learning loop skill for Claude Code. Logs errors, corrections, and decisions to structured memory files, then reads them back before future tasks to prevent repeated mistakes.

## Install

```bash
# Clone into your Claude Code skills directory
git clone https://github.com/JoKFA/Self-Evolve.git ~/.claude/skills/self-evolve
```

That's it. Claude will detect the skill automatically. Invoke it with `/self-evolve` or let it trigger naturally at the end of significant sessions.

Memory files are scaffolded automatically on first use — no manual setup needed.

## What It Does

Most "memory" systems are write-only. Self-evolve enforces a **closed loop**:

1. **Reads** memory before tasks (Phase 0 + Read Triggers)
2. **Filters** entries through an Executability Gate — rejects vague or obvious learnings
3. **Tracks** whether entries actually prevent errors (Prevention-Count)
4. **Promotes** proven learnings to CLAUDE.md through a Quality Gate that checks for duplicates, conflicts, and clarity
5. **Prunes** stale or useless entries automatically

## What to Expect

- **End of a significant session**: Claude scans for learnings, logs entries, checks for promotions. You'll see a Session Evolution Summary.
- **Next session**: Phase 0 reads previous entries and warns about known risks before you start work.
- **Over time**: Memory accumulates. Debugging gets faster. Repeated mistakes stop recurring.

## Optional: Automated Hooks

The skill works without hooks (invoke manually with `/self-evolve`). But hooks make it fully automatic — Phase 0 fires on session start, error detection fires on command failures.

See `scripts/` for hook scripts (bash + PowerShell) and setup instructions in the script comments.

**Quick setup (macOS/Linux):**
```bash
cp scripts/activator.sh scripts/error-detector.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/activator.sh ~/.claude/hooks/error-detector.sh
```

Then register in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "type": "command", "command": "bash ~/.claude/hooks/activator.sh" }
    ],
    "PostToolUse": [
      { "matcher": { "tool_name": "Bash" }, "type": "command", "command": "bash ~/.claude/hooks/error-detector.sh" }
    ]
  }
}
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Copy-Item scripts\activator.ps1, scripts\error-detector.ps1 ~\.claude\hooks\
```

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "type": "command", "command": "powershell -File ~/.claude/hooks/activator.ps1" }
    ],
    "PostToolUse": [
      { "matcher": { "tool_name": "Bash" }, "type": "command", "command": "powershell -File ~/.claude/hooks/error-detector.ps1" }
    ]
  }
}
```
</details>

## Multi-Level Architecture

Self-evolve understands that learnings have different scopes. It routes each entry to the right level automatically:

| Scope | Where it goes | Example |
|-------|--------------|---------|
| **Project** | Project memory | "This app uses Redis for sessions, not SQLite" |
| **Workspace** | Codebase CLAUDE.md | "All projects here use pnpm, not npm" |
| **Global** | Global CLAUDE.md | "When user pushes back, re-read requirements before iterating" |

When promoting a rule to a higher level, the **Quality Gate** checks all levels for duplicates, conflicts, and inherited rules — so you never end up with the same rule repeated across project, workspace, and global files.

If a project-level rule gets promoted to workspace level, the original is automatically cleaned up (`Superseded-By` marker).

## How Memory Is Stored

Plain markdown at `~/.claude/projects/<project-hash>/memory/` — one set per project. No database, no API keys, no external services. You can read, edit, or delete them directly.

```
~/.claude/CLAUDE.md                          -- Global rules (all projects)
<workspace>/CLAUDE.md                        -- Workspace rules (multi-project)
<project>/CLAUDE.md                          -- Project-specific rules

~/.claude/projects/<hash>/memory/
  MEMORY.md                                  -- Cross-session facts + Read Triggers
  learnings/
    ERRORS.md                                -- Failure logs
    LEARNINGS.md                             -- Corrections, patterns, best practices
    DECISIONS.md                             -- Architecture/design choices
```

## Test Results

12/12 tests pass (5 functional + 4 logic + 3 quality gate). See `test-results/TEST-REPORT.md`.

- **Loop closure**: Session N+1 avoids all mistakes from Session N
- **Garbage filter**: 50% rejection rate on mixed-quality input
- **3x faster debugging** with accumulated memory
- **Quality Gate**: Catches duplicates, rewrites vague rules, enforces concise diffs

## Version

1.0 (2026-03-27)
