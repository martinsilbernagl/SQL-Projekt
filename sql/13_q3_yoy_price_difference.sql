WITH price_y AS (
  SELECT
    t.year AS year,
    t.product_name AS product_name,
    AVG(t.avg_price_per_unit_czk) AS price
  FROM data_academy_content.t_martin_silbernagl_project_sql_primary_final t
  GROUP BY t.year, t.product_name
),
yoy AS (
  SELECT
    py.product_name AS product_name,
    py.year AS year,
    (py.price / LAG(py.price) OVER (PARTITION BY py.product_name ORDER BY py.year) - 1) AS yoy_price_growth
  FROM price_y py
)
SELECT
  y.product_name AS product_name,
  ROUND(AVG(y.yoy_price_growth)::numeric, 4) AS avg_yoy_growth
FROM yoy y
WHERE y.yoy_price_growth IS NOT NULL
GROUP BY y.product_name
ORDER BY avg_yoy_growth ASC
LIMIT 10;