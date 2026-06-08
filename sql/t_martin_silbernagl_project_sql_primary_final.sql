DROP TABLE IF EXISTS data_academy_content.t_martin_silbernagl_project_sql_primary_final;

CREATE TABLE data_academy_content.t_martin_silbernagl_project_sql_primary_final AS
WITH common_years AS (
	SELECT 
		y.year AS year
	FROM data_academy_content.v_common_years y
),
wages AS (
	SELECT
		pw.year AS YEAR, 
		pw.industry_code AS industry_code, 
		pw.industry_name AS industry_name, 
		pw.avg_wage_czk AS avg_wage_czk 
	FROM data_academy_content.v_payroll_wage_yearly pw
),
prices AS (
	SELECT
		pr.year AS year, 
		pr.price_category_code AS price_category_code, 
		pr.product_name AS product_name, 
		pr.unit_std AS unit_std, 
		pr.avg_price_per_unit_czk AS avg_price_per_unit_czk 
	FROM data_academy_content.v_prices_yearly pr
)
SELECT 
	cy.year AS year,
	w.industry_code AS industry_code,
	w.industry_name AS industry_name,
	ROUND(w.avg_wage_czk::NUMERIC, 2) AS avg_wage_czk,
	p.price_category_code AS price_category_code,
	p.product_name AS product_name,
	p.unit_std AS unit_std,
	ROUND(p.avg_price_per_unit_czk::NUMERIC, 2) AS avg_price_per_unit_czk,
	ROUND((w.avg_wage_czk / NULLIF(p.avg_price_per_unit_czk, 0))::NUMERIC, 2) AS purchasable_units_per_avg_wage
FROM common_years cy
JOIN wages w ON w.YEAR = cy.year
JOIN prices p ON p.YEAR = cy.year;



