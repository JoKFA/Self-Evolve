# Self-Evolve Skill

A persistent learning loop that makes Claude genuinely better across sessions. Logs errors, corrections, and decisions to structured memory files, then reads them back before future tasks to prevent repeated mistakes.

## What Makes This Different

Most "memory" systems are write-only — they log everything but never read it back. Self-evolve enforces a closed loop:

1. **Phase 0** reads memory BEFORE tasks (via Read Triggers)
2. **Executability Gate** filters out vague, obvious, or untestable entries
3. **Prevention-Count** tracks whether entries actually changed behavior
4. **Promotion Pipeline** escalates stuck entries or deletes useless ones
5. **CLAUDE.md Quality Gate** vets rules before they're promoted to instruction files
6. **Correction-of-Correction** handles when a learning itself was wrong

## Test Results

9/9 core tests pass (5 functional + 4 logic), plus 3 Quality Gate tests. See `test-results/TEST-REPORT.md` for full details.

Key findings:
- **Loop closure**: Session N+1 avoids all mistakes from Session N
- **Garbage filter**: 50% rejection rate on mixed-quality input
- **Real improvement**: 3x faster debugging with accumulated memory
- **Escalation**: Produces genuine strategy shifts, not paperwork
- **Quality Gate**: Catches duplicates, rewrites vague rules, enforces concise diffs

## Quick Start

After installing (see below), here's what to expect:

1. **First prompt of a session**: You'll see a `<read-triggers>` block reminding Claude to check memory before acting. This is the activator hook firing.
2. **When a command fails**: You'll see an `<error-detected>` block prompting Claude to log the error. This is the error-detector hook firing.
3. **End of a significant session**: Claude runs the self-evolve loop — scanning for learnings, logging entries, checking for promotions. You'll see a Session Evolution Summary.
4. **Next session**: Phase 0 reads the previous session's entries and warns about known risks before you start work.

If you don't see `<read-triggers>` on your first prompt, the hooks aren't set up correctly. Check the install steps below.

## Requirements

- **Claude Code** with hooks support (`UserPromptSubmit` and `PostToolUse` hook types)
- The `CLAUDE_TOOL_OUTPUT` environment variable must be available in PostToolUse hooks (this is set automatically by Claude Code — no action needed on your part)
- **bash** (macOS/Linux) or **PowerShell** (Windows) for hook scripts

## Install

### 1. Copy the skill

```bash
# Global (all projects)
cp -r skill/ ~/.claude/skills/self-evolve/
```

### 2. Set up hooks (optional but recommended)

The hooks automate Phase 0 (read-before-act) and error detection. Without them, you can still invoke the skill manually with `/self-evolve`, but the closed loop won't fire automatically.

**macOS / Linux (bash/zsh):**

```bash
# Create hooks directory if needed
mkdir -p ~/.claude/hooks

# Copy hook scripts
cp scripts/activator.sh ~/.claude/hooks/
cp scripts/error-detector.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/activator.sh ~/.claude/hooks/error-detector.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/activator.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": { "tool_name": "Bash" },
        "type": "command",
        "command": "bash ~/.claude/hooks/error-detector.sh"
      }
    ]
  }
}
```

**Windows (PowerShell):**

```powershell
# Copy hook scripts
Copy-Item scripts\activator.ps1 ~\.claude\hooks\
Copy-Item scripts\error-detector.ps1 ~\.claude\hooks\
```

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "powershell -File ~/.claude/hooks/activator.ps1"
      }
    ],
    "PostToolUse": [
      {
        "matcher": { "tool_name": "Bash" },
        "type": "command",
        "command": "powershell -File ~/.claude/hooks/error-detector.ps1"
      }
    ]
  }
}
```

### 3. Verify installation

Start a new Claude Code session. On your first prompt, you should see:

```
<read-triggers>
New session. Before starting work, check MEMORY.md Read Triggers section...
</read-triggers>
```

If you see this, the activator hook is working. The error-detector will fire the next time a Bash command fails.

Claude will automatically scaffold memory files (`~/.claude/projects/<hash>/memory/`) on first use — no manual setup needed.

### 4. Add bidirectional integration (optional)

If you use other skills that should trigger self-evolve, add to your global `~/.claude/CLAUDE.md`:

```markdown
## Skill Integration Rules

| When using this skill | Also do this |
|---|---|
| Any debugging skill | Read ERRORS.md before starting debug |
| Any verification skill | Run self-evolve before claiming complete |
| Any brainstorming skill | If a decision is made, log to DECISIONS.md |
| Any skill that produces a user correction | Check if existing LRN entry caused the bad behavior |
```

## File Structure

```
self-evolve/
  README.md                    -- This file
  skill/
    SKILL.md                   -- Main skill (loaded on trigger)
    references/
      templates.md             -- Entry templates (loaded only when writing)
  scripts/
    activator.sh               -- Session activator hook (bash)
    activator.ps1              -- Session activator hook (PowerShell)
    error-detector.sh           -- Error detection hook (bash)
    error-detector.ps1          -- Error detection hook (PowerShell)
  test-results/
    TEST-REPORT.md             -- Full test methodology and results
```

## How Memory Is Stored

Claude Code stores per-project memory at `~/.claude/projects/<project-hash>/memory/`. The project hash is derived from the working directory path. Run `ls ~/.claude/projects/` to see existing project hashes.

```
~/.claude/projects/<hash>/memory/
  MEMORY.md              -- Promoted cross-session facts + Read Triggers
  learnings/
    ERRORS.md            -- Failure logs (command errors, broken approaches)
    LEARNINGS.md         -- Corrections, patterns, best practices
    DECISIONS.md         -- Architecture/design choices with rationale
    FEATURE_REQUESTS.md  -- Capability requests
```

Memory files are plain markdown. No database, no API keys, no external services. You can read, edit, or delete them directly.

## Version

v5 (2026-03-27) -- CLAUDE.md Promotion Quality Gate, cross-level conflict checks, supersedes cleanup.

### Changelog

- **v5** (2026-03-27): Added CLAUDE.md Promotion Quality Gate — a 5-step process that vets rules before they're promoted to instruction files (checks for duplicates, conflicts, and overlapping rules across all levels; enforces concise/executable/non-obvious writing; requires user approval). Enhanced PROMOTED stage with supersedes cleanup for cross-level promotions. Clarified RC vs session threshold distinction at REVIEW stage. Added bash/zsh hook scripts for macOS/Linux.
- **v4** (2026-03-15): Directory format, scaffolding guidance, skill-creator compliant.
- **v3** (2026-03-15): Restructured per skill-creator standards, split templates to companion file.
- **v2** (2026-03-15): Added Prevention-Count, Executability Gate, Promotion Pipeline, Correction-of-Correction.
- **v1** (2026-03-10): Original flat .skill file, monolithic 450 lines.
