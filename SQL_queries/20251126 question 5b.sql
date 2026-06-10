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
),
-- LAGGED PRICES AND WAGES +1 YEAR
lagged AS (
    SELECT
        g.record_year,
        g.gdp_pct_change,
        w.wage_pct_change,
        p.price_pct_change,
        LEAD(w.wage_pct_change) OVER (
            ORDER BY
                g.record_year
        ) AS wage_pct_change_next_year,
        LEAD(p.price_pct_change) OVER (
            ORDER BY
                g.record_year
        ) AS price_pct_change_next_year
    FROM
        gdp_change g
        LEFT JOIN wage_change_per_year w USING(record_year)
        LEFT JOIN price_change_per_year p USING(record_year)
    WHERE
        g.country = 'Czech Republic'
) 
--MAIN QUERY
-- 1) WAGES
SELECT
    'wages' AS metric,
    ROUND(
        regr_slope(
            wage_pct_change :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS slope,
    ROUND(
        regr_intercept(
            wage_pct_change :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS intercept,
    ROUND(
        regr_r2(wage_pct_change, gdp_pct_change) :: numeric,
        2
    ) AS r2,
    ROUND(
        corr(wage_pct_change, gdp_pct_change) :: numeric,
        2
    ) AS correlation
FROM
    lagged
WHERE
    wage_pct_change IS NOT NULL
    AND gdp_pct_change IS NOT NULL
UNION
ALL -- 2) WAGES NEXT YEAR
SELECT
    'wages_next_year' AS metric,
    ROUND(
        regr_slope(
            wage_pct_change_next_year :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS slope,
    ROUND(
        regr_intercept(
            wage_pct_change_next_year :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS intercept,
    ROUND(
        regr_r2(wage_pct_change_next_year, gdp_pct_change) :: numeric,
        2
    ) AS r2,
    ROUND(
        corr(wage_pct_change_next_year, gdp_pct_change) :: numeric,
        2
    ) AS correlation
FROM
    lagged
WHERE
    wage_pct_change_next_year IS NOT NULL
    AND gdp_pct_change IS NOT NULL
UNION
ALL -- 3) PRICES 
SELECT
    'prices' AS metric,
    ROUND(
        regr_slope(
            price_pct_change :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS slope,
    ROUND(
        regr_intercept(price_pct_change, gdp_pct_change) :: numeric,
        2
    ) AS intercept,
    ROUND(
        regr_r2(price_pct_change, gdp_pct_change) :: numeric,
        2
    ) AS r2,
    ROUND(
        corr(price_pct_change, gdp_pct_change) :: numeric,
        2
    ) AS correlation
FROM
    lagged
WHERE
    price_pct_change IS NOT NULL
    AND gdp_pct_change IS NOT NULL
UNION
ALL -- 4) PRICES NEXT YEAR
SELECT
    'prices_next_year' AS metric,
    ROUND(
        regr_slope(
            price_pct_change_next_year :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS slope,
    ROUND(
        regr_intercept(
            price_pct_change_next_year :: numeric,
            gdp_pct_change :: numeric
        ) :: numeric,
        2
    ) AS intercept,
    ROUND(
        regr_r2(price_pct_change_next_year, gdp_pct_change) :: numeric,
        2
    ) AS r2,
    ROUND(
        corr(price_pct_change_next_year, gdp_pct_change) :: numeric,
        2
    ) AS correlation
FROM
    lagged
WHERE
    price_pct_change_next_year IS NOT NULL
    AND gdp_pct_change IS NOT NULL;
