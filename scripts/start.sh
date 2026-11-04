#!/usr/bin/env bash
# Mac/Linux start: loads .env, picks docker or podman, generates .github/mcp.json, starts Copilot.
# Usage (VPN on):  ./scripts/start.sh      Override runtime:  PASS_CONTAINER_RUNTIME=podman ./scripts/start.sh
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "FAIL .env missing - create it with your tokens (see README.md)"; exit 1; }
set -a; . ./.env; set +a

runtime="${PASS_CONTAINER_RUNTIME:-}"
if [ -z "$runtime" ]; then
  if command -v docker >/dev/null 2>&1; then runtime=docker
  elif command -v podman >/dev/null 2>&1; then runtime=podman
  else echo "FAIL neither docker nor podman found"; exit 1; fi
fi
"$runtime" info >/dev/null 2>&1 || { echo "FAIL $runtime engine not reachable (start Docker Desktop / podman machine)"; exit 1; }
echo "container runtime: $runtime"

sed "s/__RUNTIME__/$runtime/" .github/mcp.template.json > .github/mcp.json

for v in JIRA_PERSONAL_TOKEN CONFLUENCE_PERSONAL_TOKEN; do
  if [ -n "${!v:-}" ]; then echo "$v: loaded"; else echo "$v: MISSING"; fi
done
command -v pwsh >/dev/null 2>&1 || echo "WARN pwsh not found - the kpi-report skill needs PowerShell 7 (brew install powershell)"

exec copilot
