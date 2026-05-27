-- Projekt 4: SQL final tables
-- Replace `jmeno` and `prijmeni` in the final table names with your own values
-- before executing in the academy database.

DROP TABLE IF EXISTS t_jmeno_prijmeni_project_SQL_primary_final;

CREATE TABLE t_jmeno_prijmeni_project_SQL_primary_final AS
WITH comparable_years AS (
    SELECT DISTINCT cp.payroll_year AS year_value
    FROM czechia_payroll cp
    WHERE cp.value_type_code = 5958
        AND cp.calculation_code = 100
        AND cp.value IS NOT NULL
    INTERSECT
    SELECT DISTINCT YEAR(cpr.date_from) AS year_value
    FROM czechia_price cpr
    WHERE cpr.value IS NOT NULL
),
payroll_yearly AS (
    SELECT
        cp.payroll_year AS year_value,
        cp.industry_branch_code,
        cpib.name AS industry_branch_name,
        ROUND(AVG(cp.value), 2) AS average_payroll_czk,
        cpvt.name AS payroll_value_type,
        cpu.name AS payroll_unit
    FROM czechia_payroll cp
    JOIN czechia_payroll_industry_branch cpib
        ON cp.industry_branch_code = cpib.code
    JOIN czechia_payroll_value_type cpvt
        ON cp.value_type_code = cpvt.code
    JOIN czechia_payroll_unit cpu
        ON cp.unit_code = cpu.code
    WHERE cp.value_type_code = 5958
        AND cp.calculation_code = 100
        AND cp.value IS NOT NULL
        AND cp.industry_branch_code IS NOT NULL
    GROUP BY
        cp.payroll_year,
        cp.industry_branch_code,
        cpib.name,
        cpvt.name,
        cpu.name
),
price_yearly AS (
    SELECT
        YEAR(cpr.date_from) AS year_value,
        cpr.category_code,
        cpc.name AS price_category_name,
        cpc.price_value,
        cpc.price_unit,
        ROUND(AVG(cpr.value), 2) AS average_price_czk
    FROM czechia_price cpr
    JOIN czechia_price_category cpc
        ON cpr.category_code = cpc.code
    WHERE cpr.value IS NOT NULL
    GROUP BY
        YEAR(cpr.date_from),
        cpr.category_code,
        cpc.name,
        cpc.price_value,
        cpc.price_unit
)
SELECT
    py.year_value,
    py.industry_branch_code,
    py.industry_branch_name,
    py.average_payroll_czk,
    py.payroll_value_type,
    py.payroll_unit,
    pry.category_code,
    pry.price_category_name,
    pry.price_value,
    pry.price_unit,
    pry.average_price_czk
FROM comparable_years cy
JOIN payroll_yearly py
    ON cy.year_value = py.year_value
JOIN price_yearly pry
    ON cy.year_value = pry.year_value;


DROP TABLE IF EXISTS t_jmeno_prijmeni_project_SQL_secondary_final;

CREATE TABLE t_jmeno_prijmeni_project_SQL_secondary_final AS
WITH comparable_years AS (
    SELECT DISTINCT year_value
    FROM t_jmeno_prijmeni_project_SQL_primary_final
),
year_range AS (
    SELECT
        MIN(year_value) AS min_year,
        MAX(year_value) AS max_year
    FROM comparable_years
)
SELECT
    c.country,
    c.continent,
    e.year,
    e.GDP,
    e.gini,
    e.population
FROM countries c
JOIN economies e
    ON c.country = e.country
JOIN year_range yr
    ON e.year BETWEEN yr.min_year AND yr.max_year
WHERE c.continent = 'Europe'
    AND e.GDP IS NOT NULL;
