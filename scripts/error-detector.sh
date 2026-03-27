#!/bin/bash
# Self-Evolve Error Detector Hook (Global)
# Triggers on PostToolUse (Bash) — detects command failures and fires a log reminder
# Reads CLAUDE_TOOL_OUTPUT environment variable (available in Claude Code hooks API)
#
# Requirements:
#   - Claude Code with hooks support (PostToolUse hook type)
#   - CLAUDE_TOOL_OUTPUT env var (set automatically by Claude Code for PostToolUse hooks)

OUTPUT="$CLAUDE_TOOL_OUTPUT"

if [ -z "$OUTPUT" ]; then
    exit 0
fi

# Patterns that indicate a failure
ERROR_PATTERNS=(
    "error:"
    "Error:"
    "ERROR:"
    "failed"
    "FAILED"
    "command not found"
    "No such file"
    "Permission denied"
    "fatal:"
    "Exception"
    "Traceback"
    "npm ERR!"
    "ModuleNotFoundError"
    "SyntaxError"
    "TypeError"
    "exit code"
    "non-zero"
    "ENOENT"
    "EPIPE"
    "cannot find"
    "is not recognized"
)

CONTAINS_ERROR=false
for pattern in "${ERROR_PATTERNS[@]}"; do
    if echo "$OUTPUT" | grep -qF "$pattern"; then
        CONTAINS_ERROR=true
        break
    fi
done

if [ "$CONTAINS_ERROR" = true ]; then
    cat <<'EOF'
<error-detected>
A command error was detected. Log this to memory/learnings/ERRORS.md if:
- The error was unexpected or non-obvious
- It required investigation to resolve
- It might recur in similar contexts
- The solution could benefit future sessions

Use format: [ERR-YYYYMMDD-XXX] with Status: pending
</error-detected>
EOF
fi
