WITH cz_aff AS (
  SELECT
    t.year AS year,
    AVG(t.avg_wage_czk)           AS wage,
    AVG(t.avg_price_per_unit_czk) AS price
  FROM data_academy_content.t_martin_silbernagl_project_sql_primary_final t
  GROUP BY t.year
),
cz_macro AS (
  SELECT
    s.year AS year,
    s.gdp AS gdp,
    s.gini AS gini,
    s.population AS population
  FROM data_academy_content.t_martin_silbernagl_project_sql_secondary_final s
  WHERE s.country_name = 'Czech Republic'
),
base AS (
  SELECT
    a.year AS year,
    (a.wage  / LAG(a.wage)  OVER (ORDER BY a.year) - 1) AS yoy_wage,
    (a.price / LAG(a.price) OVER (ORDER BY a.year) - 1) AS yoy_price,
    (m.gdp   / LAG(m.gdp)   OVER (ORDER BY m.year) - 1) AS yoy_gdp,
    m.gini AS gini,
    m.population AS population
  FROM cz_aff a
  JOIN cz_macro m ON m.year = a.year
)
SELECT
  b.year AS year,
  ROUND(b.yoy_wage::numeric, 4)  AS yoy_wage,
  ROUND(b.yoy_price::numeric, 4) AS yoy_price,
  ROUND(b.yoy_gdp::numeric, 4)   AS yoy_gdp,
  ROUND(LEAD(b.yoy_wage)  OVER (ORDER BY b.year)::numeric, 4)  AS yoy_wage_next_year,
  ROUND(LEAD(b.yoy_price) OVER (ORDER BY b.year)::numeric, 4)  AS yoy_price_next_year,
  b.gini AS gini,
  b.population AS population
FROM base b
ORDER BY b.year;