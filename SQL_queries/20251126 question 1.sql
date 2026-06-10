SELECT
    industry_branch,
    round(
        regr_slope(
            payroll_value::double precision,
            (record_year + (record_quarter -1) * 0.25)::double precision
        )::numeric,
        2
    ) AS slope,
    round(
        regr_intercept(
            payroll_value::double precision,
            (record_year + (record_quarter -1) * 0.25)::double precision
        )::numeric,
        2
    ) AS intercept,
    round(
        regr_r2(
            payroll_value::double precision,
            (record_year + (record_quarter -1) * 0.25)::double precision
        ):: numeric,
        2
    ) AS r2
FROM
    data_academy_content.t_martin_silbernagl_project_sql_primary_final
WHERE
    industry_branch IS NOT null
GROUP BY
    industry_branch
ORDER BY
    slope DESC;


