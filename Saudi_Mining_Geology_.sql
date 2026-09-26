/* ============================================================
   MINING GEOLOGY DATA ANALYSIS
   MySQL Project
   ============================================================ */

USE mining_geology_project;


/* ============================================================
   1. DRILLHOLES DATA VALIDATION
   ============================================================ */

-- Check total drillhole records and unique Collar IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Collar_Record_ID) AS unique_collar_records
FROM drillholes;

-- Drillhole depth statistics
SELECT
    MIN(Total_Depth_m) AS min_depth,
    MAX(Total_Depth_m) AS max_depth,
    ROUND(AVG(Total_Depth_m), 2) AS avg_depth
FROM drillholes;


/* ============================================================
   2. INTERCEPTS DATA VALIDATION
   ============================================================ */

-- Check total intercept records and unique Intercept IDs
SELECT
    COUNT(*) AS total_intercepts,
    COUNT(DISTINCT Intercept_ID) AS unique_intercepts
FROM intercepts;


/* ============================================================
   3. RELATIONSHIP VALIDATION
   ============================================================ */

-- Check whether every intercept has a matching drillhole
SELECT
    COUNT(*) AS total_intercepts,
    COUNT(d.Collar_Record_ID) AS matched_intercepts
FROM intercepts i
LEFT JOIN drillholes d
    ON i.Collar_Record_ID = d.Collar_Record_ID;


/* ============================================================
   4. TOP GOLD INTERCEPTS
   ============================================================ */

-- Highest-grade gold intercepts with drillhole coordinates
SELECT
    i.Intercept_ID,
    i.Hole_ID,
    i.From_m,
    i.To_m,
    i.Interval_m_Reported,
    i.Au_g_t,
    d.Easting_m,
    d.Northing_m,
    d.Total_Depth_m
FROM intercepts i
INNER JOIN drillholes d
    ON i.Collar_Record_ID = d.Collar_Record_ID
ORDER BY i.Au_g_t DESC
LIMIT 10;


/* ============================================================
   5. GOLD ANALYSIS BY HOLE
   ============================================================ */

SELECT
    Hole_ID,
    COUNT(*) AS intercept_count,
    ROUND(AVG(Au_g_t), 2) AS avg_gold_grade,
    MAX(Au_g_t) AS max_gold_grade,
    ROUND(SUM(Interval_m_Reported), 2) AS total_intercept_m
FROM intercepts
GROUP BY Hole_ID
ORDER BY max_gold_grade DESC
LIMIT 10;


/* ============================================================
   6. SPATIAL + GEOLOGICAL SUMMARY
   ============================================================ */

SELECT
    i.Hole_ID,
    d.Easting_m,
    d.Northing_m,
    d.Total_Depth_m,
    COUNT(*) AS intercept_count,
    ROUND(AVG(i.Au_g_t), 2) AS avg_gold_grade,
    MAX(i.Au_g_t) AS max_gold_grade,
    ROUND(SUM(i.Interval_m_Reported), 2) AS total_intercept_m
FROM intercepts i
INNER JOIN drillholes d
    ON i.Collar_Record_ID = d.Collar_Record_ID
GROUP BY
    i.Hole_ID,
    d.Easting_m,
    d.Northing_m,
    d.Total_Depth_m
ORDER BY max_gold_grade DESC
LIMIT 10;


/* ============================================================
   7. INTERVAL DATA QUALITY CHECK
   ============================================================ */

-- Compare reported interval with To_m - From_m
SELECT
    Intercept_ID,
    Hole_ID,
    From_m,
    To_m,
    Interval_m_Reported,
    ROUND(To_m - From_m, 2) AS calculated_interval,
    ROUND(
        Interval_m_Reported - (To_m - From_m),
        2
    ) AS interval_diff,
    CASE
        WHEN ABS(
            Interval_m_Reported - (To_m - From_m)
        ) <= 0.01
            THEN 'Match'
        ELSE 'Review'
    END AS quality_status
FROM intercepts;


/* ============================================================
   8. DATA QUALITY SUMMARY
   ============================================================ */

SELECT
    CASE
        WHEN ABS(
            Interval_m_Reported - (To_m - From_m)
        ) <= 0.01
            THEN 'Match'
        ELSE 'Review'
    END AS quality_status,
    COUNT(*) AS record_count
FROM intercepts
GROUP BY quality_status;


/* ============================================================
   9. RECORDS REQUIRING REVIEW
   ============================================================ */

SELECT
    Intercept_ID,
    Hole_ID,
    From_m,
    To_m,
    Interval_m_Reported,
    ROUND(To_m - From_m, 2) AS calculated_interval,
    ROUND(
        Interval_m_Reported - (To_m - From_m),
        2
    ) AS interval_diff
FROM intercepts
WHERE ABS(
    Interval_m_Reported - (To_m - From_m)
) > 0.01
ORDER BY ABS(
    Interval_m_Reported - (To_m - From_m)
) DESC;


/* ============================================================
   10. ANALYTICAL VIEW FOR POWER BI / GIS
   ============================================================ */

CREATE OR REPLACE VIEW vw_gold_intercepts AS
SELECT
    i.Intercept_ID,
    i.Collar_Record_ID,
    i.Hole_ID,
    i.Project_ID,
    i.From_m,
    i.To_m,
    i.Interval_m_Reported,
    i.Au_g_t,
    d.Hole_Type,
    d.Easting_m,
    d.Northing_m,
    d.RL_m,
    d.Total_Depth_m,
    d.Dip_deg,
    d.Azimuth_deg,
    d.Result_Status,

    ROUND(
        i.To_m - i.From_m,
        2
    ) AS Calculated_Interval_m,

    ROUND(
        i.Interval_m_Reported - (i.To_m - i.From_m),
        2
    ) AS Interval_Diff,

    CASE
        WHEN ABS(
            i.Interval_m_Reported - (i.To_m - i.From_m)
        ) <= 0.01
            THEN 'Match'
        ELSE 'Review'
    END AS Quality_Status

FROM intercepts i
INNER JOIN drillholes d
    ON i.Collar_Record_ID = d.Collar_Record_ID;


/* ============================================================
   11. FINAL VIEW VALIDATION
   ============================================================ */

-- Expected result: 642 rows
SELECT
    COUNT(*) AS total_rows
FROM vw_gold_intercepts;

-- Preview analytical dataset
SELECT *
FROM vw_gold_intercepts
LIMIT 10;