[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,

    [string]$BaseUrl = "http://127.0.0.1:20128/v1",

    [string]$RegistryPath = (Join-Path $PSScriptRoot "..\references\model-registry.json"),

    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $RegistryPath)) { throw "Model registry not found: $RegistryPath" }

$registry = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$headers = @{ Authorization = "Bearer $ApiKey" }
$endpoint = $BaseUrl.TrimEnd("/")
$response = Invoke-RestMethod -Uri "$endpoint/models" -Headers $headers -Method Get -TimeoutSec 20
$available = @($response.data | ForEach-Object { $_.id } | Where-Object { $_ } | Sort-Object -Unique)
$known = @($registry.models | ForEach-Object { $_.id })
$enabled = @($registry.models | Where-Object { $_.enabled } | ForEach-Object { $_.id })
$lastResearch = [DateTime]::Parse($registry.last_researched)
$stale = ((Get-Date).ToUniversalTime() - $lastResearch.ToUniversalTime()).TotalDays -gt [int]$registry.research_refresh_days

$report = [pscustomobject]@{
    observed_at = (Get-Date).ToUniversalTime().ToString("o")
    catalog_count = $available.Count
    catalog_models = $available
    enabled_available_models = @($available | Where-Object { $_ -in $enabled })
    unreviewed_models = @($available | Where-Object { $_ -notin $known })
    known_but_unavailable_models = @($enabled | Where-Object { $_ -notin $available })
    research_stale = $stale
    registry_last_researched = $registry.last_researched
}

$json = $report | ConvertTo-Json -Depth 5
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $directory = Split-Path -Parent $OutputPath
    if ($directory) { New-Item -ItemType Directory -Force -Path $directory | Out-Null }
    Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
}
$json
