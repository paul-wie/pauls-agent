---
name: kpi-report
description: >
  Create sprint-specific or PI-specific KPI reports from Jira (ASDM features, ASNAST stories) as a
  Porsche-CI HTML page for Confluence. Use when asked for KPIs, a KPI report, sprint KPIs, PI KPIs,
  or "kpi-report sprint <nr>" / "kpi-report pi <nr>".
---

# kpi-report

**Status and next steps: see [`STATUS.md`](STATUS.md) — read it first, update it last.**

## Invocation

```
kpi-report sprint <YY/NN>     e.g. kpi-report sprint 26/20
kpi-report pi <YYYY.NN>       e.g. kpi-report pi 2026.37
kpi-report                    -> asks: PI level or Sprint level? (then asks for the number)
--dry-run                     -> local HTML only, no Confluence write
--kpi <name>                  -> build/verify exactly one KPI (iterative mode)
```

Routing: the first argument (or the answer to the question) selects the level. `pi` -> run only the PI-level KPIs, `sprint` -> run only the Sprint-level KPIs. Never mix levels in one run. A PI report is created only for a finished PI and covers only that PI (no cumulation across PIs).

## KPIs (all defined; all awaiting manual verification in Jira — see STATUS.md)

**PI level**
0. **PI overview (first block of the PI report)**: Delivered (first Technical Review within the PI; tickets + burned SP + by type), Left over at PI end (tickets + highest SP + by type), Added after PI start (tickets + highest SP + by type). All types with Original SP > 0; Won't Do and Sub-tasks excluded; computed in the same loop as PI-KPI 6 (`overview` in the JSON).
1. Feature Cycle Time: ASDM Features of the PI (Jira field **"Program Increment"**, NOT a component, NOT the summary). First `Implementation` -> first `Done` after it, calendar days, average + 3 longest outliers; 90-day policy line; features without Implementation listed as n/a; bulk-migration starts (2026-03-03 14:xx) flagged "uncertain".
2. Avg Story Size: Stories in PI sprints with status category Done (Won't Do excluded); size = SP burned (sum of reductions of field `Story Points`); burned 0 excluded; average only.
3. Ticket distribution: all tickets in the PI sprints, status independent, by type; Sub-tasks and Won't Do excluded; each ticket once.
4. Story Cycle Time: Stories in PI sprints; first `Ready for Dev` -> first `Technical Review` after it, **working days** (Mon–Fri, fractional, holidays not excluded); split into wait (-> In Progress) and work (In Progress ->); averages + 5 longest outliers.
5. Added after PI start: Stories and Bugs first assigned to a PI sprint after PI start + **3 days (fixed grace period)**; SP = highest SP ever recorded; stories moved in from a later PI = "pulled forward" (shown separately, positive).
6. Technical Review rate planned vs added: all types with Original SP > 0; planned = first assigned within PI start + 3 days; TR reached between PI start and PI end.
7. **Technical Review vs Left Over per sprint (chart, tickets)** — moved from sprint level to PI level (2026-10-13). One point per PI sprint; TR = Delivered tickets (S-KPI 1), Left Over = Leftovers (S-KPI 4); running sprint: Left Over = n/a.

**Sprint level** (all types with Original SP > 0; Won't Do and Sub-tasks excluded)
1. Delivered: first `Technical Review` within [sprint start, next sprint start), independent of sprint assignment; SP = burned SP, all-or-nothing; tickets by type.
2. Velocity = Delivered SP / planned person days (capacity, `capacity.json`; Excel not accessible -> user provides); missing/0 -> n/a.
3. Committed = SP (value of field `Story Points` at that time) of tickets in the sprint at sprint **activation** (`activatedDate`); ratio Delivered/Committed.
4. Leftovers (in sprint at sprint end, no Technical Review by then), Added after activation (first assigned after activation; SP = highest ever), Delivered by type.
5. Technical Review rate: planned vs added, how many reached TR in the period.

## KPI catalog (full definitions + visible HTML declarations, English in the report)

Global rules for ALL KPIs: every unique ticket counted once; Won't Do (status `Wont do`, category Done!) and Sub-tasks always excluded and declared; ratios 2 decimals, rounded, decimal comma; missing/0 divisor = "n/a"; uncertain values are flagged with reason and the USER decides in the chat (the skill never decides); PI report only for a finished PI and only that PI (never cumulated); working days = Mon–Fri, public holidays NOT excluded; outliers always listed with ticket key.

### PI level
**PI-KPI 1 Feature Cycle Time** (ASDM). Features of the PI via field "Program Increment" (carry-over features with several PIs are flagged "leftover" and shown in both PIs, but counted once in one average). Cycle time = calendar days from FIRST transition to `Implementation` until FIRST `Done` after it. Headline = arithmetic AVERAGE; no median; 3 longest features listed with key. Red line = 90-day policy, features above it highlighted. Features without Implementation (direct Done) excluded from the average and listed ("12 of 15 features"); not-Done features listed as open with all their PIs; data-quality cases (bulk migration 2026-03-03 14:56 "In Progress -> Implementation", duplicate Done events -> use first Done) flagged "uncertain". Running PI without Done features: n/a. Unit shown: "calendar days".
**PI-KPI 2 Avg Story Size.** Stories in the PI sprints, status category Done, Won't Do excluded. Size = SP BURNED = sum of all reductions of field `Story Points` (3->0 = 3; 3->8->0 = 8; every change of `Story Points` is a burn-down; re-estimates only happen in `Original story points` and are not counted). Stories with burned 0 excluded and listed. Output: ONLY the average. Declaration: "Calculated as SP burned per Done story."
**PI-KPI 3 Ticket distribution.** All tickets (Story, Task, Bug, Risk...) assigned to ANY sprint of the PI (all PI sprints, e.g. 6), **status independent** (declared), Sub-tasks not counted (declared), Won't Do excluded (declared); count and % per type; each ticket once.
**PI-KPI 4 Story Cycle Time.** Stories in the PI sprints (Won't Do excluded). Start = first `Ready for Dev`; end = first `Technical Review` after it; **working days** (Mon–Fri, fractional). Three values (averages, no median): Total (Ready for Dev -> Technical Review), Wait (Ready for Dev -> In Progress), Work (In Progress -> Technical Review); 5 longest stories listed with key. Stories without Technical Review not computable (counted separately); Technical Review without Ready for Dev excluded and flagged. Declaration: "Total = Ready for Dev until Technical Review; Waiting time = Ready for Dev until In Progress; Working time = In Progress until Technical Review. Unit: working days (Mon-Fri, public holidays not excluded). Only Stories that reached Technical Review; Won't Do excluded; each ticket counted once."
**PI-KPI 5 Added after PI start (planning quality).** Stories and Bugs first assigned to a PI sprint AFTER PI start + **3 calendar days (fixed grace period)**. Added time = first Sprint changelog entry with a sprint of the PI; created directly in the sprint = creation time. Output: (a) unplanned added: Stories count + cumulated SP, Bugs count; (b) **pulled forward** (positive, shown separately): Stories moved in from a sprint of a LATER PI (count + cumulated SP). SP = highest SP value ever recorded (estimate; current SP is burned to 0). Declaration: "Tickets added within the first 3 days after PI start are treated as planned (grace period)." plus SP basis, status independent, Won't Do excluded.
**PI-KPI 6 Technical Review rate planned vs added.** All types with Original SP > 0 (Won't Do/Sub-tasks excluded). Planned = first assigned to a PI sprint within PI start + 3 days; Added = later. For each group: how many reached `Technical Review` between PI start and PI end (count by type + SP). Declaration: "Planned = issues first assigned to a PI sprint within 3 days after PI start; Added = issues assigned later. Shown: how many of each group reached Technical Review between PI start and PI end."
**PI-KPI 7 Technical Review vs Left Over per sprint (chart).** Moved up from sprint level. Line chart (reference: old "Sprint-Übersicht" screenshot) + table, one point per sprint of the PI, counts TICKETS not SP (all types, Original SP > 0). Line 1 = tickets that reached Technical Review (= Delivered tickets S-KPI 1), line 2 = Left Over (= Leftovers S-KPI 4); identical numbers as in the sprint report. Running sprint: Left Over "n/a". Open: meaning of the "PI Start" row (27/0) in the old chart.

### Sprint level (basis: all ASNAST issue types Story/Task/Bug with `Original story points` > 0)
**S-KPI 1 Delivered.** Ticket first reaches `Technical Review` within the sprint period (start of sprint -> start of next sprint), independent of sprint assignment. SP = burned SP, all-or-nothing, no split across sprints. Tickets by type. Excluded for missing Original SP (user confirmed): e.g. ASNAST-15767, 14834, 13661. Declaration: "Delivered SP = story points of all issues (Story, Task, Bug; Won't Do and Sub-tasks excluded) with Original Story Points > 0 that reached Technical Review during the sprint period."
**S-KPI 2 Velocity** = Delivered SP / planned capacity (person days, from the capacity Excel / `capacity.json`; Excel on SharePoint not accessible -> ask the user to provide it; the Excel itself is never shown in the report). 2 decimals; missing/0 capacity = n/a. Declaration: "Velocity = Delivered SP divided by planned capacity (person days) of the sprint."
**S-KPI 3 Committed SP** = SP of the same issue set assigned to the sprint at sprint start (activation; later snapshot on the morning of the sprint change via git pipeline). ONE variable per sprint, used in every KPI, never recalculated. Ratio Delivered/Committed, 2 decimals, > 1,00 accepted. Reference only: Jira Sprint Report shows higher values (26/17 = 47, 26/18 = 56, 26/19 = 100) because removed tickets are invisible to the replay. Declaration: "Committed SP = story points of the same issue types assigned to the sprint at sprint start. Ratio = Delivered SP / Committed SP, 2 decimals."
**S-KPI 4 Leftovers / Added / Delivered overview.** Leftovers = tickets assigned to the sprint at sprint end (start of next sprint) without `Technical Review` by then (the ones taken into the next sprint): count by type + cumulated SP. Added = first assigned to the sprint after sprint activation (no grace period): count by type + SP. Delivered tickets by type. SP for Leftovers/Added = highest SP ever recorded. Declaration: "Leftovers = issues assigned to the sprint at sprint end that did not reach Technical Review. Added = issues first assigned to the sprint after sprint start. Story points = highest estimate recorded. Delivered tickets = issues that reached Technical Review during the sprint period."
**S-KPI 5 Technical Review rate planned vs added.** Planned = assigned at activation (the Committed set), Added = first assigned after activation; for each: how many reached Technical Review in the sprint period (by type + SP). Tickets delivered but neither planned nor added are possible (delivery is independent of assignment). Declaration: "Planned = issues assigned to the sprint at sprint start; Added = issues first assigned after sprint start. Shown: how many of each group reached Technical Review during the sprint period."
(Former S-KPI 6, the Technical Review vs Left Over chart, is now PI-KPI 7.)

## Deterministic calculation (MANDATORY)

The numbers are NEVER computed by hand or ad hoc in the chat. They come only from **`kpi-calc.ps1`** (same input -> same numbers, run twice = identical):

```
powershell -File kpi-calc.ps1 -Level pi -Id 2026.25
powershell -File kpi-calc.ps1 -Level sprint -Id 26/19
```
- Reads Jira via REST (`https://api.skyway.porsche.com/jira`, proxy `http://http-proxy.porsche.org:3133`, Bearer token from the env variable `JIRA_PERSONAL_TOKEN`, exported from `.env` by the user; never read `.env` directly, never print the token). Read-only.
- Writes `out/pi-<id>.json|html` or `out/sprint-<yy-nn>.json|html`. The sprint HTML is rendered from `sprint-template.html` (final design, see "HTML / CI"); the PI HTML is still generated directly by the script. Numbers and layout always come from the same run. Files needed: `kpi-calc.ps1`, `capacity.json`, `sprint-template.html`, `assets/logo.jpg`.
- Sprint list/dates from the agile API (board 114224): PI sprints = names with `(YYYY.NN)`; PI start = start of first PI sprint; PI end = start of the next sprint; activation = `activatedDate`.
- Capacity per sprint: `capacity.json` (key = `YY/NN`, person days).
- Any change of a definition = change in `kpi-calc.ps1` + entry in `STATUS.md`; never override numbers in the HTML manually.

Known limits: a replay of the changelog finds only tickets that still carry the sprint in their history (tickets removed from a sprint are missed; Jira Sprint Report shows higher Committed, e.g. 26/19 = 100). Jira does not log the initial sprint assignment at creation: first event `from` state / creation date is used. Committed will be snapshotted by a git pipeline later (then stored, never recalculated). The 3-day grace period is fixed.

**HTML cards (sprint):** S-KPI 3 shows the RATIO Delivered/Committed as the headline number (Committed SP and Delivered SP as sub-line); S-KPI 4 has separate cards for Leftovers and Added (tickets, SP, by type); S-KPI 5 is one card with two blocks (planned x/y, added x/y, each by type + SP).

## HTML / CI

Output is always English, fixed layout, numbers overwritten per run. Every KPI keeps its declaration (calculation basis, unit) — in the sprint dashboard it is the hover text of the "i" circle on each card. The capacity Excel is only an input for Velocity and is NOT shown in the report.

### Sprint dashboard — FINAL design (approved by the user 2026-10-21, do not change without request)
- **Design lock (technical):** the approved files are archived read-only in `design-final/` (`sprint-template.FINAL.html`, `logo.FINAL.jpg`, `hashes.txt` with SHA256). Before rendering, `kpi-calc.ps1` compares `sprint-template.html` and `assets/logo.jpg` against these hashes and STOPS with an error if they differ. The working template is also read-only. Restore with `Copy-Item design-final\sprint-template.FINAL.html sprint-template.html -Force`. Only if the user explicitly asks for a design change: edit the template, then update `design-final/` and `hashes.txt`.
- **Template:** `sprint-template.html` (the user's approved `dashboard.html`, only text made English and values replaced by `{{PLACEHOLDERS}}`). `kpi-calc.ps1` fills the placeholders and embeds the logo (`assets/logo.jpg`, the black PORSCHE wordmark, shown white via `filter: invert(1); mix-blend-mode: screen`) as base64, so the output file is standalone. The script throws if a placeholder stays unreplaced. Design changes = edit the template only; numbers = edit the script only.
- **Look:** Arial everywhere; dark grey gradient background with a soft red glow top right; centred logo, eyebrow "Sprint Level Report", H1 "ASNASt KPI <red>Sprint YY/NN</red>" (spelled exactly **ASNASt**, small t); chips for sprint + PI, sprint name, date range and status (Closed / Running); section headings with a small red bar; light-grey rounded cards (radius 18 px, hover turns white and lifts); big numbers (68 px), small grey labels; round "i" info circle top right of each card with a dark tooltip (declaration); badges (green `good` / amber `warn`); progress bars; footer "AI-driven analyzed · Source: Jira ASDM / ASNAST · generated <date>".
- **Layout (12-column grid):** Section "Delivery, commitment & flow of the sprint": row 1 = three hero cards (red top border, span 4): S-KPI 1 Delivered (SP big, tickets + by type), S-KPI 2 Velocity (value, "Delivered SP / <capacity> planned person days"), S-KPI 3 Delivered/Committed (RATIO big + badge "+x %" good if ratio >= 1 else warn, Committed/Delivered SP, bar capped at 100 %, text "Commitment met / not met"); row 2 = two cards (span 6): S-KPI 4 Leftovers (tickets + badge "open", or "n/a" + "sprint running" for a running sprint; SP + by type) and S-KPI 4 Added after start (tickets, SP, by type). Section "Technical Review": one full-width card S-KPI 5 with two blocks (Planned x / n, Added x / n; each with by-type "reached/total", burned SP, percent bar).
- **Placeholders** are filled from the `SprintKpi` result (see `$map` in `kpi-calc.ps1`); missing values show "n/a"; percentages = round(100 * reached / total).
- **Tooltips (declarations):** S-KPI 1 "Reached Technical Review within the sprint period; all types with Original SP > 0; Won't Do and Sub-tasks excluded." S-KPI 2 "Capacity from the team capacity Excel (input only)." S-KPI 3 "Ratio = Delivered SP / Committed SP, 2 decimals. Committed = SP of the same issue types assigned to the sprint at sprint start; one value used in all KPIs." S-KPI 4 Leftovers "Leftovers = assigned to the sprint at sprint end without Technical Review."; Added "Added = first assigned to the sprint after sprint start. SP = highest estimate recorded." S-KPI 5 "Planned = assigned at sprint start; added = first assigned after sprint start. Shown: how many of each group reached Technical Review during the sprint period (SP = burned)."

### PI report — design FINAL
The PI report uses its own template `pi-template.html` (from the user's `dashboard2.html`, approved 2026-10-21: "design fits perfectly") with the same CSS/look as the sprint dashboard. Sections: PI overview (3 hero cards) / Feature & story flow (PI-KPI 1 with top-3 list + Jira links, PI-KPI 2, PI-KPI 4 with wait/work bar + top-5) / Scope & planning (PI-KPI 3, 5, 6) / Trend (PI-KPI 7 SVG chart, black = Technical Review, red = Left Over). Info-circle tooltips carry the declarations. The script only fills `{{PLACEHOLDERS}}` and aborts if one stays unreplaced. **Design lock:** SHA256 of `pi-template.html` (key `pitemplate`) and `assets/logo.jpg` in `design-final\hashes.txt`; read-only copy `design-final\pi-template.FINAL.html`. Design change = edit template + update hash deliberately; number change = edit only the script. Sprint and PI reports stay strictly separate files and levels.

**Trigger:** the user says "sprint 26/19" (or "kpi-report sprint 26/19") -> run `kpi-calc.ps1 -Level sprint -Id 26/19` and open `out/sprint-26-19.html`; "pi 2026.25" -> PI report. "Current sprint" = the sprint with state `active` on board 114224 (Leftovers then n/a, report status "Running"); "last finished sprint" = the newest closed one.

## Data sources (read-only Jira)

| Level | Jira project | Meaning |
|-------|--------------|---------|
| Feature | `ASDM` | Features, assigned to a PI |
| Story | `ASNAST` | Stories, assigned to a Sprint (scrum board 114224) |

### External data source: Excel on SharePoint (capacity planning)
Some KPIs need `Kapazitaetsplanung_ASNASt_2024.xlsx` (SharePoint site ASNAST). The skill is used by several people, so it must never assume a local path:
1. Try to read the file from SharePoint/OneDrive (the user must have access).
2. If it cannot be accessed (e.g. 401, not synced), do NOT guess and do NOT use other Excel files. Tell the user: "No access to the SharePoint Excel. Please upload/provide the file (or its local path)." and wait.
3. Read the uploaded file locally, read-only. Verify that required sheets/columns exist; otherwise list what is missing.

## Naming conventions

- **PI**: `YYYY.NN`, e.g. `2026.37`.
- **Sprint**: `YY/NN (YYYY.NN) <fun name>`. Only the leading `YY/NN` and the PI number in
  parentheses are relevant. The trailing name changes every sprint and MUST be ignored.
  Match sprints with the prefix `YY/NN`, never with the full name.

## Logic

1. Resolve scope: sprint → sprint by prefix; PI → all sprints whose PI number matches.
2. Run `kpi-calc.ps1` (see "Deterministic calculation"); check the env token first, ask the user to export it if missing. Unverified KPIs are flagged "draft".
3. Output `out/pi-<id>.html` / `out/sprint-<yy-nn>.html` (+ `.json` with all numbers).
4. Report the numbers to the user from the JSON, never from memory. A Confluence write (never in `--dry-run`, only after
   explicit human confirmation) updates the existing page instead of creating a duplicate.

## Consistency rule (HARD)

**Every figure is computed exactly once and then reused unchanged everywhere in the report** (transparency).
- Delivered SP per sprint: S-KPI 1 (all issue types with Original Story Points > 0; Won't Do and Sub-tasks excluded; first Technical Review within the sprint period; burned SP, all-or-nothing).
- Committed SP per sprint: ONE stored variable per sprint (`committed[sprint]`), same issue filter as Delivered. Until the git pipeline snapshots it on the morning of the sprint change, it is back-calculated by the script from the changelog at the sprint activation date. Every KPI reads this variable; no KPI recalculates it.
- Ratios (Velocity, Delivered/Committed) use these numbers only, 2 decimals, rounded, decimal comma (1,25); missing/0 divisor -> "n/a".
Never recalculate, filter or vary a number per KPI. Ratios above 1,00 are accepted.

## Iterative KPI rule

One KPI at a time: define → implement JQL/calculation → human checks the numbers manually in
Jira → mark as verified in `STATUS.md`. Never present an unverified KPI as final.

## Safety

Jira is read-only. Confluence writes only after explicit human confirmation. No tokens in output.

**SP basis (since 2026-10-27):** every SP value in every KPI is Original SP (customfield_10500, latest value). No burned SP, no SP-history values (see STATUS.md).

**S-KPI 5 reconciliation:** the card ends with a fine-print line 'Planned + Added + Other = Delivered' (tickets and SP). Other = reached Technical Review in the period but neither planned at activation nor added after it. Must always add up to S-KPI 1.

## Confluence archive of sprint reports (confluence-archive.ps1)
Every sprint report is archived on the Confluence page **"19 KPI's"** (space ASNAST, page id 2714063024, https://skyway.porsche.com/confluence/spaces/ASNAST/pages/2714063024/19+KPI+s).
- **Page body = exactly ONE two-column table, nothing else:** column 1 = sprint number (e.g. `26/20`), column 2 = link to the attached HTML file. No AI notice, no numbers, no text in the body (user decision 2026-10-27). The page keeps the label `ai-generated`.
- **File name:** `Sprint KPI Report <yy-nn> - erstellt <YYYY-MM-DD>.html` (name + creation date), attached to the page.
- **Continue the table:** a new sprint is appended as a new row; the table is never recreated or reordered.
- **Same sprint again = overwrite:** if the sprint is already in the table, its row and its old attachment are replaced (old attachment deleted, new one uploaded with today's date); never a second row or a second file for the same sprint.
- **Run:** first `kpi-calc.ps1 -Level sprint -Id 26/21`, then `.\confluence-archive.ps1 -Sprint 26/21` (`-DryRun` shows what would happen without writing). Needs `CONFLUENCE_PERSONAL_TOKEN` exported from `.env`. Confluence writes only after the user asked for archiving (trigger e.g. "archive sprint 26/20 on Confluence"); the script is never run unprompted.
- Technical: REST host `https://api.skyway.porsche.com/confluence` via proxy (the MCP upload cannot read local files); Confluence shows HTML attachments as a download, it does not render them.

## Final rules (2026-10-27)
- Leftover cut-off = start of the next sprint (not carry-over; see tooltips).
- Tickets with Technical Review before the sprint start (sprint report) / PI start (PI-KPI 6) are excluded from the planned/committed basis.
- Working days = Mon-Fri, holidays NOT considered.
- Capacity: Excel is authoritative (PI 2026.25 = 366,5 PD); maintain per-sprint values in capacity.json (pending).
- Copying the skill to .github\skills / SharePoint mirror: undecided, ask the user.

### PI reports on the same Confluence page
The page body has TWO two-column tables: (Sprint | File) first, (PI | File) below. PI archive: `kpi-calc.ps1 -Level pi -Id 2026.25` then `.\confluence-archive.ps1 -Pi 2026.25 [-DryRun]`. File name: `PI KPI Report <id> - erstellt <YYYY-MM-DD>.html`. Same PI again overwrites its row + attachment; new PIs are appended to the PI table. Archive only after the user approved the report.

### Status (2026-10-27)
Sprint and PI reports are final and archived on the Confluence page (page version 7): Sprint 26/20 in the sprint table, PI 2026.25 in the PI table. PI-KPI 6 excludes tickets with TR before PI start. Dead code removed. Repo: https://github.com/paul-wie/kpi-skill.git (private). Open: per-sprint capacity from the Excel (366,5 PD, user to deliver), skill embedding into another repo.

### S-KPI 4 ticket lists (2026-11-04)
The Leftovers and Added cards list the concrete tickets below the numbers: Jira link (key), title shortened to 60 characters with '...', Original SP; small, subtle style (class .tlist). Leftovers list shows 'Available after sprint end.' while the sprint is running. Data: addedList / leftList in the sprint JSON. Template changed deliberately, hashes renewed.
