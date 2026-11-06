# Building the 311 dashboard in Tableau Public

> Synthetic portfolio data only. No employer data, no real persons.

I keep the Tableau build reproducible from the clean CSV instead of
shipping a binary `.twb`: Tableau Public connects straight to the CSV
(the two `.broken.twb` files in this folder are just diffs from an early
hand-written export attempt that Tableau's parser rejected; never
published).

I use Tableau Public (current release; I last wrote these steps against
the 2026 line).

## Connecting the data (2 minutes)

1. Open Tableau Public and click **Connect > To a File > Text file**.
2. Pick this exact file:

   `D:\Games\HDvWorkspace\Projects\WIP\service-requests-311\data_clean\requests_clean.csv`

3. Check Text File Properties: UTF-8 encoding, comma delimiter,
   header row yes, 1000 data rows, 12 columns:

   `request_id, created_date, closed_date, district, request_type,
   channel, status, priority, response_days, satisfaction,
   resolution_days, created_month`

4. Set field roles once: `created_date` and `closed_date` to Date,
   `response_days`, `satisfaction`, `resolution_days` to Number
   (whole). Open rows legitimately have blank `closed_date`,
   `satisfaction`, and `resolution_days`. I do not filter them out.

## Three sheets (10 minutes)

1. **Monthly trend.** Columns: `created_month` (continuous month).
   Rows: `CNT(request_id)`. Line chart. Title: "Service requests,
   monthly volume". It should show a band of 39 to 70 a month, peak 2026-01 (70).
2. **Top request types.** Columns: `CNT(request_id)`. Rows:
   `request_type`, sorted descending. Bar chart. Noise
   Complaint (145) should sit on top, then Streetlight (132).
3. **Avg resolution by priority.** Columns: `priority`. Rows:
   `AVG(resolution_days)`. Bar chart. Expect a near-flat 5.1 to 5.8
   days (Low slowest at 5.8). I add data labels so the inversion reads
   at a glance.

## Assembling and publishing the dashboard (5 minutes)

1. Add a Dashboard, fixed size 1600 × 900, light background.
2. Add 3 KPI tiles across the top: Total requests **1000**,
   Backlog **26.1%** (Open 132 + In Progress 129), Top type **Noise
   Complaint 145 (14.5%)**.
3. Place the 3 sheets below the tiles and mirror my chart tokens:
   blue trend/bars, priority colors Low `#94A3B8`, Medium `#38BDF8`,
   High `#F59E0B`, Critical `#DC2626` (see `design/ui/UI-DESIGN.md`).
4. Click **File > Save to Tableau Public**, paste the public link
   into `README.md`, and save a local copy in this folder as
   `tableau/my_dashboard.twb`.

## Verifying before calling it done

- Check the dashboard totals against the CSV: 1000 rows, 601 Closed,
  261 backlog. If any tile disagrees, re-check the filters first.
  Never edit the CSV to match a tile.
