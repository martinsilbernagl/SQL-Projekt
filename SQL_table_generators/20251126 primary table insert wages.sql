INSERT INTO
    t_martin_silbernagl_project_sql_primary_final (
        record_type,
        payroll_value,
        record_year,
        record_quarter,
        industry_branch,
        industry_branch_code,
        value_type_code,
        calculation_code
    )
SELECT
    --- INSERT WAGES
    'wages',
    cp.value,
    cp.payroll_year,
    cp.payroll_quarter,
    cpib.name,
    cp.industry_branch_code,
    cp.value_type_code,
    cp.calculation_code
FROM
    czechia_payroll AS cp
    LEFT JOIN czechia_payroll_industry_branch AS cpib ON cp.industry_branch_code = cpib.code
WHERE
    cp.value_type_code = 5958 --hruba mzda na zamestnance
    AND cp.calculation_code = 200 --prepocteny pocet
    and payroll_year >= 2006
	and payroll_year <= 2018
;


