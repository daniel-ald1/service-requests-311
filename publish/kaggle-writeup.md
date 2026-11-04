# 311 Service Requests, my Google Data Analytics capstone (Case 3)

For the final course of the certificate I did the "bring your own data"
track and picked 311 calls, close to the support work I've done. The dataset
is synthetic: I generated 1030 rows myself, broke them on purpose, cleaned
them back to 1000.

Reproduce: `py build_clean.py`, `py analysis.py`,
`sqlite3 service-requests.db < sql/analysis.sql`.

The question was simple: same crew, where is the backlog and what do we do?
Targets I set: Critical resolution 5.2 down to 4.0 days in 90 days, Noise
backlog 41 down to 28 this quarter, Water Leak satisfaction 2.78 up to 3.2
in two quarters.

Findings (n=1000 unless noted): backlog 26.1% (Closed 601, Open 132, In
Progress 129), worst in Noise Complaint (41 of 145), Streetlight (36),
Graffiti (36). Volume leaders Noise 145 (14.5%) and Streetlight 132. The one
I double-checked: priority doesn't buy speed (Low 5.8 days, High 5.3,
Critical 5.2, Medium 5.1 over 741 resolved, 5.3 overall). Steady demand, 39
to 70 a month for 18 months, peak 70 in Jan 2026. Water Leak is the quality
hole at 2.78 of 5 vs 3.08 overall, while top-volume Noise scores best at
3.33. Phone leads intake at 220 (22%), digital combined beats it.

Charts plus a Tableau dashboard mirror the same three views. Tableau was
built in Public from the clean CSV; steps in `tableau/TABLEAU-CONNECT.md`.

Limits, stated plainly: synthetic data, one snapshot, 26 Closed tickets with
no close date that I worked around instead of solving. I'd validate against
a second pull before spending on any of it.

SQL and SQLite, Python (pandas, matplotlib), Tableau Public.
