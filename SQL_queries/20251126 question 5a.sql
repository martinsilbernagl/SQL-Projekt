--GDP CHANGE CALCULATION PREP
WITH gdp_year AS (
    SELECT
        country,
        record_year,
        gdp
    FROM
        data_academy_content.t_martin_silbernagl_project_sql_secondary_final AS s
),
gdp_change AS (
    SELECT
        curr.country,
        curr.record_year,
        ROUND(
            (
                (curr.gdp - prev.gdp) / NULLIF(prev.gdp, 0) * 100
            ) :: NUMERIC,
            1
        ) AS gdp_pct_change
    FROM
        gdp_year AS curr
        LEFT JOIN gdp_year AS prev ON curr.country = prev.country
        AND curr.record_year = prev.record_year + 1
),
--WAGE CHANGE CALCULATION PREP
wage_avg_year AS (
    SELECT
        record_year,
        avg(payroll_value) AS wage_avg_per_year
    FROM
        data_academy_content.t_martin_silbernagl_project_sql_primary_final
    WHERE
        industry_branch IS NULL --for Czechia
    GROUP BY
        record_year
),
wage_change_per_year AS (
    SELECT
        curr.record_year,
        round(
            (
                (curr.wage_avg_per_year - prev.wage_avg_per_year) / NULLIF(prev.wage_avg_per_year, 0) * 100
            ) :: NUMERIC,
            1
        ) AS wage_pct_change
    FROM
        wage_avg_year AS curr
        LEFT JOIN wage_avg_year AS prev ON curr.record_year = prev.record_year + 1
),
--PRICE CHANGE CALCULATION PREP
price_avg_year AS (
    SELECT
        record_year,
        category,
        avg(price_value) AS avg_price_per_year
    FROM
        data_academy_content.t_martin_silbernagl_project_sql_primary_final
    GROUP BY
        record_year,
        category
),
price_change_per_year AS (
    SELECT
        curr.record_year,
        ROUND(
            AVG(
                (
                    curr.avg_price_per_year - prev.avg_price_per_year
                ) / NULLIF(prev.avg_price_per_year, 0) * 100
            ) :: NUMERIC,
            1
        ) AS price_pct_change
    FROM
        price_avg_year AS curr
        LEFT JOIN price_avg_year AS prev ON curr.category = prev.category
        AND curr.record_year = prev.record_year + 1
    GROUP BY
        curr.record_year
) 
-- MAIN QUERY
SELECT
    s.record_year,
    g.gdp_pct_change,
    w.wage_pct_change,
    p.price_pct_change
FROM
    data_academy_content.t_martin_silbernagl_project_sql_secondary_final AS s
    LEFT JOIN gdp_change AS g -- adds gdp
    ON s.country = g.country
    AND s.record_year = g.record_year
    LEFT JOIN wage_change_per_year AS w --adds wages
    ON s.record_year = w.record_year
    LEFT JOIN price_change_per_year AS p -- adds prices
    ON s.record_year = p.record_year
WHERE
    s.country = 'Czech Republic'
    AND g.gdp_pct_change IS NOT NULL
ORDER BY
    s.record_year;
