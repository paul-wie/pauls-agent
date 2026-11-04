# kpi-report

Berechnet KPIs aus Jira (ASDM = Features, ASNAST = Stories/Tasks/Bugs) und erzeugt feste HTML-Dashboards auf **Sprint-** und **PI-Ebene**. Alle Zahlen kommen deterministisch aus `kpi-calc.ps1`, das Layout ist per Hash gesperrt (`design-final\`).

## Voraussetzungen
- Windows + PowerShell, Firmennetz/VPN (Proxy `http-proxy.porsche.org:3133`)
- Umgebungsvariablen: `JIRA_PERSONAL_TOKEN` (und `CONFLUENCE_PERSONAL_TOKEN` fuer das Archiv)
- Jira-Leserechte auf ASDM/ASNAST

## Report erzeugen
```powershell
.\kpi-calc.ps1 -Level sprint -Id 26/20     # Sprint-Report -> out\sprint-26-20.html
.\kpi-calc.ps1 -Level pi -Id 2026.25       # PI-Report     -> out\pi-2026.25.html
```
Optional archivieren (Confluence-Seite "19 KPI's", je eine Tabelle fuer Sprints und PIs; gleicher Sprint/PI wird ueberschrieben):
```powershell
.\confluence-archive.ps1 -Sprint 26/20 [-DryRun]
.\confluence-archive.ps1 -Pi 2026.25 [-DryRun]
```

## Capacity pflegen
Vor jedem Sprint-Report die Personentage des Sprints in `capacity.json` eintragen (Quelle: Team-Kapazitaets-Excel), z. B. `"26/21": 68`. Fehlt der Wert, ist die Velocity `n/a`.

## Grundregeln
- **SP** = Original Story Points (letzter Stand zum Berichtszeitpunkt).
- **Delivered** = Ticket erreicht erstmals *Technical Review* im Zeitraum (Won't Do und Sub-tasks ausgeschlossen).
- **Committed** = Tickets im Sprint bei Aktivierung; Tickets mit TR vor Sprintstart zaehlen nicht.
- **Leftover** = bei Sprintende im Sprint ohne TR (nicht automatisch Carry-over).

## Sprint-KPIs
| KPI | Berechnung |
|---|---|
| S-KPI 1 Delivered | Tickets und SP mit erstem TR im Sprintzeitraum, nach Typ |
| S-KPI 2 Velocity | Delivered SP / Kapazitaet (Personentage) |
| S-KPI 3 Committed | Committed SP, Quote = Delivered / Committed |
| S-KPI 4 Leftovers / Added | Leftovers am Sprintende; Added = nach Aktivierung zugewiesen |
| S-KPI 5 TR-Quote | Planned vs. Added: Anteil mit TR; Abstimmung Planned + Added + Other = Delivered |

## PI-KPIs
| KPI | Berechnung |
|---|---|
| Overview | Delivered, Leftover und Added im PI (Tickets, SP, nach Typ) |
| PI-KPI 1 Feature Cycle Time | Kalendertage Implementierungsstart bis Abschluss (ASDM) |
| PI-KPI 2 Avg Story Size | Durchschnittliche SP erledigter Stories |
| PI-KPI 3 Ticketverteilung | Tickets in PI-Sprints nach Typ, statusunabhaengig |
| PI-KPI 4 Story Cycle Time | Arbeitstage (Mo-Fr) Ready for Dev bis TR: gesamt, Wartezeit, Arbeitszeit |
| PI-KPI 5 Added nach PI-Start | Stories/Bugs, die mehr als 3 Tage nach PI-Start zugewiesen wurden |
| PI-KPI 6 TR-Quote | Planned vs. Added, Anteil mit TR im PI |
| PI-KPI 7 TR vs. Leftover | Tickets je Sprint des PI (Diagramm) |

Details, Entscheidungen und Historie: `SKILL.md`, `STATUS.md`.
