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
$required = @(
  '13.107.0.0/16',
  '18.66.0.0/16',
  '20.118.0.0/16',
  '23.35.0.0/16',
  '104.18.0.0/16',
  '142.250.0.0/16',
  '172.64.0.0/16',
  '184.105.0.0/16',
  '188.114.0.0/16'
)

foreach ($cidr in $required) {
  if ($rules -notmatch [regex]::Escape($cidr)) {
    Write-Error "Missing iptables rule for $cidr"
    exit 1
  }
}

$hosts = $null
try {
  $hosts = docker exec xray-ubuntu getent ahosts ifconfig.me
} catch {
  $hosts = $null
}

if ($hosts) {
  $ips = $hosts | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ -match '^\d+\.' } | Sort-Object -Unique
  $matched = $false
  foreach ($ip in $ips) {
    if ($rules -match [regex]::Escape("$ip/32")) {
      $matched = $true
      break
    }
  }
  if (-not $matched) {
    Write-Error 'Missing iptables rule for ifconfig.me IPs'
    exit 1
  }
}

Write-Host 'All tests passed'
