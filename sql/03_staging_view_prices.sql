DROP VIEW IF EXISTS v_prices_yearly;
CREATE VIEW v_prices_yearly AS
WITH normalized AS (
  SELECT
    EXTRACT(YEAR FROM cp.date_from)::int AS year,
    cpc.code        AS price_category_code,
    cpc.name        AS product_name,
    -- standardized unit label
    CASE
      WHEN cpc.price_unit = 'g'  THEN 'kg'
      WHEN cpc.price_unit = 'ml' THEN 'l'
      ELSE cpc.price_unit
    END AS unit_std,
    -- price per standardized unit in CZK
    CASE
      WHEN cpc.price_unit = 'g'  THEN (cp.value / NULLIF(cpc.price_value,0)) * 1000  -- per 1 kg
      WHEN cpc.price_unit = 'ml' THEN (cp.value / NULLIF(cpc.price_value,0)) * 1000  -- per 1 l
      ELSE (cp.value / NULLIF(cpc.price_value,0))                                    -- per 1 kg / 1 l / 1 ks
    END AS price_per_unit_czk
  FROM czechia_price cp
  JOIN czechia_price_category cpc
    ON cpc.code = cp.category_code
  WHERE cp.region_code IS NULL
)
SELECT
  year,
  price_category_code,
  product_name,
  unit_std,
  AVG(price_per_unit_czk) AS avg_price_per_unit_czk
FROM normalized
GROUP BY year, price_category_code, product_name, unit_std;
