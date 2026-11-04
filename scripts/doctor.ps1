# Checks the local setup: tokens, podman, node, copilot, MCP config. Prints only OK/FAIL, never token values.
# Usage: .\scripts\doctor.ps1   (run after .\scripts\start.ps1 or with tokens exported)
$root = Split-Path $PSScriptRoot -Parent
$fail = 0
function Ok($m)   { Write-Host "OK    $m" -ForegroundColor Green }
function Bad($m)  { Write-Host "FAIL  $m" -ForegroundColor Red; $script:fail++ }
function Warn($m) { Write-Host "WARN  $m" -ForegroundColor Yellow }

if (Test-Path (Join-Path $root '.env')) { Ok '.env exists' } else { Bad '.env missing (see README.md)' }

foreach ($v in 'JIRA_PERSONAL_TOKEN', 'CONFLUENCE_PERSONAL_TOKEN') {
  $val = (Get-Item "Env:$v" -ErrorAction SilentlyContinue).Value
  if (-not $val) { Bad "$v not loaded in this session (run .\scripts\start.ps1)" }
  elseif ($val -match '\s') { Bad "$v contains whitespace (pasted a header instead of the bare token?)" }
  else { Ok "$v loaded" }
}
if ($env:GITHUB_PERSONAL_ACCESS_TOKEN) { Ok 'GITHUB_PERSONAL_ACCESS_TOKEN loaded' } else { Warn 'GITHUB_PERSONAL_ACCESS_TOKEN not set (optional)' }

if (Get-Command podman -ErrorAction SilentlyContinue) {
  Ok 'podman found'
  podman info *> $null
  if ($LASTEXITCODE -eq 0) { Ok 'podman engine reachable' } else { Bad 'podman installed but engine not reachable (podman machine start)' }
} else { Bad 'podman not found on PATH' }

if (Get-Command node -ErrorAction SilentlyContinue) { Ok "node found ($(node --version))" } else { Bad 'node not found (needed for npx MCP servers)' }
if (Get-Command copilot -ErrorAction SilentlyContinue) { Ok 'copilot found' } else { Bad 'copilot not found on PATH' }

$mcp = Join-Path $root '.github\mcp.json'
try { $null = Get-Content $mcp -Raw | ConvertFrom-Json; Ok '.github/mcp.json is valid JSON' } catch { Bad '.github/mcp.json missing or invalid' }

if ($fail) { Write-Host "`n$fail check(s) failed." -ForegroundColor Red; exit 1 } else { Write-Host "`nAll checks passed." -ForegroundColor Green }
