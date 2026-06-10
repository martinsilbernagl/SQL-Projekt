WITH avg_year AS (
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
change_per_year AS (
  SELECT
    y0.category,
    y0.record_year,
    (
      (y0.avg_price_per_year - y1.avg_price_per_year) / y1.avg_price_per_year
    ) * 100 AS pct_change
  FROM
    avg_year AS y0
    LEFT JOIN avg_year AS y1 ON y0.category = y1.category
    AND y0.record_year = y1.record_year + 1
)
SELECT
  category,
  round(avg(pct_change), 2) AS average_pct_change
FROM
  change_per_year
WHERE
  pct_change IS NOT NULL
GROUP BY
  category
ORDER BY
  average_pct_change ASC
LIMIT
  1;
