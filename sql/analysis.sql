-- analysis.sql — KPIs over requests_clean (SQLite-compatible).
-- I run these after sql/cleaning.sql; all numbers come from the data.

-- Q1: volume by request type.
SELECT request_type, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM requests_clean), 1) AS pct
FROM requests_clean GROUP BY 1 ORDER BY n DESC;

-- Q2: volume by district (top 10).
SELECT district, COUNT(*) AS n FROM requests_clean
GROUP BY 1 ORDER BY n DESC LIMIT 10;

-- Q3: volume by channel.
SELECT channel, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM requests_clean), 1) AS pct
FROM requests_clean GROUP BY 1 ORDER BY n DESC;

-- Q4: avg resolution days by priority (closed tickets with dates only).
SELECT priority, COUNT(*) AS n,
       ROUND(AVG(resolution_days), 1) AS avg_days,
       ROUND(AVG(response_days), 1) AS avg_reported_days
FROM requests_clean
WHERE resolution_days IS NOT NULL AND resolution_days >= 0
GROUP BY 1 ORDER BY avg_days DESC;

-- Q5: backlog — open rate and counts by status.
SELECT status, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM requests_clean), 1) AS pct
FROM requests_clean GROUP BY 1 ORDER BY n DESC;

-- Q6: satisfaction by request type (responded tickets only).
SELECT request_type, COUNT(satisfaction) AS responses,
       ROUND(AVG(satisfaction), 2) AS avg_satisfaction
FROM requests_clean GROUP BY 1 ORDER BY avg_satisfaction DESC;

-- Q7: monthly trend of created volume.
SELECT created_month, COUNT(*) AS n FROM requests_clean
WHERE created_month IS NOT NULL GROUP BY 1 ORDER BY 1;
