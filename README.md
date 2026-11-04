# Pauls ASNAST Agent

Copilot CLI mit Jira/Confluence-MCP und dem **kpi-report**-Skill fuer ASNAST/ASDM. Laeuft eigenstaendig, ohne das PLES-Repo, unter Windows und Mac.

## Einrichtung (einmalig)
1. Repo klonen, VPN an.
2. Im Repo-Root eine Datei `.env` anlegen (sie ist im `.gitignore`, wird also nie committet) mit eigenen Tokens, je eine Zeile `NAME=Wert`:
   - `JIRA_PERSONAL_TOKEN`
   - `CONFLUENCE_PERSONAL_TOKEN` (fuer Confluence-Zugriff und Archivierung)
   - `GITHUB_PERSONAL_ACCESS_TOKEN` (optional, nur fuer den GitHub-MCP)
3. Voraussetzungen: Copilot CLI, Node (`npx`), **Docker oder Podman** (fuer den Atlassian-MCP) und PowerShell 7 (`pwsh`, fuer den KPI-Skill; Mac: `brew install powershell`).

## Container (Docker oder Podman)
Der Atlassian-MCP (Jira + Confluence) laeuft wie im PLES-Repo als Container (`ghcr.io/sooperset/mcp-atlassian`, Proxy und URLs stehen in `.github/mcp.template.json`; die Startskripte erkennen Podman/Docker automatisch, erzeugen daraus `.github/mcp.json` (git-ignoriert) und ueberschreiben mit `PASS_CONTAINER_RUNTIME=docker|podman` moeglich, die `.env` wird per `--env-file` uebergeben). Der Container startet automatisch, sobald Copilot im Repo-Root startet. Einmalig vorab ziehen (`docker` bzw. `podman`) und das Setup pruefen:
```powershell
docker pull ghcr.io/sooperset/mcp-atlassian:latest
.\scripts\doctor.ps1
```
Copilot muss im Repo-Root gestartet werden (`--env-file .env` ist relativ), am einfachsten ueber `.\scripts\start.ps1` (Windows) bzw. `./scripts/start.sh` (Mac/Linux).

## Starten
```powershell
.\scripts\start.ps1
```
Mac/Linux: `./scripts/start.sh` (einmalig `chmod +x scripts/start.sh`). Laedt die `.env` in die Sitzung und startet Copilot im Repo-Root. Dann koennen beliebige Fragen zu Jira/Confluence gestellt oder KPI-Reports angefordert werden (z. B. "kpi-report sprint 26/21").

## KPI-Reports direkt
```powershell
.\.github\skills\kpi-report\kpi-calc.ps1 -Level sprint -Id 26/21
.\.github\skills\kpi-report\kpi-calc.ps1 -Level pi -Id 2026.25
```
Ausgabe in `.github\skills\kpi-report\out\`. Kapazitaeten pro Sprint in `.github\skills\kpi-report\capacity.json` pflegen. Mehr dazu in `.github\skills\kpi-report\README.md`.

## Inhalt
- `.github/mcp.template.json`: MCP-Server (Atlassian, GitHub, context7, sequential-thinking), `.github/mcp.json` wird beim Start generiert
- `.github/skills/kpi-report/`: der KPI-Skill
- `AGENTS.md`: Arbeitsregeln fuer den Agenten
- `scripts/start.ps1` / `scripts/start.sh`: Token laden, Container-Runtime erkennen, MCP-Config erzeugen, Copilot starten
- `scripts/doctor.ps1`: Setup pruefen (Tokens, Docker/Podman, Node, Copilot, MCP-Config)

Das oeffentlich nutzbare KPI-Repo fuer andere ist `paul-wie/kpi-skill`; dieses Repo ist der vollstaendige Agent mit MCP-Setup.
