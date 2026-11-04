# kpi-report — Status

Last updated: 2026-10-13

## Decisions
- Invocation: `kpi-report sprint <YY/NN>` | `kpi-report pi <YYYY.NN>`; no ID = latest closed.
- Sources: ASDM (Feature level), ASNAST (Story level; scrum board 114224 "1. ASNAST RT-Dev-Board").
- Naming: PI `2026.37`; sprint `26/20 (2026.37) <irrelevant fun name>` — match on prefix only.
- Output: always HTML, identical layout, Porsche CI, numbers overwritten; stored in Confluence.
- Approach: incremental — one KPI at a time, manually verified in Jira before it counts.
- Storage: local only (this folder), NOT in the git repo.
- Jira access verified (ASDM readable; ASNAST readable, 11779 issues).

## Findings (2026-10-13, ASDM discovery)
- PI is a **component** on the Feature: `PI 2025.49`. Existing PI components: 2025.37, 2025.49 (archived).
- Feature workflow: New → Funnel → Program Backlog → Implementation → Done (also back-transitions).
- Cycle time source: changelog `status` items (`jira_get_issue` with `expand=changelog`, fields
  `created`, `from_string`, `to_string`). Output is huge (~260 KB for one issue) -> parse, don't read.
- PI 2025.49 has 15 Features, all Done (JQL: `project = ASDM AND issuetype = Feature AND component = "PI 2025.49"`).
- Carry-over: Features can carry several PI components (ASDM-9, ASDM-14, ASDM-27 in 2025.37 + 2025.49).
- No Python on this machine (WSL bash exists); use PowerShell or Node for parsing.

## KPI 1: Feature Cycle Time (PI level) — DRAFT, awaiting manual verification
**Headline number = AVERAGE (arithmetic mean) of the per-feature cycle times** (decided 2026-10-13).
Median may be shown as secondary info only. Features without a cycle time are excluded from the
average and listed separately.
Definition: calendar days from FIRST transition to `Implementation` until FIRST transition to `Done`
after it. Features of the PI without Implementation or Done are listed as flagged/open (with all their PIs).
Decisions: start = first Implementation; unit = calendar days; evaluate all PI features, flag not-Done ones + all PIs.

Draft result PI 2025.49 (15 features, 12 computable): avg 57.2 d, median 22.9 d.
| Feature | Impl | Done | Days |
|---|---|---|---|
| ASDM-2 | 2026-04-09 | 2026-09-10 | 154.1 |
| ASDM-3 | 2026-03-03 | 2026-03-12 | 9.1 |
| ASDM-4 | 2026-03-03 | 2026-03-25 | 21.9 |
| ASDM-5 | 2026-06-09 | 2026-07-02 | 23.1 |
| ASDM-9 (also PI 2025.37) | 2026-03-03 | 2026-06-23 | 111.9 |
| ASDM-13 | 2026-03-03 | 2026-06-18 | 106.8 |
| ASDM-14 (also 2025.37) | 2026-03-03 | 2026-03-25 | 21.9 |
| ASDM-15 | 2026-03-03 | 2026-03-25 | 21.9 |
| ASDM-17 | 2026-03-03 | 2026-03-12 | 9.1 |
| ASDM-19 | 2026-03-03 | 2026-07-01 | 120.0 |
| ASDM-23 | 2026-03-03 | 2026-03-26 | 22.7 |
| ASDM-24 | 2026-06-09 | 2026-08-12 | 64.2 |
| ASDM-7, ASDM-27 (also 2025.37), ASDM-28 | never in Implementation | Done | n/a |

Data quality issues found:
- 2026-03-03 14:56: bulk workflow migration "In Progress -> Implementation" for 9 features. Their
  Implementation start is NOT the real start -> cycle times of those are unreliable (open question: use alternative start?).
- Some Done events occur twice (ASDM-17, ASDM-27: second Done on 2026-03-17 = migration). Use FIRST Done.
- ASDM-7/27/28 went directly to Done (no Implementation).

## Demo current PI 2026.37 (2026-10-13)
PI selection rule for the demo: Feature `summary ~ "2026.37"` — no `PI 2026.37` component exists yet
(TODO: agree on a clean PI assignment, e.g. component per PI). 5 Features, none Done -> average = n/a.
| Feature | Impl since | Running days |
|---|---|---|
| ASDM-63 | 2026-09-10 | 32.8 |
| ASDM-65 | 2026-09-10 | 32.8 |
| ASDM-66 | 2026-09-10 | 32.8 |
| ASDM-69 | 2026-09-10 | 33.0 |
| ASDM-74 | 2026-09-16 | 26.7 |
Running days are informational only and not part of the average.

## Decisions KPI 1 (2026-10-13, round 2)
- **Uncertain values:** features whose cycle time is affected by data quality (e.g. bulk migration
  2026-03-03 14:56, duplicate Done events) are output as **"uncertain"**, with reason and what exactly
  is uncertain. The skill does NOT decide: the user decides in the chat whether to include/exclude/adjust.
- **Features without Implementation** (direct to Done): excluded from average, listed visibly
  ("12 of 15 features"). Expected NOT to occur in future (process now requires Implementation).
- **Leftovers** (formerly "carry-overs"; always use this term): features assigned to more than one PI.
  There is only ONE calculation: average over all features of the PI. Leftovers only affect
  *presentation*: flag them, and show them also in the PI they were carried over into/from.
- **Median** is shown additionally to the average (outliers visible).
- **Policy red line: 90 days** maximum cycle time. Shown as a red line in the HTML chart; features above
  it are highlighted. PI 2025.49 above 90 d: ASDM-2 (154.1), ASDM-19 (120.0), ASDM-9 (111.9), ASDM-13 (106.8).
- Running PI without Done features: KPI shows n/a (acceptable for now). Optional: check last PI as demo.
- Manual verification in Jira before "verified" (agreed).

## KPI 3: Ticket distribution by type (PI level) — DRAFT, awaiting manual verification
Decisions (2026-10-13): count ALL tickets assigned to the PI's sprints (236880, 236882, 236884, 236886), **status independent** (declare in report: "status independent"); Sub-tasks NOT counted (declare in report); Won't Do always excluded (declare); every unique ticket counted exactly ONCE (applies to ALL KPIs; PI level, no double counting; leftovers only flagged for display).
Demo PI 2026.37: Story 74 (69.8%), Task 23 (21.7%), Bug 9 (8.5%) = 106 tickets. Excluded: 10 Won't Do (7 Story, 2 Task, 1 Bug), 7 Sub-tasks.
JQL sprint-in returns each ticket once, so no duplicates.

