param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [Parameter(Mandatory = $true)]
    [string]$Requirement,
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [string]$SpecificationPath = "",
    [string]$ApiKeyEnvironmentVariable = "METAGPT_SESSION_2_API_KEY",
    [string]$Model = "qwen/qwen3-coder:free",
    [ValidateSet("P1", "P2", "P3", "P4", "P5")]
    [string]$Profile = "P1",
    [int]$Rounds = 3,
    [double]$Investment = 0.3,
    [string]$ContainerName = ""
)

$ErrorActionPreference = "Stop"
$sessionRoot = $PSScriptRoot
$templatePath = Join-Path $sessionRoot "config2.template.yaml"
$runtimePath = Join-Path $sessionRoot "runtime"
$logsPath = Join-Path $sessionRoot "logs"
$specificationsPath = Join-Path $sessionRoot "specifications"

foreach ($path in @($runtimePath, $logsPath, $specificationsPath)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "Project root not found: $ProjectRoot" }
if (-not (Test-Path -LiteralPath $templatePath)) { throw "Session template not found: $templatePath" }

$apiKey = [Environment]::GetEnvironmentVariable($ApiKeyEnvironmentVariable, "Process")
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "Environment variable $ApiKeyEnvironmentVariable is not defined for this PowerShell process."
}

$specPath = $SpecificationPath
if ([string]::IsNullOrWhiteSpace($specPath)) {
    $specPath = @(
        (Join-Path $ProjectRoot "agents.md"),
        (Join-Path $ProjectRoot "AGENTS.md")
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $specPath) { throw "No agents.md or AGENTS.md found in the project root." }
$specPath = (Resolve-Path -LiteralPath $specPath).Path

$profiles = @{
    P1 = @{ MaxToken = 12000; Temperature = 0.1; Repair = $false }
    P2 = @{ MaxToken = 8000; Temperature = 0.0; Repair = $false }
    P3 = @{ MaxToken = 8000; Temperature = 0.0; Repair = $false }
    P4 = @{ MaxToken = 6000; Temperature = 0.3; Repair = $false }
    P5 = @{ MaxToken = 4000; Temperature = 0.0; Repair = $true }
}
$profileSettings = $profiles[$Profile]

$projectNameSafe = $ProjectName -replace "[^A-Za-z0-9_-]", ""
if ([string]::IsNullOrWhiteSpace($projectNameSafe)) { throw "ProjectName must contain letters, numbers, underscores, or hyphens." }
if ([string]::IsNullOrWhiteSpace($ContainerName)) { $ContainerName = "metagpt-session-2-$projectNameSafe" }

$existingNames = & docker ps -a --format "{{.Names}}"
if ($existingNames -contains $ContainerName) { throw "Container already exists: $ContainerName. Choose a different name or remove it after inspecting its logs." }

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$specification = Get-Content -LiteralPath $specPath -Raw -Encoding UTF8
$specSnapshot = Join-Path $specificationsPath "$timestamp-$([IO.Path]::GetFileName($specPath))"
Copy-Item -LiteralPath $specPath -Destination $specSnapshot -Force

$config = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$config = $config.Replace("__METAGPT_API_KEY__", $apiKey)
$config = $config.Replace("__METAGPT_MODEL__", $Model)
$config = $config.Replace("__MAX_TOKEN__", [string]$profileSettings.MaxToken)
$config = $config.Replace("__TEMPERATURE__", [string]$profileSettings.Temperature)
$config = $config.Replace("__REPAIR_LLM_OUTPUT__", $profileSettings.Repair.ToString().ToLowerInvariant())
$runtimeConfig = Join-Path $runtimePath "config2.yaml"
Set-Content -LiteralPath $runtimeConfig -Value $config -Encoding UTF8 -NoNewline

$prompt = @"
$Requirement

This is a limited, recoverable MetaGPT round. Deliver only the requested phase.
Do not invent product scope outside the authoritative specification below.

--- BEGIN SPECIFICATION ---
$specification
--- END SPECIFICATION ---
"@
$encodedPrompt = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($prompt))
$containerProjectPath = "/app/metagpt/workspace/$projectNameSafe"

$manifest = [ordered]@{
    session = "session-2"
    timestamp = $timestamp
    container_name = $ContainerName
    project_root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    specification_snapshot = $specSnapshot
    model = $Model
    profile = $Profile
    rounds = $Rounds
    api_key_environment_variable = $ApiKeyEnvironmentVariable
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logsPath "$timestamp-manifest.json") -Encoding UTF8

& docker run -d --name $ContainerName --privileged `
    -v "${runtimeConfig}:/app/metagpt/config/config2.yaml" `
    -v "${ProjectRoot}:${containerProjectPath}" `
    metagpt/metagpt:latest `
    python -c "import base64; from metagpt.software_company import generate_repo; idea=base64.b64decode('$encodedPrompt').decode('utf-8'); generate_repo(idea, investment=$Investment, n_round=$Rounds, code_review=True, run_tests=True, implement=True, project_name='$projectNameSafe', project_path='$containerProjectPath', inc=True)"

if ($LASTEXITCODE -ne 0) { throw "Docker could not start the MetaGPT session." }
Write-Output "Session started: $ContainerName"
Write-Output "Monitor with: docker logs -f $ContainerName"
