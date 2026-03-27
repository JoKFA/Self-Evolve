# Self-Evolve Smart Activator Hook (Global)
# Triggers on UserPromptSubmit
# First prompt of session: outputs Read Triggers reminder (~20 tokens)
# Subsequent prompts: silent (0 tokens)
# Session boundary: 2-hour gap between prompts = new session

$flagFile = "$env:TEMP\.claude-evolve-session"
$now = Get-Date
$shouldFire = $true

if (Test-Path $flagFile) {
    $lastFired = Get-Item $flagFile | Select-Object -ExpandProperty LastWriteTime
    if (($now - $lastFired).TotalHours -lt 2) {
        $shouldFire = $false
    }
}

if ($shouldFire) {
    Set-Content $flagFile $now.ToString()
    Write-Output @"
<read-triggers>
New session. Before starting work, check MEMORY.md Read Triggers section for known risks relevant to this task.
</read-triggers>
"@
}
