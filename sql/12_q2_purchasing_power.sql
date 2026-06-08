WITH pp AS (
  SELECT
    t.year AS year,
    t.product_name AS product_name,
    AVG(t.purchasable_units_per_avg_wage) AS units_per_avg_wage
  FROM data_academy_content.t_martin_silbernagl_project_sql_primary_final t
  WHERE t.product_name ILIKE '%mléko%' OR t.product_name ILIKE '%chléb%'
  GROUP BY t.year, t.product_name
),
bounds AS (
  SELECT
    MIN(pp.year) AS first_year, 
    MAX(pp.year) AS last_year
  FROM pp
)
SELECT
  pp.product_name AS product_name,
  MAX(CASE WHEN pp.year = b.first_year THEN ROUND(pp.units_per_avg_wage::numeric, 2) END) AS first_year_units,
  MAX(CASE WHEN pp.year = b.last_year  THEN ROUND(pp.units_per_avg_wage::numeric, 2) END) AS last_year_units
FROM pp
CROSS JOIN bounds b
GROUP BY pp.product_name
ORDER BY pp.product_name;