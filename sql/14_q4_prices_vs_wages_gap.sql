WITH w AS (
  SELECT 
  	t.year AS year, 
  	AVG(t.avg_wage_czk) AS wage
  FROM data_academy_content.t_martin_silbernagl_project_sql_primary_final t
  GROUP BY t.year
),
p AS (
  SELECT 
  	t.year AS year, 
  	AVG(t.avg_price_per_unit_czk) AS price
  FROM data_academy_content.t_martin_silbernagl_project_sql_primary_final t
  GROUP BY t.year
),
g AS (
  SELECT
    w.year AS year,
    (w.wage  / LAG(w.wage)  OVER (ORDER BY w.year) - 1) AS yoy_wage,
    (p.price / LAG(p.price) OVER (ORDER BY p.year) - 1) AS yoy_price
  FROM w 
  JOIN p ON p.year = w.year
)
SELECT
  g.year AS year,
  ROUND(g.yoy_price::numeric,4) AS yoy_price,
  ROUND(g.yoy_wage::numeric,4)  AS yoy_wage,
  ROUND((g.yoy_price - g.yoy_wage)::numeric,4) AS gap_price_minus_wage
FROM g
WHERE g.yoy_price IS NOT NULL 
	AND g.yoy_wage IS NOT NULL
  	AND (g.yoy_price - g.yoy_wage) > 0.10
ORDER BY g.year;