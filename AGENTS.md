# Pauls ASNAST Agent - Agent Instructions

Persoenliches Arbeits-Repo fuer KPI-Reports und Ad-hoc-Fragen zu **ASNAST** (Stories/Tasks/Bugs) und **ASDM** (Features) in Jira/Confluence. Nicht PLES-spezifisch.

## Konventionen
- Sprache: Deutsch fuer Dokumentation und Antworten, Englisch fuer Code.
- Antworten kurz und konkret halten.

## Zugang und Tokens
- Tokens (`JIRA_PERSONAL_TOKEN`, `CONFLUENCE_PERSONAL_TOKEN`, optional `GITHUB_PERSONAL_ACCESS_TOKEN`) kommen **immer** aus der `.env` im Repo-Root, geladen per `.\scripts\start.ps1`. Nie hart codieren, nie ausgeben, nie committen.
- Die `.env` selbst nie lesen oder ausgeben. Nur pruefen, ob eine Variable gesetzt ist (Laenge), nie den Wert.
- Jira und Confluence erreicht man nur im Firmennetz/VPN ueber den Proxy `http://http-proxy.porsche.org:3133`.
- Jira: `https://api.skyway.porsche.com/jira` (Board 114224, Original SP = `customfield_10500`, Sprint = `customfield_10004`).
- Confluence: `https://api.skyway.porsche.com/confluence`.
- MCP-Server (`.github/mcp.template.json`, generated to `.github/mcp.json` by the start scripts): mcp-atlassian (Jira + Confluence), github, context7, sequential-thinking.

## Sicherheitsregeln
- Jira ist standardmaessig **nur lesend**. Schreibzugriffe (Tickets aendern, Sprints bearbeiten) nur nach ausdruecklicher Anweisung. Sprints nie direkt per MCP bearbeiten.
- Confluence wird nur durch `confluence-archive.ps1` beschrieben, und nur wenn der Nutzer das Archivieren verlangt.
- Vor jeder irreversiblen Aktion (Git-History, Loeschen, Schreiben in Fremdsysteme) nachfragen.

## KPI-Skill
Der Skill `kpi-report` liegt in `.github/skills/kpi-report/` (Details in dessen `SKILL.md`, `STATUS.md`, `README.md`). Das Design der HTML-Templates ist per Hash gesperrt (`design-final/`); nur bewusst und mit Hash-Erneuerung aendern. Zahlen kommen ausschliesslich aus `kpi-calc.ps1`.

```powershell
.\.github\skills\kpi-report\kpi-calc.ps1 -Level sprint -Id 26/21
.\.github\skills\kpi-report\kpi-calc.ps1 -Level pi -Id 2026.25
```
