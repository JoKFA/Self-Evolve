# Self-Evolve Error Detector Hook (Global)
# Triggers on PostToolUse (Bash) — detects command failures and fires a log reminder
# Reads CLAUDE_TOOL_OUTPUT environment variable

$output = $env:CLAUDE_TOOL_OUTPUT

if (-not $output) { exit 0 }

# Patterns that indicate a failure
$errorPatterns = @(
    "error:",
    "Error:",
    "ERROR:",
    "failed",
    "FAILED",
    "command not found",
    "No such file",
    "Permission denied",
    "fatal:",
    "Exception",
    "Traceback",
    "npm ERR!",
    "ModuleNotFoundError",
    "SyntaxError",
    "TypeError",
    "exit code",
    "non-zero",
    "ENOENT",
    "EPIPE",
    "cannot find",
    "is not recognized"
)

$containsError = $false
foreach ($pattern in $errorPatterns) {
    if ($output -match [regex]::Escape($pattern)) {
        $containsError = $true
        break
    }
}

if ($containsError) {
    Write-Output @"
<error-detected>
A command error was detected. Log this to memory/learnings/ERRORS.md if:
- The error was unexpected or non-obvious
- It required investigation to resolve
- It might recur in similar contexts
- The solution could benefit future sessions

Use format: [ERR-YYYYMMDD-XXX] with Status: pending
</error-detected>
"@
}
