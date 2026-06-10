--WAGE CHANGE CALCULATION PREP
WITH wage_avg_year AS (
  SELECT
    record_year,
    avg(payroll_value) AS wage_avg_per_year
  FROM
    data_academy_content.t_martin_silbernagl_project_sql_primary_final
  WHERE
    industry_branch IS NULL --For Czechia
  GROUP BY
    record_year
),
wage_change_per_year AS (
  SELECT
    y0.record_year,
    (
      (y0.wage_avg_per_year - y1.wage_avg_per_year) / y1.wage_avg_per_year
    ) * 100 AS wage_pct_change
  FROM
    wage_avg_year AS y0
    LEFT JOIN wage_avg_year AS y1 ON y0.record_year = y1.record_year + 1
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
    y0.category,
    y0.record_year,
    (
      (y0.avg_price_per_year - y1.avg_price_per_year) / y1.avg_price_per_year
    ) * 100 AS price_pct_change
  FROM
    price_avg_year AS y0
    LEFT JOIN price_avg_year AS y1 ON y0.category = y1.category
    AND y0.record_year = y1.record_year + 1
) 
--MAIN QUERY
SELECT
  w.record_year,
  round(wage_pct_change, 2) AS wage_change,
  ROUND(AVG(price_pct_change), 2) AS prices_change,
  ROUND(AVG(price_pct_change), 2) - round(wage_pct_change, 2) AS prices_minus_wages
FROM
  wage_change_per_year AS w
  LEFT JOIN price_change_per_year AS p ON w.record_year = p.record_year
WHERE
  wage_pct_change IS NOT NULL
  AND price_pct_change IS NOT null
GROUP BY
  w.record_year,
  wage_pct_change
ORDER BY
  w.record_year ASC;