## KPI 4: Story Cycle Time Ready for Dev -> Technical Review, working days (PI level) — DRAFT, awaiting decisions + manual verification
Definition (2026-10-13): all Stories (ASNAST) in the PI's sprints (Won't Do excluded, each ticket once); start = first entry into status `Ready for Dev`, end = first entry into `Technical Review`. Unit = **working days** (Mon-Fri, fractional, Sat/Sun excluded; public holidays NOT excluded yet - open). Output: average (+ median, calendar-day equivalent for reference).
HTML: under each cycle-time number show the unit: KPI 1 = "calendar days", KPI 4 = "working days". Basis text: "Calculated from status change Ready for Dev until Technical Review".
Demo PI 2026.37 (74 Stories): 39 computable. Avg **14.5 working days** (= 20.4 calendar days), median 10.7 WD.
Not computable (35): never reached Technical Review (still New/Refinement/Ready for Dev/In Progress) or no Ready for Dev event (ASNAST-15791).
Uncertain: ASNAST-15791 (Technical Review without Ready for Dev, excluded), ASNAST-15603 (3x Ready for Dev, first used: 32.0 WD), ASNAST-14273 (2x Ready for Dev).
Top: ASNAST-15651 (55 WD), 15650 (44.9), 15471 (36), 15695 (33.3), 15603 (32).

Finding (2026-10-13, user: avg seems long): split of the 14.5 WD: wait Ready for Dev -> In Progress avg 10.5 WD (median 6.0; 23 of 39 > 5 WD), active In Progress -> Technical Review avg 4.0 WD (median 3.3). Cause = queue time in Ready for Dev, not dev time. Decision open: keep as defined or split / start at In Progress.

**DECISION (2026-10-13): Option 2 = split.** KPI 4 outputs three values (all working days, avg): Total Ready for Dev -> Technical Review (14.5), Wait phase Ready for Dev -> In Progress (10.5), Work phase In Progress -> Technical Review (4.0). Wait start = first Ready for Dev; In Progress = first In Progress after it. Stories without In Progress step are excluded from the split (39 of 39 had it in demo). Median shown additionally as in KPI 1 (total 10.7, wait 6.0, work 3.3).
HTML declaration (English, visible): "Total = Ready for Dev until Technical Review; Waiting time = Ready for Dev until In Progress; Working time = In Progress until Technical Review. Unit: working days (Mon-Fri, public holidays not excluded). Only Stories that reached Technical Review; Won't Do excluded; each ticket counted once."

**UPDATE (2026-10-13): KPI 4 shows NO median.** Outliers = the 3 longest Stories by total working days, listed with key: ASNAST-15651 (55.0 WD), ASNAST-15650 (44.9 WD), ASNAST-15471 (36.0 WD). Output KPI 4 = averages only (Total 14.5 / Wait 10.5 / Work 4.0 WD) + 3 outliers. Open: apply the same (no median, top-3 outliers) to KPI 1?

**UPDATE (2026-10-13): KPI 1 aligned with KPI 4.** No median; outliers = the 3 longest Features with key. PI 2025.49: ASDM-2 (154.1 d), ASDM-19 (120.0 d), ASDM-9 (111.9 d). Average stays 57.2 calendar days. 90-day policy red line stays in the chart (4 features above: ASDM-2, 19, 9, 13). Supersedes the earlier "show median" decision.

**UPDATE (2026-10-13): KPI 4 outliers = 5 longest Stories (instead of 3):** ASNAST-15651 (55.0 WD), ASNAST-15650 (44.9), ASNAST-15471 (36.0), ASNAST-15695 (33.3), ASNAST-15603 (32.0). Open: KPI 1 stays at 3 outliers unless changed.

## KPI 5: Added Stories & Bugs after PI start (PI level) — DRAFT, awaiting decisions + manual verification
Definition (2026-10-13): Stories and Bugs (ASNAST) first assigned to a PI sprint AFTER the PI start (PI start = start date of first PI sprint, PI 2026.37 = 2026-09-10 09:58). Won't Do excluded, Sub-tasks not counted, each ticket once. Output: count per type + cumulated SP (Stories; Bugs have no SP).
Added time = first Sprint changelog entry assigning a "2026.37" sprint; if the ticket was created directly in the sprint (no event) = creation time.
SP basis = estimate (initial/Original story points = max SP value), because current SP is burned down to 0.
Demo PI 2026.37: 19 added = 12 Stories (cum. SP 27) + 7 Bugs (no SP).
Stories: ASNAST-15755 (2), 15819 (1), 15813 (2), 15827 (3), 15828 (2), 15830 (1), 15831 (2), 15814 (3), 15836 (3), 15837 (3), 15795 (5), 15845 (no estimate).
Bugs: ASNAST-15820, 15821, 15833, 15780, 15840, 15844, 15846.
Borderline: ASNAST-15755 (added 10:59, 1 h after start), ASNAST-15795 (created 10:08, 10 min after start) = planning day.
SCOPE FINDING: PI 2026.37 has 6 sprints (26/18-26/23; IDs 236880, 236882, 236884, 236886, 236888, 236890). KPI 2-4 demos used only 4 (without 236888/236890 = 32 tickets) -> KPI 3/4 must be recomputed (Story+Bug in 6 sprints: 111). Open decision.

