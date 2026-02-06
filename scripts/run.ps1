$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $scriptDir 'check.ps1')

function Get-ComposeCmd {
  try {
    docker compose version | Out-Null
    return @('docker', 'compose')
  } catch {
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
      return @('docker-compose')
    }
    throw 'Docker Compose not found'
  }
}

$compose = Get-ComposeCmd
& $compose @('up', '-d', '--build')

& (Join-Path $scriptDir 'test.ps1')
