param(
    [Parameter(Mandatory = $true)]
    [string]$ContainerName,
    [int]$Tail = 100
)

$ErrorActionPreference = "Stop"
& docker ps -a --filter "name=^/$ContainerName$" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
& docker logs --tail $Tail $ContainerName
if ($LASTEXITCODE -ne 0) { throw "Could not read logs for container: $ContainerName" }
