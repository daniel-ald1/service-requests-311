-- cleaning.sql (SQLite-compatible)
-- I build requests_clean + requests_flags from requests_raw.
-- Assumes requests_raw(request_id, created_date, closed_date, district,
--   request_type, channel, status, priority, response_days_raw, satisfaction)
-- exists as TEXT columns (loaded from data_raw/requests_raw.csv).
-- Run: sqlite3 service-requests.db < sql/cleaning.sql  (or via python sqlite3)

DROP TABLE IF EXISTS requests_clean;
DROP TABLE IF EXISTS requests_flags;

-- I normalize, parse dates strictly, dedupe, and apply null rules.
CREATE TABLE requests_clean AS
WITH base AS (
    SELECT
        rowid AS rid,
        TRIM(request_id) AS request_id,
        TRIM(created_date) AS created_raw,
        TRIM(closed_date) AS closed_raw,
        LOWER(TRIM(district)) AS district_key,
        LOWER(TRIM(request_type)) AS type_key,
        LOWER(TRIM(channel)) AS channel_key,
        LOWER(TRIM(status)) AS status_key,
        LOWER(TRIM(priority)) AS priority_key,
        TRIM(response_days_raw) AS resp_raw,
        TRIM(satisfaction) AS satis_raw
    FROM requests_raw
    WHERE TRIM(request_id) IS NOT NULL AND TRIM(request_id) <> ''
),
dedup AS (
    -- I keep the first occurrence of each request_id.
    SELECT *, ROW_NUMBER() OVER (PARTITION BY request_id ORDER BY rid) AS rn
    FROM base
),
parsed AS (
    SELECT
        request_id, created_raw, closed_raw, district_key, type_key,
        channel_key, status_key, priority_key, resp_raw, satis_raw, rn,
        -- I parse YYYY-MM-DD strictly (reject overflow like 2025-02-30,
        -- which SQLite date() would silently roll into March).
        CASE
            WHEN created_raw GLOB '????-??-??'
                 AND substr(created_raw, 5, 1) = '-' AND substr(created_raw, 8, 1) = '-'
                 AND date(created_raw) IS NOT NULL
                 AND date(created_raw) = created_raw
            THEN created_raw
            -- I parse DD/MM/YYYY -> ISO.
            WHEN created_raw GLOB '??/??/????'
                 AND substr(created_raw, 3, 1) = '/' AND substr(created_raw, 6, 1) = '/'
                 AND date(substr(created_raw, 7, 4) || '-' || substr(created_raw, 4, 2) || '-' || substr(created_raw, 1, 2)) IS NOT NULL
                 AND date(substr(created_raw, 7, 4) || '-' || substr(created_raw, 4, 2) || '-' || substr(created_raw, 1, 2))
                     = (substr(created_raw, 7, 4) || '-' || substr(created_raw, 4, 2) || '-' || substr(created_raw, 1, 2))
            THEN (substr(created_raw, 7, 4) || '-' || substr(created_raw, 4, 2) || '-' || substr(created_raw, 1, 2))
            -- I parse MM-DD-YYYY -> ISO.
            WHEN created_raw GLOB '??-??-????'
                 AND substr(created_raw, 3, 1) = '-' AND substr(created_raw, 6, 1) = '-'
                 AND date(substr(created_raw, 7, 4) || '-' || substr(created_raw, 1, 2) || '-' || substr(created_raw, 4, 2)) IS NOT NULL
                 AND date(substr(created_raw, 7, 4) || '-' || substr(created_raw, 1, 2) || '-' || substr(created_raw, 4, 2))
                     = (substr(created_raw, 7, 4) || '-' || substr(created_raw, 1, 2) || '-' || substr(created_raw, 4, 2))
            THEN (substr(created_raw, 7, 4) || '-' || substr(created_raw, 1, 2) || '-' || substr(created_raw, 4, 2))
            WHEN created_raw IS NULL OR created_raw = '' THEN NULL
            ELSE NULL
        END AS created_iso,
        CASE
            WHEN closed_raw GLOB '????-??-??'
                 AND substr(closed_raw, 5, 1) = '-' AND substr(closed_raw, 8, 1) = '-'
                 AND date(closed_raw) IS NOT NULL
                 AND date(closed_raw) = closed_raw
            THEN closed_raw
            WHEN closed_raw GLOB '??/??/????'
                 AND substr(closed_raw, 3, 1) = '/' AND substr(closed_raw, 6, 1) = '/'
                 AND date(substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 4, 2) || '-' || substr(closed_raw, 1, 2)) IS NOT NULL
                 AND date(substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 4, 2) || '-' || substr(closed_raw, 1, 2))
                     = (substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 4, 2) || '-' || substr(closed_raw, 1, 2))
            THEN (substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 4, 2) || '-' || substr(closed_raw, 1, 2))
            WHEN closed_raw GLOB '??-??-????'
                 AND substr(closed_raw, 3, 1) = '-' AND substr(closed_raw, 6, 1) = '-'
                 AND date(substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 1, 2) || '-' || substr(closed_raw, 4, 2)) IS NOT NULL
                 AND date(substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 1, 2) || '-' || substr(closed_raw, 4, 2))
                     = (substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 1, 2) || '-' || substr(closed_raw, 4, 2))
            THEN (substr(closed_raw, 7, 4) || '-' || substr(closed_raw, 1, 2) || '-' || substr(closed_raw, 4, 2))
            WHEN closed_raw IS NULL OR closed_raw = '' THEN NULL
            ELSE NULL
        END AS closed_iso
    FROM dedup
    WHERE rn = 1
)
SELECT
    request_id,
    created_iso AS created_date,
    closed_iso AS closed_date,
    CASE district_key
        WHEN 'usaquen' THEN 'Usaquen' WHEN 'chapinero' THEN 'Chapinero'
        WHEN 'santa fe' THEN 'Santa Fe' WHEN 'san cristobal' THEN 'San Cristobal'
        WHEN 'usme' THEN 'Usme' WHEN 'tunjuelito' THEN 'Tunjuelito'
        WHEN 'bosa' THEN 'Bosa' WHEN 'kennedy' THEN 'Kennedy'
        WHEN 'fontibon' THEN 'Fontibon' WHEN 'engativa' THEN 'Engativa'
        WHEN 'suba' THEN 'Suba' WHEN 'barrios unidos' THEN 'Barrios Unidos'
        WHEN 'teusaquillo' THEN 'Teusaquillo' WHEN 'martires' THEN 'Martires'
        WHEN 'antonio narino' THEN 'Antonio Narino'
        WHEN 'puente aranda' THEN 'Puente Aranda'
        WHEN 'candelaria' THEN 'Candelaria'
        WHEN 'rafael uribe' THEN 'Rafael Uribe'
        WHEN 'ciudad bolivar' THEN 'Ciudad Bolivar'
        WHEN 'sumapaz' THEN 'Sumapaz'
        ELSE 'Unknown'
    END AS district,
    CASE type_key
        WHEN 'streetlight' THEN 'Streetlight' WHEN 'pothole' THEN 'Pothole'
        WHEN 'waste collection' THEN 'Waste Collection'
        WHEN 'water leak' THEN 'Water Leak' WHEN 'graffiti' THEN 'Graffiti'
        WHEN 'park maintenance' THEN 'Park Maintenance'
        WHEN 'noise complaint' THEN 'Noise Complaint'
        WHEN 'sidewalk repair' THEN 'Sidewalk Repair'
        ELSE 'Unknown'
    END AS request_type,
    CASE channel_key
        WHEN 'phone' THEN 'Phone' WHEN 'web' THEN 'Web'
        WHEN 'mobile app' THEN 'Mobile App' WHEN 'in person' THEN 'In Person'
        WHEN 'social media' THEN 'Social Media'
        ELSE 'Unknown'
    END AS channel,
    CASE status_key
        WHEN 'closed' THEN 'Closed' WHEN 'open' THEN 'Open'
        WHEN 'in progress' THEN 'In Progress' WHEN 'cancelled' THEN 'Cancelled'
        ELSE 'Other'
    END AS status,
    CASE priority_key
        WHEN 'low' THEN 'Low' WHEN 'medium' THEN 'Medium'
        WHEN 'high' THEN 'High' WHEN 'critical' THEN 'Critical'
        ELSE 'Medium'
    END AS priority,
    -- I null out negative response values; flags capture them below.
    CASE WHEN resp_raw IS NULL OR resp_raw = '' THEN NULL
         WHEN CAST(resp_raw AS INTEGER) < 0 THEN NULL
         ELSE CAST(resp_raw AS INTEGER) END AS response_days,
    CASE WHEN satis_raw IS NULL OR satis_raw = '' THEN NULL
         WHEN CAST(satis_raw AS INTEGER) BETWEEN 1 AND 5
         THEN CAST(satis_raw AS INTEGER) ELSE NULL END AS satisfaction,
    -- I derive resolution days from ISO dates (NULL when either is missing).
    CASE WHEN created_iso IS NOT NULL AND closed_iso IS NOT NULL
         THEN CAST(julianday(closed_iso) - julianday(created_iso) AS INTEGER)
         ELSE NULL END AS resolution_days,
    substr(created_iso, 1, 7) AS created_month
