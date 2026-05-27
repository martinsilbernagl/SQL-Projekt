-- Projekt 4: research questions
-- All queries expect the tables from `create_final_tables.sql` to exist.

-- Question 1
-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
WITH wage_trend AS (
    SELECT
        year_value,
        industry_branch_name,
        average_payroll_czk,
        LAG(average_payroll_czk) OVER (
            PARTITION BY industry_branch_code
            ORDER BY year_value
        ) AS previous_average_payroll_czk
    FROM (
        SELECT DISTINCT
            year_value,
            industry_branch_code,
            industry_branch_name,
            average_payroll_czk
        FROM t_jmeno_prijmeni_project_SQL_primary_final
    ) wages
)
SELECT
    year_value,
    industry_branch_name,
    average_payroll_czk,
    previous_average_payroll_czk,
    ROUND(
        (
            average_payroll_czk - previous_average_payroll_czk
        ) / previous_average_payroll_czk * 100,
        2
    ) AS payroll_growth_pct
FROM wage_trend
WHERE previous_average_payroll_czk IS NOT NULL
ORDER BY industry_branch_name, year_value;


-- Question 2
-- Kolik litrů mléka a kilogramů chleba je možné koupit za první a poslední srovnatelné období?
WITH comparable_periods AS (
    SELECT
        MIN(year_value) AS first_year,
        MAX(year_value) AS last_year
    FROM t_jmeno_prijmeni_project_SQL_primary_final
),
selected_food AS (
    SELECT
        year_value,
        price_category_name,
        average_price_czk
    FROM t_jmeno_prijmeni_project_SQL_primary_final
    WHERE price_category_name IN (
        'Mléko polotučné pasterované',
        'Chléb konzumní kmínový'
    )
    GROUP BY
        year_value,
        price_category_name,
        average_price_czk
),
average_wage AS (
    SELECT
        year_value,
        ROUND(AVG(average_payroll_czk), 2) AS country_average_payroll_czk
    FROM (
        SELECT DISTINCT
            year_value,
            industry_branch_code,
            average_payroll_czk
        FROM t_jmeno_prijmeni_project_SQL_primary_final
    ) wages
    GROUP BY year_value
)
SELECT
    sf.year_value,
    sf.price_category_name,
    aw.country_average_payroll_czk,
    sf.average_price_czk,
    ROUND(
        aw.country_average_payroll_czk / sf.average_price_czk,
        2
    ) AS purchasable_units
FROM selected_food sf
JOIN comparable_periods cp
    ON sf.year_value IN (cp.first_year, cp.last_year)
JOIN average_wage aw
    ON sf.year_value = aw.year_value
ORDER BY sf.price_category_name, sf.year_value;


-- Question 3
-- Která kategorie potravin zdražuje nejpomaleji?
WITH price_trend AS (
    SELECT
        category_code,
        price_category_name,
        year_value,
        average_price_czk,
        LAG(average_price_czk) OVER (
            PARTITION BY category_code
            ORDER BY year_value
        ) AS previous_average_price_czk
    FROM (
        SELECT DISTINCT
            category_code,
            price_category_name,
            year_value,
            average_price_czk
        FROM t_jmeno_prijmeni_project_SQL_primary_final
    ) prices
),
price_growth AS (
    SELECT
        category_code,
        price_category_name,
        ROUND(
            (
                average_price_czk - previous_average_price_czk
            ) / previous_average_price_czk * 100,
            2
        ) AS yearly_price_growth_pct
    FROM price_trend
    WHERE previous_average_price_czk IS NOT NULL
)
SELECT
    price_category_name,
    ROUND(AVG(yearly_price_growth_pct), 2) AS average_yearly_price_growth_pct
FROM price_growth
GROUP BY price_category_name
ORDER BY average_yearly_price_growth_pct ASC;