**UPDATE (2026-10-13): grace period.** Counting starts 3 calendar days after PI start (PI 2026.37 cutoff 2026-09-13 09:58; PI 2026.25 start 2026-06-18 16:02, cutoff 2026-06-21 16:02). Declare in HTML: "Tickets added within the first 3 days after PI start are treated as planned (grace period)." Supersedes borderline question (ASNAST-15755 and 15795 are now not counted).
Result PI 2026.37 (6 sprints): 17 added = 10 Stories (cum. SP 20) + 7 Bugs.
Sample PI 2026.25 (sprints 232220-232225, 109 Stories+Bugs, Won't Do excluded): 43 added = 21 Stories (cum. SP 55) + 22 Bugs. Note: 6 Stories (ASNAST-15709, 15711, 15710, 15683, 15721, 15720) were moved in from a later-PI sprint (26/18 2026.37) in Aug; counted as added. SP basis = highest SP ever (estimate); several stories have 0/no SP.
Open: 3 days fixed? (user said "2-3 days"); moved-in-from-other-PI tickets counted as added.

**CLARIFICATION (2026-10-13): Purpose of KPI 5 = planning quality.** Count tickets that were NOT planned at PI planning (= not in a PI sprint at PI start + grace period). Stories pulled forward from a later PI also count as added (not planned in this PI). Supersedes the idea to separate/remove them. Result unchanged: PI 2026.25 = 21 Stories (55 SP) + 22 Bugs; PI 2026.37 = 10 Stories (20 SP) + 7 Bugs. Breakdown PI 2026.25 Stories: 10 created and assigned same day, 4 created in PI and assigned 1-6 d later, 1 from backlog, 6 pulled forward from PI 2026.37 (13 SP).

**DECISION (2026-10-13): grace period fixed = 3 days after PI start.** Check PI 2026.25: 66 of 109 tickets were assigned before the cutoff (bulk on 06-11: 39, 06-16: 6, 06-18: 17 = PI planning fill); later additions are single tickets spread over weeks, i.e. not planning fill.

**DECISION (2026-10-13): pulled-forward split.** Stories moved in from a sprint of a LATER PI are "pulled forward" = rated POSITIVE and shown separately (count + cumulated SP), not in the "unplanned added" figure. KPI 5 output: (a) added unplanned: Stories count + cum. SP, Bugs count; (b) pulled forward (positive): Stories count + cum. SP. Detection: Sprint changelog `from` of the first PI-sprint assignment contains a later PI.
PI 2026.25: added 15 Stories (42 SP) + 22 Bugs; pulled forward 6 Stories (13 SP): ASNAST-15709, 15711, 15710, 15683, 15721, 15720.
PI 2026.37: added 10 Stories (20 SP) + 7 Bugs; pulled forward 0.
HTML: declare grace period (3 days), SP basis (highest SP value = estimate), status independent, Won't Do excluded.

**DECISION (2026-10-13): public holidays are NOT considered** (working days = Mon-Fri only). Declare in HTML: "Working days = Monday to Friday, public holidays not excluded".
**DECISIONS (2026-10-13):** (1) The PI report is only created AFTER the PI is finished (closed) -> the sprint scope is then complete automatically (all PI sprints, e.g. 6 for 2026.37); the open demo-scope issue (4 vs 6 sprints) is no longer an open item. (2) Every PI report starts fresh and covers ONLY that PI; never cumulate across PIs.
**PI level: first draft of 5 KPIs complete (2026-10-13).** Skill routing: ask PI level or Sprint level at invocation, then run only that level's KPIs (documented in SKILL.md). Sprint-level KPIs are next. Pending: holidays for working days; manual Jira verification of all PI KPIs.

## SPRINT LEVEL (started 2026-10-13)
### S-KPI 1: Delivered Story Points per sprint — DRAFT, awaiting verification
**UPDATED 2026-10-13 (see S-KPI 3 FINAL RULES): scope = all issue types (Story, Task, Bug) with Original Story Points > 0, not Stories only. Demo values below are Stories-only = OBSOLETE until recalculated.**
Definition (user, 2026-10-13): delivered = Story first reaches status `Technical Review` within the sprint period (start of sprint to start of next sprint); scope = ALL ASNAST Stories reaching Technical Review in that period, independent of sprint assignment; Won't Do excluded; SP = burned SP (sum of reductions, like KPI 2, whole story history); each story counted once (first Technical Review).
Demo PI 2026.37 (windows: 26/18 09-10 09:58 -> 09-24 10:03; 26/19 -> 10-08 10:03; 26/20 -> now):
- 26/18: 10 Stories, **26 SP** (ASNAST-15735 burned 0)
- 26/19: 25 Stories, **108 SP**
- 26/20 (active, partial): 5 Stories, 13 SP
Uncertain: burned SP is taken over the whole story history, so SP burned before the sprint is counted in the delivery sprint (e.g. ASNAST-15575 = 20, ASNAST-15529 = 13, both in 26/19). Alternative: only SP burned within the sprint period. Also 3 stories reached Technical Review before 26/18 (ASNAST-15533, 15537, 15720) and are not counted.
HTML declaration S-KPI 1 (English, visible): "Delivered Story Points = story points of all Stories that reached the status Technical Review during the sprint period (independent of sprint assignment). Story points are burned SP (sum of all reductions of the field Story Points). Each Story counted once (first entry into Technical Review). Won't Do excluded."
**DECISION (2026-10-13, answer from lead):** SP are not burned in between, so a story delivers ALL its SP or none. All burned SP of a story count in the sprint where it first reaches Technical Review (no split across sprints). The earlier "uncertain" point (SP burned before the sprint) is resolved. Demo values stand: 26/18 = 26 SP, 26/19 = 108 SP, 26/20 = 13 SP (partial).
## Excel data source (capacity planning) — 2026-10-13
Next sprint KPI needs `Kapazitaetsplanung_ASNASt_2024.xlsx` (SharePoint ASNAST). Check result: no access from the agent (SharePoint link 401, file not synced locally). Decision: the skill always checks access first; if not possible it asks the user to upload/provide the Excel (documented in SKILL.md, section "External data source"). KPI definition pending until the file is available.
Note: `ASNASt 2025.xlsx` etc. in the local OneDrive folder `Documents\ASNASt` were only found by a file search; they are not the capacity planning file and were not read.
### S-KPI 2: Velocity per sprint — DRAFT, awaiting verification
Definition (user, 2026-10-13): Velocity = Delivered SP (S-KPI 1) / cumulated planned capacity of the sprint (plan capacity, unit = person days PT). Plan capacity is provided by the user for now (later from the Excel capacity planning, see Excel section).
Test sprint 26/19: Delivered SP 108 / plan capacity 77.5 PT = **1.39 SP per PT**.
Decisions (2026-10-13): Velocity shown with 2 decimals; plan capacity missing or 0 -> "n/a". Open: only manual verification. HTML declaration (English): "Velocity = Delivered SP divided by planned capacity (person days) of the sprint."
### S-KPI 3: Committed SP vs Delivered SP per sprint — DEFINITION FINAL (2026-10-13); everything below this block is superseded history
**FINAL RULES (user, 2026-10-13) — valid everywhere:**
1. **Counted tickets (Delivered AND Committed): all ASNAST issue types (Story, Task, Bug, ...) with `Original story points` > 0.** Sub-tasks and Won't Do excluded. Not "Stories only" any more.
2. **Delivered SP per sprint** = ticket first reaches `Technical Review` within the sprint period (start of sprint -> start of next sprint), SP = burned SP (all-or-nothing, as before). One number per sprint, identical in EVERY KPI and everywhere in the report (Velocity, Committed vs Delivered, ...). Old values (26/18 = 26, 26/19 = 108, 26/20 = 13) were Stories-only and are OBSOLETE; to be recalculated with rule 1.
3. **Committed SP per sprint** = snapshot taken in the MORNING of the sprint change (automated via git pipeline, later). Snapshot = tickets assigned to the sprint with their SP at that time (rule 1 filter). The snapshot is stored and never recalculated; one number, identical everywhere. Until the pipeline exists, the value is provided manually.
4. Ratio Delivered / Committed = decimal, 2 decimals, rounded, decimal comma (1,25); Committed missing/0 -> "n/a". Values above 1,00 accepted.
5. Jira Sprint Report committed values for comparison (user): 26/17 = 47, 26/18 = 56, 26/19 = 100 (replay could not reproduce: 28 / 48 / 94, probably tickets removed from the sprint later). That is the reason for the snapshot.
HTML declaration (English): "Delivered SP = story points of all issues (Story, Task, Bug; Won't Do and Sub-tasks excluded) with Original Story Points > 0 that reached Technical Review during the sprint period. Committed SP = story points of the same issue types assigned to the sprint at sprint start (snapshot on the morning of the sprint change). Ratio = Delivered SP / Committed SP, 2 decimals."
RECALCULATED (new rule, all types, Original SP > 0, Won't Do/Sub-tasks excluded): **26/18 = 24 SP (11 issues), 26/19 = 113 SP (27 issues), 26/20 (active, partial) = 14 SP (7 issues)**. Excluded for missing Original SP but with burned SP: ASNAST-15767 Story (3, 26/19), ASNAST-14834 Task (1, 26/18), ASNAST-13661 Story (3, 26/18, Original 0). Velocity demo 26/19 becomes 113 / 77.5 = 1,46 (old 1.39 obsolete). **Confirmed by user (2026-10-13): the three excluded tickets without Original SP stay excluded; recalculated Delivered values stand.**
COMMITTED (new rule: all types, Original SP > 0, Won't Do/Sub-tasks excluded; replay at sprint activation; stored as ONE variable per sprint, reused in every calculation): **26/17 = 28 SP (6 issues), 26/18 = 45 SP (13 issues), 26/19 = 77 SP (22 issues: 19 Stories 69 SP + 3 Tasks 8 SP)**. Excluded: ASNAST-13661 (3 SP, Original 0) in 26/18. Caveat: replay only finds tickets still in the sprint; the Jira report values 47 / 56 / 100 are higher. 26/19 differs from the earlier Stories-only 86 (probably earlier count included Won't Do stories; not re-verified). Ratios: 26/18 = 24 / 45 = 0,53; 26/19 = 113 / 77 = 1,47. **Confirmed by user (2026-10-13): committed 26/18 = 45, 26/19 = 77 stand as start values.**
--- history below (superseded) ---
Committed SP = SP of Stories that were in the sprint at sprint start (activated date), via replay of the changelog fields Sprint and Story Points. No direct Jira field: JQL `sprint was` is NOT supported on this instance, so removed-and-gone tickets cannot be found (only tickets now sitting in other PI sprints).
Test sprint 26/19 (activated 2026-09-24 11:21): 33 Stories in the sprint, **committed 86 SP** (10 stories with 0 SP at start) vs **delivered 108 SP**.
Uncertain: (a) ASNAST-15575 was 3 SP at start but burned 20 (delivered 20) -> committed and delivered not comparable for partly burned/re-estimated stories; (b) delivered includes Stories added after sprint start (e.g. ASNAST-15819, 15830, 15813) -> ratio > 100% possible; (c) stories already done/at 0 SP at start are in the sprint but add 0 SP.
Open decisions: delivered only from committed Stories vs all delivered; SP basis for partly burned stories.
Cross-check sprint 26/21 (future, 2026-10-13): Stories (no Won't Do) = 31 SP (12 estimated + ASNAST-15845 without SP). Tasks in the sprint carry SP too: ASNAST-15635 (3), 15639 (2), 15723 (2) = 7 SP. Won't Do Stories: ASNAST-15697 (1), 15698 (2) = 3 SP. Stories 31 + Tasks 7 + Won't Do 3 = 41 = Jira number "hive 41" (counts everything). Jira backlog shows 30 (1 SP less than my 31, cause unknown yet).
Open: do Tasks (with SP) count as committed/delivered SP? Currently S-KPI 1 delivered counts Stories only.
Resolved (screenshot 2026-10-13): Jira backlog "30" for 26/21 = 11 issues incl. 3 Tasks (7 SP) + 8 Stories (23 SP). The backlog hides Stories in status `New` (ASNAST-15699 = 1, 15701 = 5, 15786 = 1, 15787 = 1 = 8 SP; plus ASNAST-15845 without SP, in technical Investigation). My 31 SP = 23 + 8 (Stories only, incl. status New). Jira "41" = everything incl. Tasks and Won't Do.
User: delivered = Stories only (as defined). **Decision (2026-10-13): committed = Stories only** (Tasks/Bugs excluded, Won't Do excluded). Status of the story does not matter (my recommendation: status `New` counts, assignment is what counts; pending user confirmation). 26/21 = 31 SP.
HTML declaration (English): "Committed SP = Story Points of all Stories (excl. Won't Do; Tasks and Bugs not counted) assigned to the sprint at sprint start, independent of their status. Delivered SP = see Delivered Story Points (Stories only). Comparison = Delivered / Committed."
Still open: SP basis for partly burned stories, comparison format (percentage).
**Decision (2026-10-13, HARD RULE): Committed SP per sprint = ONE number, the one shown in the Jira backlog for the sprint (Estimate), reused unchanged in every KPI and everywhere in the report.** Comparison = Delivered / Committed as a decimal number with 2 decimals, rounded (e.g. 1,25 or 0,87); Committed missing/0 -> "n/a". Replaces the percentage idea.
CHECK 26/19 (user: Jira sprint report shows committed 100): my Stories-only replay = 86. Tasks/Bugs in sprint at start with SP: ASNAST-15812 (3), 15805 (3), 15647 (2) = 8 -> 94, still 6 short of 100 (ASNAST-15806 Task without SP at start; other differences unclear). Jira sprint report counts all issue types.
TEST 2026-10-13 (replay at activated date, Won't Do/Sub-tasks excluded): 26/18 = Stories 48 SP (14), Tasks/Bugs 0 SP -> 48. 26/17 = Stories 28 SP (6), others 0 -> 28. Awaiting Jira report values for comparison. 26/19: Stories 86 / all types 94 (Jira report 100).
Jira sprint report committed (user, 2026-10-13): 26/17 = 47, 26/18 = 56, 26/19 = 100. My replay (all types, currently-in-sprint tickets only): 28 / 48 / 94 -> always lower (gaps 19 / 8 / 6). Not explained by sub-tasks (0 SP), partly burned stories (max-SP variant gives 31 / 75, no match) or Task/Bug SP. Suspect: tickets removed/moved out of the sprint after start (invisible to `sprint = <id>`). Next: user sends Sprint Report issue lists for 26/17 to find the missing tickets.
**CONFLICT TO CLARIFY: backlog Estimate for 26/21 = 30 includes Tasks (7 SP) and hides Stories in status New (8 SP), while the earlier decision was "Stories only" (31 SP). Pending user decision which one is binding. = exactly the number from S-KPI 1, in EVERY KPI and everywhere in the report. No variants, no filtering by committed, no recalculation.** Hence ratios > 100% are possible and accepted.

### S-KPI 4: Sprint overview — Leftovers, Added after sprint start, Delivered tickets — DRAFT, awaiting verification (defined 2026-10-13)
Basis (same as Delivered/Committed): all ASNAST issue types (Story, Task, Bug) with Original Story Points > 0; Won't Do and Sub-tasks excluded; every ticket counted once; broken down by type.
- **Leftovers** = tickets assigned to the sprint at sprint end (start of next sprint) that have NOT reached `Technical Review` by then. Count by type + cumulated SP.
- **Added after sprint start** = tickets whose first assignment to the sprint happened after the sprint activation (no grace period). Count by type + cumulated SP.
- **Delivered tickets** = tickets that reached Technical Review in the sprint period (same set as Delivered SP, S-KPI 1). Count by type. Delivered SP itself is the existing single number.
- SP basis for Leftovers and Added = highest SP value ever recorded (estimate).
Demo 26/19 (end 2026-10-08 10:03; activation 2026-09-24 11:21): Leftovers 8 / 23 SP (Story 7 / 22 SP, Task 1 / 1 SP). Added 6 / 15 SP (Story 5 / 14 SP, Task 1 / 1 SP: ASNAST-15830, 15813, 15736, 15684, 15610; Task 15829). Delivered tickets 27 (Story 24, Task 3) = 113 SP.
Caveat: replay only finds tickets still carrying the sprint in their history. **Confirmed by user (2026-10-13): S-KPI 4 demo values for 26/19 are correct.**
HTML declaration (English): "Leftovers = issues (Story, Task, Bug with Original Story Points > 0; Won't Do excluded) assigned to the sprint at sprint end that did not reach Technical Review. Added = issues first assigned to the sprint after sprint start. Story points = highest estimate recorded. Delivered tickets = issues that reached Technical Review during the sprint period."

### S-KPI 5: Technical Review rate — Planned vs Added tickets — DRAFT, awaiting verification (defined 2026-10-13)
Same basis as S-KPI 4 (all types, Original SP > 0, Won't Do/Sub-tasks excluded). Planned = tickets assigned at sprint activation (the Committed set); Added = first assigned after activation. For each group: how many reached `Technical Review` in the sprint period (count by type + burned SP, Delivered rule).
Demo 26/19: Planned 18 of 22 reached TR (Story 15 of 19, Task 3 of 3; 93 SP); not reached: ASNAST-15759, 15719, 15531, 15530. Added 5 of 6 (Story 5 of 5, Task 0 of 1; 14 SP); not reached: ASNAST-15829.
Note: 18 + 5 = 23 of the 27 delivered tickets (107 of 113 SP). The other 4 tickets (6 SP) reached TR in the period but were not in the sprint at activation or added to it (delivered independent of sprint assignment).
HTML declaration (English): "Planned = issues assigned to the sprint at sprint start; Added = issues first assigned after sprint start. Shown: how many of each group reached Technical Review during the sprint period."

### PI-KPI 6: Technical Review rate — Planned vs Added tickets (PI level) — DRAFT, awaiting verification (defined 2026-10-13)
Same logic as S-KPI 5, but over the whole PI: window = PI start to PI end (not sprint borders). Basis: all ASNAST types with Original SP > 0, Won't Do and Sub-tasks excluded, every ticket once. Planned = first assigned to a PI sprint within PI start + 3 calendar days (same grace period as PI-KPI 5); Added = first assigned later. For each group: how many reached `Technical Review` between PI start and PI end (count by type + burned SP). PI report only for a finished PI.
Demo PI 2026.37 (PI NOT finished: window 2026-09-10 09:58 to 2026-10-13 14:50, sprints 26/21–26/23 still open): Planned 37 of 82 reached TR (Story 35 of 74, Task 2 of 8; 138 SP). Added 7 of 14 (Story 3 of 9, Task 4 of 5; 12 SP). Total 44 tickets / 150 SP in TR (sprint sum 24 + 113 + 14 = 151).
Findings: Jira does NOT log the initial sprint assignment at ticket creation (no Sprint changelog event). Tickets created directly into a PI sprint had to be classified via their creation date (12 tickets, e.g. ASNAST-15650 to 15655, 15817, 15808).
CORRECTION to S-KPI 3/4/5 (same cause, replay now starts with the first event's from-state): Committed SP unchanged (26/18 = 45, 26/19 = 77), but 26/19 Planned = 23 tickets (18 reached TR, was 18 of 22) and Leftovers = 9 / 26 SP (Story 8, Task 1; was 8 / 23 SP). Added unchanged (6 / 15 SP; 5 reached TR).
HTML declaration (English): "Planned = issues first assigned to a PI sprint within 3 days after PI start; Added = issues assigned later. Shown: how many of each group reached Technical Review between PI start and PI end."

### S-KPI 6: Sprint overview chart — Technical Review vs Left Over (tickets per sprint) — DRAFT, awaiting verification (defined 2026-10-13)
Layout reference: user screenshot (line chart + table "Sprint overview": one point/row per sprint of the PI; green line "Done", red line "Left Over"). Change: the green line shows tickets that reached **Technical Review** (not Done). Counts are TICKETS (not SP), basis as in S-KPI 4/5 (all types, Original SP > 0, Won't Do/Sub-tasks excluded). Done/Technical Review = Delivered tickets of S-KPI 1 (same number everywhere); Left Over = Leftovers of S-KPI 4 (same number everywhere). Running sprint: Left Over shown as "n/a" until the sprint ended.
Demo PI 2026.37: 26/18: TR 11, Left Over 9. 26/19: TR 27, Left Over 9. 26/20 (running): TR 7, Left Over n/a. 26/21 to 26/23: not started.
Open: meaning of the "PI Start" row in the screenshot (27 / 0) — to be clarified.
HTML declaration (English): "Technical Review = issues that reached Technical Review during the sprint period. Left Over = issues assigned to the sprint at sprint end that did not reach Technical Review. Number of issues (Story, Task, Bug with Original Story Points > 0; Won't Do excluded)."

## Review & draft (2026-10-13)
- **kpi-calc.ps1 = single source of numbers (REST, deterministic; two runs of PI 2026.25 gave byte-identical JSON).** Ad-hoc chat numbers are obsolete. Documented in SKILL.md.
- Finding: PI 2026.25 has **15 ASDM features** via field "Program Increment" (id 963; ASDM-37 etc.); the earlier summary search found only 3 -> wrong. PI-KPI 1 = 79,8 calendar days (11 of 15 computable; n/a: ASDM-30, ASDM-37 (Done without Implementation), ASDM-42, ASDM-63 (still Implementation)); uncertain (bulk migration start): ASDM-19, ASDM-9; carry-over (several PIs): ASDM-2, ASDM-9, ASDM-19, ASDM-40, ... ; 90-day policy exceeded by ASDM-2 (154,1), ASDM-19 (120,0), ASDM-9 (111,9), ASDM-25 (93,0).
- PI 2026.25 sprints: "PI 2026.25 - Start Finishing" (06-18, special first sprint, other name pattern) + 26/13 ... 26/17; PI end = 2026-09-10 07:58 (start of next sprint).
- PI 2026.25 results (script): KPI 2 = 4,68 SP (79); KPI 3 = 142 (Story 83, Task 32, Bug 26, Risk 1); KPI 4 = 24,7 WD (wait 18,3 / work 6,4, n=82); KPI 5 = 15 Stories (42 SP) + 22 Bugs, pulled forward 6 Stories (13 SP); KPI 6 = planned 58/71 reached TR (198/253 SP), added 30/30 (69 SP) - added now 30 (was 25 in the ad-hoc run: creation date used instead of first-event proxy).
- PI-KPI 7 (chart, moved from S-KPI 6): TR / Left Over: Start Finishing 12/1, 26/13 17/4, 26/14 15/11, 26/15 17/6, 26/16 16/3, 26/17 11/2.
- **Sprint 26/19 deterministic result vs earlier confirmed values:** Delivered 27 tickets / 113 SP (same), Added 6 / 15 SP, TR planned 18, Leftovers 9 / 26 SP (same). DIFFERENT: Planned 24 tickets (was 23) and Committed 88 SP (was 77) -> ratio 1,28, velocity 1,46. Reason: ASNAST-15795 (5 SP) was added at 11:19:54, 84 s BEFORE activation (11:21:18) and ASNAST-15819 (1 SP) earlier; the old ad-hoc replay could not be reproduced. DECISION NEEDED: cut-off = activatedDate (current) or sprint startDate (10:03)? Committed 88 vs Jira Sprint Report 100.
- Capacity mismatch 2026.25: sprint values sum to 355, Excel says 366,5 (11,5 diff); capacity is only an input for velocity and is not shown in the report.
- CI: user slide "Delivery & Flow Performance" was a reference; user asked for a different, simpler CI (layout/numbers first). Current output: light page, Porsche red, PORSCHE wordmark.
- Open: meaning of "PI Start" row in the old chart; manual verification of all KPIs; Committed snapshot pipeline.

## HTML report requirements (for later)
- KPI 2 note (visible in report): "Story size = SP burned. Every change of the field Story Points is a burn-down; re-estimates only occur in the field Original story points and are not counted."
- Report language: **English** (chat/docs with the user stay German).
- Each KPI must state its calculation basis visibly, e.g. for Feature Cycle Time:
  "Calculated from status change *Implementation* until *Done* (calendar days, average over all Done features of the PI)."
- Fixed layout, Porsche CI; only numbers/scope header are overwritten.
- Show the **90-day policy** as a red line (threshold) in the cycle-time chart; highlight features above it.
- Show average AND median, count "X of Y features", list uncertain values with reason, list leftovers.

## KPI 2: Average Story Size (PI level) — DRAFT, awaiting manual verification
**Decision (2026-10-13):** Story size = number of SP actually **burned** on the story = sum of all
reductions of `Story Points` in the changelog (3->0 = 3; 3->8->0 = 8; increases count as they are burned later).
**Only output: the AVERAGE** (no median/extras for this KPI). Basis shown in report: "Calculated as SP burned per Done story".
- Only truly done stories: status category Done includes `Wont do` -> **exclude Won't Do** (data quality: JQL statusCategory=Done is not enough).
- Stories without any burned SP (burned = 0) are excluded and listed; uncertain values are flagged with reason, user decides in chat.
- Stories in several sprints of the PI count once (leftovers flagged).
- PI of a story = sprints with that PI number in the name; JQL via sprint IDs.

Demo PI 2026.37 (sprints 236880, 236882, 236884; 29 stories with Done category):
- 5 Won't Do excluded (ASNAST-15694, 15738, 15740, 15784, 15785); 1 with burned = 0 (ASNAST-15735, SP 1 never burned).
- 23 stories counted, avg = 4.17 SP (sum 96). Without uncertain ASNAST-15575: 22 stories, avg 3.45.
- **Confirmed by user (2026-10-13):** Won't Do stories are always excluded. KPI 2 definition complete; remaining step = manual Jira verification by user.
- **Clarified by user (2026-10-13):** every change in `Story Points` is a burn; re-estimates occur ONLY in `Original story points`. So ASNAST-15575 (20->3->0 = 20) is NOT uncertain and counts. Result stands: 23 stories, avg 4.17 SP.
- Largest: ASNAST-15529 (13; 3->13 increase), ASNAST-15471 (8).

Findings that remain valid: Story Points field customfield_10006, Original story points customfield_10500, Sprint customfield_10004.
Superseded: earlier idea of using Original/peak SP and current SP (mostly 0 on Done stories).
**KEY INSIGHT (2026-10-13): Story Points are BURNED DOWN** during work, so `Story Points` (customfield_10006)
of a Done story is mostly 0 and is NOT the story size. Estimates can also be INCREASED during work.
- `Original story points` (customfield_10500) keeps the initial estimate (e.g. ASNAST-15737: SP now 0, original 3;
  changelog: Story Points 3 -> 0). Some stories have SP empty but original set (ASNAST-15788: original 2).
- Increases are only visible in the changelog of `Story Points` (from_string/to_string), not in the original field.
- Candidate definition of real size: max(Original story points, highest value ever in Story Points changelog).
- Demo data (before this insight): PI 2026.37 = 29 Done stories, of which only 3 with current SP>0 -> NOT usable;
  PI 2026.25 (sprints 232220-232225, 89 Done stories) also mostly 0.
Avg Story Points per story in the PI (ASNAST stories).
- Story Points field: `customfield_10006` ("Story Points"); there is also "Original story points" (customfield_10500) — not used for now.
- Sprint field: `customfield_10004`; a story can be in several sprints (leftovers).
- PI of a story = PI number in the sprint name `YY/NN (YYYY.NN) <name>`, e.g. `26/20 (2026.37) TrustIssues`.
  JQL cannot wildcard sprint names -> resolve sprint IDs per PI via board 114224 (`jira_get_sprints_from_board`), then `sprint in (id,...)`.
- Current PI 2026.37 has at least sprints 26/19 (id 236882, closed) and 26/20 (id 236884, active, 2026-10-08..2026-10-22).
- Data quality: Story Points can be 0.0 (e.g. ASNAST-15603) or empty.
Open decisions: which stories count (all vs. Done only), 0/empty points, stories in several sprints of the PI (count once).

## CURRENT STATE (2026-10-13, end of day) — supersedes all older sections above where they conflict
**Built and working:** `kpi-calc.ps1` (deterministic, REST, runs twice = identical numbers) generates `out/pi-<id>.html|json` and `out/sprint-<yy-nn>.html|json`. All KPIs are defined in SKILL.md (KPI catalog). Trigger: user says "sprint 26/19" or "pi 2026.25".

| Level | KPI | Status |
|-------|-----|--------|
| PI | Overview (Delivered / Left over / Added, tickets + SP + by type) | built, new, to verify |
| PI | 1 Feature cycle time (ASDM, field Program Increment) | built, to verify |
| PI | 2 Avg story size (SP burned) | built, to verify |
| PI | 3 Ticket distribution | built, to verify |
| PI | 4 Story cycle time (working days, wait/work) | built, to verify |
| PI | 5 Added after PI start (3-day grace, pulled forward) | built, to verify |
| PI | 6 Technical Review planned vs added | built, to verify |
| PI | 7 Technical Review vs Left Over per sprint (chart) | built, to verify |
| Sprint | 1 Delivered, 2 Velocity, 3 Ratio Delivered/Committed (headline), 4 Leftovers/Added (own cards), 5 TR rate planned vs added | built, to verify |

**Report layout:** SPRINT dashboard design is FINAL (user 2026-10-21: "perfect"). Template `sprint-template.html` + logo `assets/logo.jpg`, details in SKILL.md "HTML / CI". Title spelled "ASNASt KPI". First rendered with the running sprint 26/20 (Delivered 57 SP, velocity 0,79, ratio 0,97, committed 59 SP, leftovers n/a, added 2 / 3 SP, planned TR 18/29, added TR 1/2). PI report is ALSO FINAL (user 2026-10-21): template `pi-template.html`, hash-locked in `design-final\ ` (key `pitemplate`), example PI 2026.25 rendered (Delivered 88 tickets / 333 SP). Open oddity: PI-KPI 6 card shows "259 of 253 SP" (burned vs original SP).
(Older layout notes below are superseded: light page, background image, PLES KPI title.) light simple CI, Porsche red, PORSCHE wordmark; sprint S-KPI 3 shows the ratio as the big number; S-KPI 5 one card with planned/added blocks; PI report starts with the overview. Background image was tried and removed again. Design will be adjusted in the coming days; the real Porsche CI is still missing.

**Reference values (script):** Sprint 26/19: Delivered 27 / 113 SP, velocity 1,46, Committed 88 SP, ratio 1,28, planned 24 (18 in TR), added 6 / 15 SP (5 in TR), leftovers 9 / 26 SP. PI 2026.25: overview 88 delivered / 333 SP, 3 left over / 22 SP, 30 added / 73 SP; other values see "Review & draft".

## Open
- [ ] User: manual verification of all PI and sprint KPIs in Jira (user: "not everything fits yet", to be done on 2026-10-14 or later) — collect deviations and fix `kpi-calc.ps1` + SKILL.md.
- [ ] DECISION: Committed cut-off = activatedDate (11:21, 88 SP, 24 planned) or sprint startDate (10:03)? Earlier confirmed 77 SP / 23 planned; Jira Sprint Report 100.
- [ ] Meaning of the "PI Start" row (27/0) in the old chart.
- [ ] Capacity Excel: sums to 355 in `capacity.json` vs 366,5 in the Excel (user must provide the Excel; SharePoint 401 for the agent).
- [ ] Real Porsche CI / design (background image removed for now).
- [ ] Committed snapshot via git pipeline (store, never recalculate).
- [ ] Confluence target page/parent and publishing (only after explicit confirmation; `--dry-run` otherwise).
- [ ] Clean up older superseded sections of this file (S-KPI 3 history).

## Next step
1. DONE 2026-10-21: PI report in the final dashboard design, locked. Next: clarify PI-KPI 6 SP display, user verifies KPIs, Committed cut-off decision (88 vs 77).
2. User verifies the KPIs against Jira; deviations go back into `kpi-calc.ps1` and SKILL.md. Then Confluence publishing.

**DECISION (2026-10-27):** Committed = Story Points at `activatedDate` (actual sprint activation). Sprint 26/19 = 88 SP (confirmed by user; 77 via startDate and 100 from the Jira Sprint Report are NOT used). Open item 'Committed cut-off' is closed.

**DECISION (2026-10-27):** PI-KPI 6 shows SP of the Technical-Review tickets in ORIGINAL SP (same basis as the denominator). PI 2026.25: planned 58/71 tickets, 198 of 253 SP; added 30/30, 69 of 69 SP. Open: PI overview 'Delivered SP' (333) still uses burned SP - check whether it should use Original SP too.

**DECISION (2026-10-27): ALL SP = Original SP (customfield_10500, latest value).** Reason: the team now sets SP only as complexity (not effort/time) and sets Story Points to 0 on completion; 'Burned' double-counted re-estimates and toggles (e.g. ASNAST-15713, ASNAST-15652). Applies to Delivered, Velocity, TR-SP, Committed, Added, Leftover, PI overview, PI-KPI 2 and 6. Committed = ticket set at `activatedDate` x Original SP. Tooltips in both templates updated, design hashes in design-final\ renewed deliberately. New numbers: 26/19 delivered 27 / 90 SP, committed 87, ratio 1,03, velocity 1,16; 26/20 (closed) delivered 22 / 63 SP, committed 81, ratio 0,78, velocity 0,87; PI 2026.25 delivered 88 / 267 SP, PI-KPI 2 avg 3,65 SP (n=78). Note: the 'latest value' is read at report time (a later re-estimate changes old reports) - open: freeze values at period end.

**DECISION (2026-10-27):** Always the LATEST Original SP at report time; no freezing at period end. Closes the open item 'freeze values at period end'. Consequence: re-running an old report after a re-estimate can change its SP numbers (accepted).

**DECISION (2026-10-27): S-KPI 5 reconciliation line (fine print).** Delivered = first Technical Review in the sprint period (independent of sprint membership). Tickets that reached TR in the period but were neither planned at activation nor added afterwards are 'Other' (26/20: ASNAST-15700 5 SP - assigned 10.09., not in sprint at activation; ASNAST-15847 2 SP - never assigned). The S-KPI 5 card shows 'Planned + Added + Other = Delivered' in tickets and SP so everything adds up (26/20: 19+1+2 = 22 tickets, 55+1+7 = 63 SP; 26/19: 18+5+4 = 27, 72+12+6 = 90). Consistency is the top rule. sprint-template.html changed deliberately (new .recon block), design-final hashes renewed.

**DECISION (2026-10-27): tooltip disclaimers.** Leftovers (sprint + PI) and S-KPI 5 tooltips state that leftovers / planned-not-in-TR tickets are NOT automatically carried over into the next sprint/PI (26/20: 7 leftovers, only 4 are in 26/21; 3 reached TR within an hour after the cut-off). Open: leftover cut-off definition; Committed 26/20 includes 3 tickets (6 SP) already in TR before sprint start (ASNAST-15610, 15742, 15746). Hashes renewed.

**DECISION (2026-10-27): Committed excludes tickets that reached Technical Review BEFORE the sprint start** (they are dropped from the planned/committed basis entirely). 26/20: Committed 75 SP, ratio 0,84, planned TR 19/25 (ASNAST-15610, 15742, 15746 removed). 26/19: Committed 84 SP, ratio 1,07, planned 18/22. Open: same rule for PI-KPI 6 not applied. **Confluence archive (user request 2026-10-27):** page 'https://skyway.porsche.com/confluence/spaces/ASNAST/pages/2714063024/19+KPI+s' (id 2714063024): attachment 'Sprint KPI Report 26-20 - erstellt 2026-10-27.html' (id 2722112023, version 2) + body with AI notice and KPI table, label 'ai-generated'. Upload works only via REST (host api.skyway.porsche.com/confluence, Bearer CONFLUENCE_PERSONAL_TOKEN, via proxy); MCP upload cannot read local files. New version of an attachment: POST .../child/attachment/<id>/data. HTML attachments are downloaded, not rendered by Confluence.

**DECISION (2026-10-27): Confluence archive = one 2-column table (Sprint | file) only; new sprints appended; same sprint again overwrites row + attachment.** Implemented as `confluence-archive.ps1` (tested with 26/20: dry run + real overwrite run, one row, one attachment). Documented in SKILL.md.

**DECISION (2026-10-27): open-items round.** (1) Leftover cut-off stays = start of the next sprint. (2) TR-before-start exclusion MUST also apply to PI-KPI 6 (TODO: implement). (3) Capacity: Excel value 366,5 for PI 2026.25 is correct; user will deliver per-sprint values (TODO: update capacity.json). (4) Holidays: no, Mon-Fri is enough. (5) Dead code in kpi-calc.ps1 (Page/Card/CSS, Burned/SPAt/MaxSP) to be removed (TODO). (6) Copying the skill to .github\skills / SharePoint mirror: user wants to discuss LATER - ask again.

**DECISION (2026-10-27) IMPLEMENTED:** PI-KPI 6 excludes tickets with TR before PI start (PI 2026.25: planned 58/61 = 198 of 220 SP, added 30/30 = 69 SP; was 58/71, 253 SP). Dead code removed from kpi-calc.ps1 (CSS/Card/Two/Page, Burned/SPAt/MaxSP); sprint 26/20 and PI re-run, numbers unchanged otherwise. Backup: %TEMP%\kpi-calc.bak.ps1. Final rules: leftover cut-off = start of next sprint; holidays ignored (Mon-Fri); capacity PI 2026.25 = 366,5 per Excel (per-sprint values pending from user, capacity.json still 355); skill copy to .github\skills / SharePoint = discuss later.

**OPEN (2026-10-27):** Repo https://github.com/paul-wie/kpi-skill.git (private) exists. Later: make it embeddable into another repo (e.g. PASS-AI .github\skills\kpi-report) via git subtree/submodule; check SKILL.md frontmatter (name/description) and path independence ($PSScriptRoot already used). Tokens always from environment.

**DECISION (2026-10-27):** PI reports are archived on the same Confluence page in a second table (PI | File) below the sprint table. confluence-archive.ps1 now supports -Pi (dry-run tested; real archive of PI 2026.25 only after user review of out\pi-2026.25.html).

**DONE (2026-10-27):** PI 2026.25 report reviewed by user and archived on Confluence page 2714063024 (version 7, second table PI | File, attachment 'PI KPI Report 2026.25 - erstellt 2026-10-27.html'). Sprint and PI level are both final. Open: per-sprint capacity (Excel 366,5), embeddable repo, copy of the skill to .github\skills.

**DECISION (2026-11-04):** S-KPI 4 (Leftovers + Added after start) now lists the concrete tickets (key as small Jira link, title max 60 chars + '...', SP). sprint-template.html changed deliberately, design-final hashes renewed. Second improvement requested by the user is still open.
