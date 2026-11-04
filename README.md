# Pauls ASNAST Agent

Persoenliches Repo: Copilot CLI mit Jira/Confluence-MCP und dem **kpi-report**-Skill fuer ASNAST/ASDM. Alles laeuft hier, ohne das PLES-Repo.

## Einrichtung (einmalig)
1. Repo klonen, VPN an.
2. Im Repo-Root eine Datei `.env` anlegen (sie ist im `.gitignore`, wird also nie committet) mit eigenen Tokens, je eine Zeile `NAME=Wert`:
   - `JIRA_PERSONAL_TOKEN`
   - `CONFLUENCE_PERSONAL_TOKEN` (fuer Confluence-Zugriff und Archivierung)
   - `GITHUB_PERSONAL_ACCESS_TOKEN` (optional, nur fuer den GitHub-MCP)
3. Voraussetzungen: PowerShell, Copilot CLI, Node (`npx`) und Podman (fuer den Atlassian-MCP).

## Container (Podman)
Der Atlassian-MCP (Jira + Confluence) laeuft wie im PLES-Repo als Podman-Container (`ghcr.io/sooperset/mcp-atlassian`, Proxy und URLs sind in `.github/mcp.json` gesetzt, die `.env` wird per `--env-file` uebergeben). Der Container startet automatisch, sobald Copilot im Repo-Root startet. Einmalig vorab ziehen und das Setup pruefen:
```powershell
podman pull ghcr.io/sooperset/mcp-atlassian:latest
.\scripts\doctor.ps1
```
Copilot muss im Repo-Root gestartet werden (`--env-file .env` ist relativ), am einfachsten ueber `.\scripts\start.ps1`.

## Starten
```powershell
.\scripts\start.ps1
```
Laedt die `.env` in die Sitzung und startet Copilot im Repo-Root. Dann koennen beliebige Fragen zu Jira/Confluence gestellt oder KPI-Reports angefordert werden (z. B. "kpi-report sprint 26/21").

## KPI-Reports direkt
```powershell
.\.github\skills\kpi-report\kpi-calc.ps1 -Level sprint -Id 26/21
.\.github\skills\kpi-report\kpi-calc.ps1 -Level pi -Id 2026.25
```
Ausgabe in `.github\skills\kpi-report\out\`. Kapazitaeten pro Sprint in `.github\skills\kpi-report\capacity.json` pflegen. Mehr dazu in `.github\skills\kpi-report\README.md`.

## Inhalt
- `.github/mcp.json`: MCP-Server (Atlassian, GitHub, context7, sequential-thinking)
- `.github/skills/kpi-report/`: der KPI-Skill
- `AGENTS.md`: Arbeitsregeln fuer den Agenten
- `scripts/start.ps1`: Token laden und Copilot starten
- `scripts/doctor.ps1`: Setup pruefen (Tokens, Podman, Node, Copilot, MCP-Config)

Das oeffentlich nutzbare KPI-Repo fuer andere ist `paul-wie/kpi-skill`; dieses Repo ist nur fuer mich.