-- Question 4
-- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd?
WITH wage_growth AS (
    SELECT
        year_value,
        ROUND(
            (
                average_wage - LAG(average_wage) OVER (ORDER BY year_value)
            ) / LAG(average_wage) OVER (ORDER BY year_value) * 100,
            2
        ) AS wage_growth_pct
    FROM (
        SELECT
            year_value,
            ROUND(AVG(average_payroll_czk), 2) AS average_wage
        FROM (
            SELECT DISTINCT
                year_value,
                industry_branch_code,
                average_payroll_czk
            FROM t_jmeno_prijmeni_project_SQL_primary_final
        ) wages
        GROUP BY year_value
    ) wage_summary
),
price_growth AS (
    SELECT
        year_value,
        ROUND(
            (
                average_price - LAG(average_price) OVER (ORDER BY year_value)
            ) / LAG(average_price) OVER (ORDER BY year_value) * 100,
            2
        ) AS price_growth_pct
    FROM (
        SELECT
            year_value,
            ROUND(AVG(average_price_czk), 2) AS average_price
        FROM (
            SELECT DISTINCT
                year_value,
                category_code,
                average_price_czk
            FROM t_jmeno_prijmeni_project_SQL_primary_final
        ) prices
        GROUP BY year_value
    ) price_summary
)
SELECT
    pg.year_value,
    pg.price_growth_pct,
    wg.wage_growth_pct,
    ROUND(pg.price_growth_pct - wg.wage_growth_pct, 2) AS difference_pct
FROM price_growth pg
JOIN wage_growth wg
    ON pg.year_value = wg.year_value
WHERE pg.price_growth_pct - wg.wage_growth_pct > 10
ORDER BY pg.year_value;


-- Question 5
-- Má výška HDP vliv na změny mezd a cen potravin ve stejném nebo následujícím roce?
WITH wage_growth AS (
    SELECT
        year_value,
        ROUND(
            (
                average_wage - LAG(average_wage) OVER (ORDER BY year_value)
            ) / LAG(average_wage) OVER (ORDER BY year_value) * 100,
            2
        ) AS wage_growth_pct
    FROM (
        SELECT
            year_value,
            ROUND(AVG(average_payroll_czk), 2) AS average_wage
        FROM (
            SELECT DISTINCT
                year_value,
                industry_branch_code,
                average_payroll_czk
            FROM t_jmeno_prijmeni_project_SQL_primary_final
        ) wages
        GROUP BY year_value
    ) wage_summary
),
price_growth AS (
    SELECT
        year_value,
        ROUND(
            (
                average_price - LAG(average_price) OVER (ORDER BY year_value)
            ) / LAG(average_price) OVER (ORDER BY year_value) * 100,
            2
        ) AS price_growth_pct
    FROM (
        SELECT
            year_value,
            ROUND(AVG(average_price_czk), 2) AS average_price
        FROM (
            SELECT DISTINCT
                year_value,
                category_code,
                average_price_czk
            FROM t_jmeno_prijmeni_project_SQL_primary_final
        ) prices
        GROUP BY year_value
    ) price_summary
),
gdp_growth AS (
    SELECT
        year,
        country,
        GDP,
        ROUND(
            (
                GDP - LAG(GDP) OVER (PARTITION BY country ORDER BY year)
            ) / LAG(GDP) OVER (PARTITION BY country ORDER BY year) * 100,
            2
        ) AS gdp_growth_pct
    FROM t_jmeno_prijmeni_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
)
SELECT
    g.year,
    g.gdp_growth_pct,
    wg.wage_growth_pct AS same_year_wage_growth_pct,
    pg.price_growth_pct AS same_year_price_growth_pct,
    wg_next.wage_growth_pct AS next_year_wage_growth_pct,
    pg_next.price_growth_pct AS next_year_price_growth_pct
FROM gdp_growth g
LEFT JOIN wage_growth wg
    ON g.year = wg.year_value
LEFT JOIN price_growth pg
    ON g.year = pg.year_value
LEFT JOIN wage_growth wg_next
    ON g.year + 1 = wg_next.year_value
LEFT JOIN price_growth pg_next
    ON g.year + 1 = pg_next.year_value
WHERE g.gdp_growth_pct IS NOT NULL
ORDER BY g.year;
