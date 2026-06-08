WITH w AS (
	SELECT
		t.year AS year,
		t.industry_name AS industry_name,
		AVG(t.avg_wage_czk) AS wage
	FROM data_academy_content.t_martin_silbernagl_project_sql_primary_final t
	GROUP BY t.year, t.industry_name
)
SELECT
	w.industry_name AS industry_name,
	w.YEAR AS year,
	ROUND(w.wage::NUMERIC, 2) AS avg_wage_czk,
	ROUND((wage / LAG(w.wage) OVER (PARTITION BY w.industry_name ORDER BY w.year) - 1)::NUMERIC, 4) AS yoy_wage_growth
FROM w
ORDER BY w.industry_name, w.year;