FROM parsed;

-- I log one row per issue so the audit trail survives the clean table.
CREATE TABLE requests_flags AS
SELECT request_id, 'DUPLICATE' AS issue FROM (
    SELECT TRIM(request_id) AS request_id, COUNT(*) c FROM requests_raw GROUP BY 1
) WHERE c > 1
UNION ALL
SELECT TRIM(request_id), 'INVALID_CREATED_DATE' FROM requests_raw
WHERE TRIM(created_date) NOT GLOB '????-??-??'
  AND TRIM(created_date) NOT GLOB '??/??/????'
  AND TRIM(created_date) NOT GLOB '??-??-????'
  AND TRIM(created_date) <> '' AND created_date IS NOT NULL
UNION ALL
SELECT request_id, 'INVALID_CREATED_DATE' FROM requests_clean WHERE created_date IS NULL
UNION ALL
SELECT request_id, 'INVALID_CLOSED_DATE' FROM requests_clean
WHERE closed_date IS NULL AND status = 'Closed'
UNION ALL
SELECT TRIM(request_id), 'NEGATIVE_RESPONSE_DAYS' FROM requests_raw
WHERE CAST(TRIM(response_days_raw) AS INTEGER) < 0
UNION ALL
SELECT TRIM(request_id), 'STALE_STATUS' FROM requests_raw
WHERE LOWER(TRIM(status)) NOT IN ('closed', 'open', 'in progress', 'cancelled')
UNION ALL
SELECT TRIM(request_id), 'MISSING_DISTRICT' FROM requests_raw
WHERE TRIM(district) IS NULL OR TRIM(district) = ''
UNION ALL
SELECT TRIM(request_id), 'MISSING_REQUEST_TYPE' FROM requests_raw
WHERE TRIM(request_type) IS NULL OR TRIM(request_type) = ''
UNION ALL
SELECT TRIM(request_id), 'MISSING_CHANNEL' FROM requests_raw
WHERE TRIM(channel) IS NULL OR TRIM(channel) = '';
