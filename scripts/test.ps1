$ErrorActionPreference = 'Stop'

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
& $compose @('ps')

try {
  docker exec xray-ubuntu xray version | Out-Null
} catch {
  Write-Error 'xray is not responding inside the container'
  exit 1
}

$ss = docker exec xray-ubuntu ss -ltnp
if ($ss -notmatch '10808') {
  Write-Error 'SOCKS inbound not listening on 10808'
  exit 1
}

if ($ss -notmatch '12345') {
  Write-Error 'Transparent inbound not listening on 12345'
  exit 1
}

$rules = docker exec xray-ubuntu iptables -t nat -S XRAY
if ($rules -notmatch '172.64.0.0/24') {
  Write-Error 'Missing iptables rule for 172.64.0.0/24'
  exit 1
}
if ($rules -notmatch '8.47.0.0/24') {
  Write-Error 'Missing iptables rule for 8.47.0.0/24'
  exit 1
}

Write-Host 'All tests passed'
