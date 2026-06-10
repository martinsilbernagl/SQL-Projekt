CREATE TABLE 
    t_martin_silbernagl_project_sql_primary_final (
    record_type VARCHAR(20),
    -- 'wages' nebo 'prices'
    record_year INT,
    record_quarter INT,
    -- for wages
    payroll_value NUMERIC(12, 2),
    industry_branch VARCHAR(255),
    industry_branch_code VARCHAR(255),
    value_type_code INT,
    calculation_code INT,
    -- for prices
    category VARCHAR(255),
    price_value NUMERIC(10, 1),
    category_code INT
);

