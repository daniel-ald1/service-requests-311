"""I generate the synthetic raw 311-style dataset (CLEARLY synthetic, Bogota-inspired)."""
import csv
import random
from datetime import date, timedelta

random.seed(311)

BASE = "D:/Games/HDvWorkspace/Projects/WIP/service-requests-311/data_raw/requests_raw.csv"

DISTRICTS = ["Usaquen", "Chapinero", "Santa Fe", "San Cristobal", "Usme",
             "Tunjuelito", "Bosa", "Kennedy", "Fontibon", "Engativa",
             "Suba", "Barrios Unidos", "Teusaquillo", "Martires",
             "Antonio Narino", "Puente Aranda", "Candelaria",
             "Rafael Uribe", "Ciudad Bolivar", "Sumapaz"]
TYPES = ["Streetlight", "Pothole", "Waste Collection", "Water Leak",
         "Graffiti", "Park Maintenance", "Noise Complaint", "Sidewalk Repair"]
CHANNELS = ["Phone", "Web", "Mobile App", "In Person", "Social Media"]
STATUSES = ["Closed", "Closed", "Closed", "Closed", "Closed",
            "Open", "In Progress", "Cancelled"]
PRIORITIES = ["Low", "Medium", "Medium", "High", "Critical"]


def messy_case(s, r):
    # I scatter inconsistent casing/whitespace on purpose.
    roll = r.random()
    if roll < 0.12:
        return "  " + s + " "
    if roll < 0.24:
        return s.upper()
    if roll < 0.32:
        return s.lower()
    return s


def fmt_date(d, r):
    # I mix three date formats intentionally.
    roll = r.random()
    if roll < 0.5:
        return d.strftime("%Y-%m-%d")
    if roll < 0.8:
        return d.strftime("%d/%m/%Y")
    return d.strftime("%m-%d-%Y")


def rand_created(r):
    start = date(2025, 1, 1)
    return start + timedelta(days=r.randint(0, 545))


rows = []
N_BASE = 1000
for i in range(1, N_BASE + 1):
    r = random.Random(311 * 1000 + i)
    rid = f"REQ-{i:05d}"
    created = rand_created(r)
    status = r.choice(STATUSES)
    priority = r.choice(PRIORITIES)
    dtype = r.choice(TYPES)
    district = r.choice(DISTRICTS)
    channel = r.choice(CHANNELS)
    resp = int(r.expovariate(1 / 6.0))
    resp = min(resp, 45)
    if status in ("Open", "In Progress"):
        closed = ""
        if status == "In Progress" and r.random() < 0.3:
            closed = fmt_date(created + timedelta(days=resp), r)
    else:
        closed = fmt_date(created + timedelta(days=resp), r) if r.random() > 0.04 else ""
    satis = "" if status in ("Open", "In Progress") and r.random() < 0.8 else str(r.randint(1, 5))
    if status == "Closed" and r.random() < 0.08:
        satis = ""
    row = {
        "request_id": rid,
        "created_date": fmt_date(created, r),
        "closed_date": closed,
        "district": messy_case(district, r),
        "request_type": messy_case(dtype, r),
        "channel": messy_case(channel, r),
        "status": messy_case(status, r),
        "priority": messy_case(priority, r),
        "response_days_raw": str(resp) if r.random() > 0.03 else "",
        "satisfaction": satis,
    }
    # I inject scattered nulls into descriptive keys.
    if r.random() < 0.02:
        row["district"] = ""
    if r.random() < 0.015:
        row["request_type"] = ""
    if r.random() < 0.015:
        row["channel"] = ""
    if r.random() < 0.01:
        row["priority"] = ""
    rows.append(row)

# I add exact-ish duplicates (~3%).
dupes = random.sample(rows, 30)
for d in dupes:
    c = dict(d)
    # I keep the same request_id so dedupe has a clear key.
    rows.append(c)

# I force the required edge cases (deterministic positions).
rows[5]["created_date"] = "2025-02-30"      # impossible date 1
rows[17]["created_date"] = "2025-13-01"     # impossible date 2
rows[42]["closed_date"] = "30/02/2025"      # impossible date 3
rows[8]["response_days_raw"] = "-5"         # negative 1
rows[66]["response_days_raw"] = "-2"        # negative 2
rows[11]["status"] = "Awaiting_legacy_sys"  # stale status (not in valid set)
rows[3]["request_type"] = "  Streetlight "
rows[9]["request_type"] = "STREETLIGHT"

random.Random(99).shuffle(rows)

with open(BASE, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["request_id", "created_date", "closed_date",
                                      "district", "request_type", "channel",
                                      "status", "priority", "response_days_raw",
                                      "satisfaction"])
    w.writeheader()
    w.writerows(rows)
print(f"wrote {len(rows)} rows -> {BASE}")
