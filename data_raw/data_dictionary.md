# Data Dictionary: `data_raw/requests_raw.csv` (SYNTHETIC)

> Synthetic City 311-style Service Requests for Bogota. All rows are
> invented for portfolio purposes. No real employer names, no real persons,
> no Cyclistic content. Messiness below is intentional.

| # | Column | Expected type | Description | Known messiness I inject |
|---|--------|---------------|-------------|--------------------------|
| 1 | `request_id` | TEXT, key like `REQ-00001` | Synthetic ticket key | ~3% exact duplicate rows (same `request_id`); I dedupe keeping first |
| 2 | `created_date` | TEXT (mixed) | Date the request was opened | Mixed formats: `YYYY-MM-DD`, `DD/MM/YYYY`, `MM-DD-YYYY`; 2 impossible dates (`2025-02-30`, `2025-13-01`) |
| 3 | `closed_date` | TEXT (mixed) or empty | Date the request was closed | Same mixed formats; 1 impossible date (`30/02/2025`); empty for open/in-progress tickets; a few closed tickets missing it |
| 4 | `district` | TEXT | Bogota locality (geography only, not employer) | Inconsistent casing/whitespace (`"  Streetlight "`-style padding, UPPER/lower); ~2% nulls → I map to `Unknown` |
| 5 | `request_type` | TEXT | Service category (Streetlight, Pothole, …) | Same casing/whitespace noise, e.g. `"  Streetlight "`, `"STREETLIGHT"`; ~1.5% nulls → `Unknown` |
| 6 | `channel` | TEXT | Intake channel (Phone, Web, …) | Same casing/whitespace noise; ~1.5% nulls → `Unknown` |
| 7 | `status` | TEXT | `Closed / Open / In Progress / Cancelled` | Casing noise + 1 stale value `Awaiting_legacy_sys` → I map to `Other` |
| 8 | `priority` | TEXT | `Low / Medium / High / Critical` | Casing noise; ~1% nulls → I default to `Medium` |
| 9 | `response_days_raw` | TEXT/int or empty | Reported days to resolve | 2 negative values (`-5`, `-2`) → I set NULL + flag; ~3% nulls kept as NULL |
| 10 | `satisfaction` | TEXT/int 1–5 or empty | Post-close survey score | Empty mostly for open tickets; some closed tickets missing → kept NULL |

Cleaning rules (mirrored in `sql/cleaning.sql`):
I trim + lowercase all text keys, map to canonical labels, strictly parse
dates (impossible → NULL + flag), cast numerics (negatives → NULL + flag),
dedupe on `request_id`, and log every issue into `requests_flags`.
