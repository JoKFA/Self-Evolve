# Self-Evolve Templates

Reference file for entry templates. Only read this when writing new entries or scaffolding memory files.

---

## Memory File Locations

```
~/.claude/projects/<project-hash>/memory/
  MEMORY.md
  learnings/
    ERRORS.md
    LEARNINGS.md
    DECISIONS.md
    FEATURE_REQUESTS.md
```

The project hash is derived from the working directory. Each directory gets its own memory.

---

## Entry ID Format

`TYPE-YYYYMMDD-XXX` where XXX = sequential 3-digit number for that day.

| Type | Prefix | File |
|---|---|---|
| Error / failure | `ERR` | `ERRORS.md` |
| Learning / correction | `LRN` | `LEARNINGS.md` |
| Decision | `DEC` | `DECISIONS.md` |
| Feature request | `FEAT` | `FEATURE_REQUESTS.md` |

---

## Status Lifecycle

`pending` -> `tested` (Prevention-Count >= 1) -> `promoted` (written to target)

Alternative paths:
- `pending` -> `stale` (30+ days, Recurrence-Count: 1) -> deleted
- `pending`/`tested` -> `unstable` (revised 2+ times) -> hold until stable 2+ sessions
- `promoted` -> `resolved` (situation no longer arises) -> keep 30 days -> remove

---

## Error Template -> ERRORS.md

Triggers: command failed, tool error, edit broke something, build failed, user corrected broken approach.

```markdown
## [ERR-YYYYMMDD-XXX] Short title

**Logged**: YYYY-MM-DDTHH:MM:SSZ
**Priority**: low | medium | high | critical
**Status**: pending
**Failure-Type**: knowledge-gap | tool-misuse | process | permission | misread-requirement | environment
**Area**: [project domain, e.g. frontend | backend | workflow | tools | memory | infra]

### Summary
One sentence.

### Error
\```
Actual error output or what went wrong
\```

### Context
- What was attempted
- Input or parameters
- Environment if relevant

### Suggested Fix
[Must pass Executability Gate -- "When [condition], do [action]"]

### Resolution Criteria
What "fixed" looks like -- the observable behavior that proves this won't recur.

### Metadata
- Reproducible: yes | no | unknown
- Related Files: path/to/file
- See Also: ERR-YYYYMMDD-XXX (if recurring)
- Prevention-Count: 0
- Recurrence-Count: 1
- First-Seen: YYYY-MM-DD
- Last-Seen: YYYY-MM-DD
```

---

## Learning Template -> LEARNINGS.md

Triggers: user corrects Claude, non-obvious pattern found, best practice confirmed, knowledge gap discovered.

Categories: `correction` | `pattern` | `best-practice` | `knowledge-gap`

**Organize by domain sections, not by date.** Example sections (adapt to project):
```
## Frontend
## Backend / API
## Database
## Workflow & Tooling
## Deployment & Infra
## Memory & Self-Evolve
```

```markdown
## [LRN-YYYYMMDD-XXX] Short title

**Logged**: YYYY-MM-DDTHH:MM:SSZ
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: [project domain]

### Summary
One sentence.

### Details
What happened, what was wrong, what is correct.

### Suggested Action
[Must pass Executability Gate -- "When [condition], do [action]"]

### Resolution Criteria
What "applied correctly" looks like.

### Metadata
- Source: conversation | error | user_feedback
- Category: correction | pattern | best-practice | knowledge-gap
- Related Files: path/to/file
- Tags: tag1, tag2
- See Also: LRN-YYYYMMDD-XXX
- Pattern-Key: (optional stable key for recurring patterns)
- Prevention-Count: 0
- Recurrence-Count: 1
- First-Seen: YYYY-MM-DD
- Last-Seen: YYYY-MM-DD
- Revised: (empty until revised -- then YYYY-MM-DD -- reason)
```

---

## Decision Template -> DECISIONS.md

Triggers: architecture choice made, convention established, user chose between alternatives.

```markdown
## [DEC-YYYYMMDD-XXX] Decision title

**Logged**: YYYY-MM-DDTHH:MM:SSZ
**Status**: active

### Context
Why this decision came up.

### Decision
What was chosen.

### Alternatives Rejected
What else was considered and why not.

### Rationale
Why this option won.
```

---

## Feature Request Template -> FEATURE_REQUESTS.md

Triggers: user asks for something that doesn't exist yet.

```markdown
## [FEAT-YYYYMMDD-XXX] Capability name

**Logged**: YYYY-MM-DDTHH:MM:SSZ
**Priority**: low | medium | high
**Status**: pending
**Area**: [project domain]

### Requested Capability
What the user wanted to do.

### User Context
Why they needed it, what problem it solves.

### Complexity Estimate
simple | medium | complex

### Suggested Implementation
How this could be built.

### Metadata
- Frequency: first_time | recurring
- Related Features: existing_feature_name
```

---

## Read Triggers Format (for MEMORY.md)

```markdown
## Read Triggers

| Before doing this | Read |
|---|---|
| [task pattern] | [file] -> [section or entry ID] |
```

---

## Session Report Format

```
Session Evolution Summary:
- Memory files READ this session: X
- Preventions applied (read + behavior changed): X
- Recurrence bumps (same error again): X
- Executable rules written: Y / Z total
- Errors logged: X  (IDs: ERR-...)
- Learnings logged: X  (IDs: LRN-...)
- Decisions logged: X  (IDs: DEC-...)
- Feature requests logged: X  (IDs: FEAT-...)
- Promoted: X | Pruned: X
- Escalated (Stage 3 forced): X
- CLAUDE.md update suggested: yes/no
- Skill extraction flagged: yes/no
```

If all new metrics are zero: expected for trivial sessions. For significant sessions, `reads: 0` is a warning.

---

## Scaffolding Templates

When creating new memory files from scratch, use these minimal starters:

### MEMORY.md (new project)
```markdown
# [Project Name] -- Long-Term Memory

## Read Triggers

| Before doing this | Read |
|---|---|
| Debugging any error | ERRORS.md |
| Editing config or settings files | ERRORS.md |
| Starting a task similar to past work | LEARNINGS.md |
| Making an architecture choice | DECISIONS.md |
```

### ERRORS.md (empty)
```markdown
# Errors Log

<!-- Entries organized by recency. Use ERR-YYYYMMDD-XXX format. -->
```

### LEARNINGS.md (empty)
```markdown
# Learnings

<!-- Entries organized by domain section. Use LRN-YYYYMMDD-XXX format. -->
```

### DECISIONS.md (empty)
```markdown
# Decisions

<!-- Architecture and design decisions. Use DEC-YYYYMMDD-XXX format. -->
```

### FEATURE_REQUESTS.md (empty)
```markdown
# Feature Requests

<!-- Capability requests. Use FEAT-YYYYMMDD-XXX format. -->
```
