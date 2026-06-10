WITH price_data AS (
  SELECT
    category,
    record_year,
    record_quarter,
    price_value
  FROM
    data_academy_content.t_martin_silbernagl_project_sql_primary_final
  WHERE
    (category_code IN (111301, 114201)) --111301 bread, 114201 milk
),
wage_data AS (
  SELECT
    payroll_value,
    record_year,
    record_quarter
  FROM
    data_academy_content.t_martin_silbernagl_project_sql_primary_final
  WHERE
    industry_branch_code IS NULL
    AND payroll_value IS NOT null
) 
SELECT
  sub.category AS item,
  sub.record_year AS year,
  sub.record_quarter AS quarter,
  payroll_value,
  round(payroll_value / price_value) AS items_per_average_wage
FROM
  (
    SELECT
      p.category,
      p.price_value,
      w.payroll_value,
      w.record_year,
      w.record_quarter,
      row_number() OVER (
        PARTITION BY category
        ORDER BY
          p.record_year asc,
          p.record_quarter asc
      ) AS rows_asc,
      row_number() OVER (
        PARTITION BY category
        ORDER BY
          p.record_year desc,
          p.record_quarter desc
      ) AS rows_desc
    FROM
      wage_data AS w
      INNER JOIN price_data AS p ON w.record_year = p.record_year
      AND w.record_quarter = p.record_quarter
  ) sub
WHERE
  sub.rows_asc = 1
  OR sub.rows_desc = 1
ORDER BY
  sub.record_year,
  sub.record_quarter,
  sub.category;
