INSERT into
    t_martin_silbernagl_project_sql_secondary_final (
        country,
        record_year,
        gdp,
        population,
        gini
    )
SELECT
    e.country,
    e.year,
    e.gdp,
    e.population,
    e.gini
FROM
    economies AS e
    LEFT JOIN countries AS c ON e.country = c.country
WHERE
    c.continent = 'Europe'
    AND e.year >= 2006 --to be consistent with primary table 
    AND e.year <= 2018;

