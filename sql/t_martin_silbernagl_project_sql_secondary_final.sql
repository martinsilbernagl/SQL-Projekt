DROP TABLE IF EXISTS data_academy_content.t_martin_silbernagl_project_sql_secondary_final;

CREATE TABLE data_academy_content.t_martin_silbernagl_project_sql_secondary_final AS 
WITH e AS (
	SELECT
		year,
		UPPER(TRIM(country)) AS e_country_norm, gdp, gini, population
	FROM data_academy_content.economies
),
c AS (
	SELECT
		UPPER(TRIM(country)) AS c_country_norm,
		country AS country_name,
		iso_numeric AS country_code,
		continent
	FROM data_academy_content.countries
)
SELECT
	e.year,
	c.country_name,
	c.country_code,
	e.gdp,
	e.gini,
	e.population
FROM e
JOIN c ON c.c_country_norm = e.e_country_norm
WHERE c.continent = 'Europe'
	AND e.year IN (SELECT year FROM data_academy_content.v_common_years);
