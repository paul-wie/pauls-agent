# Loads .env into this PowerShell session and starts Copilot CLI in the repo root.
# Usage (VPN on):  .\scripts\start.ps1
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
if (-not (Test-Path .env)) { throw ".env missing - create it with your tokens (see README.md)." }
Get-Content .env | Where-Object { $_ -match '^\s*(export\s+)?[A-Za-z_][A-Za-z0-9_]*=' } | ForEach-Object {
  $line = $_ -replace '^\s*export\s+', ''
  $name, $value = $line -split '=', 2
  Set-Item -Path "Env:$($name.Trim())" -Value $value.Trim().Trim('"').Trim("'")
}
foreach ($v in 'JIRA_PERSONAL_TOKEN', 'CONFLUENCE_PERSONAL_TOKEN') {
  "{0}: {1}" -f $v, $(if ((Get-Item "Env:$v" -ErrorAction SilentlyContinue).Value) { 'loaded' } else { 'MISSING' })
}
copilot
