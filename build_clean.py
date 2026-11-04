"""I load raw CSV into SQLite, run sql/cleaning.sql, export the clean CSV."""
import csv
import os
import sqlite3

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "service-requests.db")
RAW = os.path.join(BASE, "data_raw", "requests_raw.csv")
SQL = os.path.join(BASE, "sql", "cleaning.sql")
OUT = os.path.join(BASE, "data_clean", "requests_clean.csv")

if os.path.exists(DB):
    os.remove(DB)
con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("""CREATE TABLE requests_raw(request_id TEXT, created_date TEXT,
closed_date TEXT, district TEXT, request_type TEXT, channel TEXT, status TEXT,
priority TEXT, response_days_raw TEXT, satisfaction TEXT)""")
with open(RAW, newline="", encoding="utf-8") as f:
    r = csv.DictReader(f)
    cur.executemany("INSERT INTO requests_raw VALUES (?,?,?,?,?,?,?,?,?,?)",
                    [[row[c] for c in r.fieldnames] for row in r])
con.commit()
with open(SQL, encoding="utf-8") as f:
    con.executescript(f.read())
con.commit()
rows = con.execute("SELECT * FROM requests_clean ORDER BY request_id").fetchall()
cols = [d[0] for d in con.execute("SELECT * FROM requests_clean LIMIT 0").description]
with open(OUT, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(cols)
    w.writerows(rows)
print(f"raw={con.execute('SELECT COUNT(*) FROM requests_raw').fetchone()[0]} "
      f"clean={len(rows)} flags={con.execute('SELECT COUNT(*) FROM requests_flags').fetchone()[0]}")
con.close()
