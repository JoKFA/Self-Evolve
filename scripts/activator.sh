#!/bin/bash
# Self-Evolve Smart Activator Hook (Global)
# Triggers on UserPromptSubmit
# First prompt of session: outputs Read Triggers reminder (~20 tokens)
# Subsequent prompts: silent (0 tokens)
# Session boundary: 2-hour gap between prompts = new session

FLAG_FILE="${TMPDIR:-/tmp}/.claude-evolve-session"
NOW=$(date +%s)
SHOULD_FIRE=true

if [ -f "$FLAG_FILE" ]; then
    LAST_FIRED=$(stat -c %Y "$FLAG_FILE" 2>/dev/null || stat -f %m "$FLAG_FILE" 2>/dev/null)
    ELAPSED=$(( NOW - LAST_FIRED ))
    if [ "$ELAPSED" -lt 7200 ]; then
        SHOULD_FIRE=false
    fi
fi

if [ "$SHOULD_FIRE" = true ]; then
    echo "$NOW" > "$FLAG_FILE"
    cat <<'EOF'
<read-triggers>
New session. Before starting work, check MEMORY.md Read Triggers section for known risks relevant to this task.
</read-triggers>
EOF
fi
