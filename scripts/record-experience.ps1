param(
    [Parameter(Mandatory = $true)][string]$Stage,
    [Parameter(Mandatory = $true)][string]$Evidence,
    [Parameter(Mandatory = $true)][string]$Decision,
    [string]$Date = (Get-Date -Format 'yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'
$logPath = Join-Path $PSScriptRoot '..\references\experience-log.md'
$entry = "- $Date | $Stage | $Evidence | $Decision"
if ($entry -match '(?i)(sk-[a-z0-9]|api[_ -]?key\s*[:=])') {
    throw 'Do not record secrets in the experience log.'
}
Add-Content -LiteralPath $logPath -Value $entry -Encoding utf8
$lines = Get-Content -LiteralPath $logPath -Encoding utf8
if ($lines.Count -gt 31) {
    $header = $lines[0]
    $recent = $lines | Select-Object -Last 30
    Set-Content -LiteralPath $logPath -Value @($header, $recent) -Encoding utf8
}

$skillRoots = @(
    'C:\Users\Wellington\.codex\skills',
    'C:\Users\Wellington\.config\opencode\skills',
    'C:\Users\Wellington\.gemini\skills',
    'C:\Users\Wellington\.gemini\config\skills',
    'C:\Users\Wellington\.agents\skills'
)
foreach ($root in $skillRoots) {
    $target = Join-Path $root 'metagpt-pilot\references\experience-log.md'
    if ((Test-Path -LiteralPath $target) -and ((Resolve-Path -LiteralPath $target).Path -ne (Resolve-Path -LiteralPath $logPath).Path)) {
        Copy-Item -LiteralPath $logPath -Destination $target -Force
    }
}
