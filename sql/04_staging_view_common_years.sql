DROP VIEW IF EXISTS v_common_years;

CREATE VIEW v_common_years AS
SELECT year FROM v_payroll_wage_yearly
INTERSECT
SELECT year FROM v_prices_yearly;
