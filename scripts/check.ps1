$ErrorActionPreference = 'Stop'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Error 'Docker is not installed or not in PATH'
  exit 1
}

try {
  docker info | Out-Null
} catch {
  Write-Error 'Docker daemon is not running'
  exit 1
}

$hasDockerCompose = $false
try {
  docker compose version | Out-Null
  $hasDockerCompose = $true
} catch {
  $hasDockerCompose = $false
}

$hasDockerComposeExe = $false
if (-not $hasDockerCompose) {
  if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    $hasDockerComposeExe = $true
  }
}

if (-not $hasDockerCompose -and -not $hasDockerComposeExe) {
  Write-Error 'Docker Compose not found. Install Docker Desktop or docker-compose.'
  exit 1
}

if (-not (Test-Path -Path (Join-Path $PWD 'docker-compose.yml'))) {
  Write-Error "docker-compose.yml not found in $PWD"
  exit 1
}

Write-Host 'Dependency checks passed'
