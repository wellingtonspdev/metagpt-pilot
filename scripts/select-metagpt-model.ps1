[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,

    [string]$BaseUrl = "http://127.0.0.1:20128/v1",

    [ValidateSet("Auto", "Planning", "Architecture", "Implementation", "Review", "Fast")]
    [string]$Phase = "Auto",

    [string]$Role = "",

    [string]$Task = "",

    [ValidateSet("Auto", "Low", "Medium", "High")]
    [string]$Complexity = "Auto",

    [string[]]$ExcludeModels = @(),

    [ValidateRange(1, 3)]
    [int]$MaxProbeAttempts = 2
)

$ErrorActionPreference = "Stop"

function Resolve-Route {
    param([string]$RequestedPhase, [string]$RequestedRole, [string]$RequestedTask, [string]$RequestedComplexity)

    if ($RequestedPhase -ne "Auto") { return $RequestedPhase }

    $text = ("$RequestedRole $RequestedTask").ToLowerInvariant()
    if ($text -match "prd|requisit|backlog|produto|product manager|planej|alice") { return "Planning" }
    if ($text -match "arquitet|architecture|diagrama|decisao tecnica|investig|root cause|bob") { return "Architecture" }
    if ($text -match "review|qa|teste|test|qualidade|bug fix|correc|eve") { return "Review" }
    if ($text -match "documentacao|classific|extrac|renome|boilerplate|simples") { return "Fast" }
    if ($RequestedComplexity -eq "High") { return "Architecture" }
    return "Implementation"
}

function Get-FailureDetail {
    param($Exception)

    $status = $null
    $detail = $Exception.Message
    $response = $Exception.Response
    if ($response) {
        try { $status = [int]$response.StatusCode } catch {}
        try {
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
            $detail = $reader.ReadToEnd()
            $reader.Dispose()
        } catch {}
    }
    $detail = ($detail -replace "\s+", " ").Trim()
    if ($detail.Length -gt 240) { $detail = $detail.Substring(0, 240) }
    return [pscustomobject]@{ status = $status; detail = $detail }
}

$route = Resolve-Route -RequestedPhase $Phase -RequestedRole $Role -RequestedTask $Task -RequestedComplexity $Complexity
$candidatesByRoute = @{
    Planning = @(
        "gemini/gemini-3.1-flash-lite-preview",
        "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free",
        "openrouter/cohere/north-mini-code:free"
    )
    Architecture = @(
        "nvidia/deepseek-ai/deepseek-v4-flash",
        "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free",
        "gemini/gemini-3.1-flash-lite-preview"
    )
    Implementation = @(
        "openrouter/poolside/laguna-m.1:free",
        "openrouter/cohere/north-mini-code:free",
        "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free",
        "nvidia/deepseek-ai/deepseek-v4-flash"
    )
    Review = @(
        "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free",
        "nvidia/deepseek-ai/deepseek-v4-flash",
        "openrouter/cohere/north-mini-code:free"
    )
    Fast = @(
        "openrouter/cohere/north-mini-code:free",
        "openrouter/poolside/laguna-xs-2.1:free",
        "gemini/gemini-3.1-flash-lite-preview"
    )
}

$headers = @{ Authorization = "Bearer $ApiKey"; "Content-Type" = "application/json" }
$endpoint = $BaseUrl.TrimEnd("/")
$catalog = Invoke-RestMethod -Uri "$endpoint/models" -Headers $headers -Method Get -TimeoutSec 20
$available = @($catalog.data | ForEach-Object { $_.id } | Where-Object { $_ } | Sort-Object -Unique)
$candidates = @($candidatesByRoute[$route] | Where-Object { $_ -in $available -and $_ -notin $ExcludeModels })

if ($candidates.Count -eq 0) {
    throw "No available candidates for route $route after exclusions. Refresh provider configuration or pass -Model explicitly."
}

$probes = @()
$selected = $null
foreach ($candidate in $candidates | Select-Object -First $MaxProbeAttempts) {
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $body = @{
        model = $candidate
        messages = @(@{ role = "user"; content = "Responda somente OK" })
        max_tokens = 8
        temperature = 0
        stream = $false
    } | ConvertTo-Json -Depth 6 -Compress

    try {
        $null = Invoke-RestMethod -Uri "$endpoint/chat/completions" -Method Post -Headers $headers -Body $body -TimeoutSec 35
        $timer.Stop()
        $probes += [pscustomobject]@{ model = $candidate; status = "healthy"; http_status = 200; latency_ms = $timer.ElapsedMilliseconds; detail = "" }
        $selected = $candidate
        break
    } catch {
        $timer.Stop()
        $failure = Get-FailureDetail -Exception $_.Exception
        $classification = if ($failure.status -eq 429 -or -not $failure.status) { "temporary_unavailable" } elseif ($failure.status -in 400, 401, 403, 404, 410) { "misconfigured_or_incompatible" } else { "temporary_unavailable" }
        $probes += [pscustomobject]@{ model = $candidate; status = $classification; http_status = $failure.status; latency_ms = $timer.ElapsedMilliseconds; detail = $failure.detail }
    }
}

if (-not $selected) {
    throw "No healthy model found for route $route. Probe results: $($probes | ConvertTo-Json -Compress)"
}

$fallbacks = @($candidates | Where-Object { $_ -ne $selected })
[pscustomobject]@{
    version = "2026-07-16"
    selected_model = $selected
    fallback_models = $fallbacks
    route = $route
    complexity = $Complexity
    reason = "Selected by route $route after a local 9Router health check."
    probes = $probes
} | ConvertTo-Json -Depth 6 -Compress
