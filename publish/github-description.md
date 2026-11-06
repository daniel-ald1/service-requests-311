SHORT DESCRIPTION (GitHub About):
My Google Data Analytics capstone on 1000 synthetic 311 tickets (SQL, Python, Tableau): 26.1% backlog, Noise leads at 145, priority doesn't buy speed, Water Leak trails at 2.78 of 5.

TOPICS:
data-analytics, sql, python, tableau

ABOUT SECTION:
# 311 Service Requests, capstone (Case 3, own path)

Final course of the Google Data Analytics certificate, "bring your own data"
track. I picked 311-style tickets, close to support work I've done: 1030
synthetic rows in, 1000 clean out. Generated and broke the data myself, so
nothing here belongs to any employer.

26.1% backlog concentrated where volume is highest (Noise 145, worst backlog
at 41), priority not buying speed (Low 5.8 days vs Critical 5.2), Water Leak
as the satisfaction problem (2.78 vs 3.08 overall). Three recommendations
with targets, every number from a query.

Reproduce:
py build_clean.py
py analysis.py
sqlite3 service-requests.db < sql/analysis.sql

Charts in charts/. Tableau: https://public.tableau.com/app/profile/daniel.aldana3931/viz/311ServiceRequests-Capstone/311ServiceRequests-Capstone
