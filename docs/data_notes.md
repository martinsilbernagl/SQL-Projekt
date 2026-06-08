# Data Notes – sql_project_01 Food Accessibility

Last updated: 2026-06-08 
Author: Martin Silbernágl

## 1) Purpose
This document records data quality findings, assumptions, filters, and transformations so the analysis is reproducible and auditable. Final answers and key figures are summarized in README.

## 2) Data Sources
- `czechia_payroll` + reference tables:
  - `czechia_payroll_industry_branch` (industry),
  - `czechia_payroll_unit` (units),
  - `czechia_payroll_value_type` (metrics),
  - `czechia_payroll_calculation` (calculation method).
- `czechia_price` + `czechia_price_category` (food prices).
- Additional: `economies`, `countries` (EU metrics: GDP, GINI, population).

## 3) Known Issues / Anomalies

### 3.1 Swapped units in `czechia_payroll`
While inspecting `value_type_code × unit_code` combinations, I observed:

- `value_type_code = 5958` = “Průměrná hrubá mzda na zaměstnance” (Average gross wage per employee)  
  appears in the raw data with `unit_code = 200` = “tis. osob (thousands of persons)” expected: CZK

- `value_type_code = 316` = “Průměrný počet zaměstnaných osob” (Average number of employed persons)  
  appears with `unit_code = 80403` = “Kč (CZK)” expected: thousands of persons

Interpretation: In this dataset dump, the unit codes for the two primary metrics appear swapped. The values themselves look plausible (wages in thousands/tens of thousands CZK; employment in thousands of persons), but the attached `unit_code` is inconsistent.

Decision: I did not modify raw data. Instead, I fixed the interpretation in staging views by deriving the unit logically from `value_type_code` (wages → CZK, employment → thousands of persons).

Diagnostic query (repro):
```sql
SELECT 
  vt.code AS vt_code, vt.name AS value_type,
  u.code  AS unit_code, u.name AS unit_name,
  COUNT(*) AS rows,
  MIN(p.value) AS min_v, MAX(p.value) AS max_v
FROM czechia_payroll p
JOIN czechia_payroll_value_type vt ON vt.code = p.value_type_code
JOIN czechia_payroll_unit       u  ON u.code  = p.unit_code
GROUP BY 1,2,3,4
ORDER BY 1,3;
```

## 4) Transformations & Staging (recap)

### 4.1 Wages (staging)
`v_payroll_wage_yearly` — yearly average gross wage per employee (CZK), by industry.  
Filter by `value_type_code = 5958`. Aggregated to `year × industry`.

### 4.2 Prices (staging)
`v_prices_yearly` — yearly average **standardized** price per product:
- Normalize per-unit:
  - `g`→`kg` and `ml`→`l` via 1000 multiplier,
  - else use provided unit and `price_value` as divisor.
- Grain: `year × product`.

### 4.3 Common years
`v_common_years` — intersection of years present in both staging views.
**Schema:** `data_academy_content` (adjust if different in your DB).

### 4.4 Primary final (CZ)
**Name:** `data_academy_content.t_martin_silbernagl_project_sql_primary_final`  
**Grain:** 1 row = `industry × product × year` (CZ only, common years)  
**Columns (key):** `year, industry_code, industry_name, avg_wage_czk, product_name, unit_std, avg_price_per_unit_czk, purchasable_units_per_avg_wage`  
**Note:** `purchasable_units_per_avg_wage = avg_wage_czk / avg_price_per_unit_czk` (safety via `NULLIF`).

- Primary final table is built via a single `CREATE TABLE AS` statement using CTEs (common_years, wages, prices) for clarity and reproducibility.
- Rounding convention: monetary/unit values are rounded to 2 decimals; YoY growth rates in analysis queries are rounded to 4 decimals.


---

## 5) Secondary Final (Europe macro indicators)

**Name:** `data_academy_content.t_martin_silbernagl_project_sql_secondary_final`  
**Grain:** 1 row = `country × year`  
**Coverage:** `countries.continent IN 'Europe'` and `year IN v_common_years` 
**Columns:** `year, country_name, country_code, gdp, gini, population`
**Country code:** `iso_numeric` from `countries` (aliased to `country_code`).

### 5.1 Source tables
- `data_academy_content.economies` (`year, country, gdp, gini, population`)
- `data_academy_content.countries` (`country, iso_numeric, continent`)

### 5.2 Join strategy
- Normalize names on both sides with `UPPER(TRIM(...))`.
- Inner join `economies` ↔ `countries` on normalized name.
- Aggregates/regions present in `economies.country` (e.g. "European Union," "Small states") are **excluded automatically** by the join (no matching row in `countries`).

### 5.3 Decisions
- Years: aligned to v_common_years (consistent with the primary final table)
- Scope: Europe only via countries.continent
- Czech Republic: included
- No raw-data edits: cleaning handled in CTAS

**Repro (simplified CTAS):**
```sql
DROP TABLE IF EXISTS data_academy_content.t_martin_silbernagl_project_sql_secondary_final;

CREATE TABLE data_academy_content.t_martin_silbernagl_project_sql_secondary_final AS
WITH e AS (
  SELECT year,
         UPPER(TRIM(country)) AS e_country_norm,
         gdp, gini, population
  FROM data_academy_content.economies
),
c AS (
  SELECT UPPER(TRIM(country)) AS c_country_norm,
         country              AS country_name,
         iso_numeric          AS country_code,
         continent
  FROM data_academy_content.countries
)
SELECT e.year, c.country_name, c.country_code, e.gdp, e.gini, e.population
FROM e
JOIN c ON c.c_country_norm = e.e_country_norm
WHERE c.continent = 'Europe'
  AND e.year IN (SELECT year FROM data_academy_content.v_common_years);  -- adjust schema if needed
```

## 6) Analysis Notes - Research Questions

### 6.1 Question 1 (Are wages rising across all sectors over the years, or are they falling in some?)

#### 6.1.1 Analysis Notes
- Analysis is based on the **primary final table** (`data_academy_content.t_martin_silbernagl_project_sql_primary_final`).
- Because the primary final table has grain `industry × product × year`, wage values are repeated across products for the same `industry × year`.
- To evaluate wage trends correctly, wages are first aggregated to **industry × year**.
- Year-over-year (YoY) wage growth is then calculated using a **window function** (`LAG`).
- The first available year for each industry has `NULL` YoY growth (no previous year for comparison).
- Negative YoY values indicate a year-on-year wage decline in a given industry.

### 6.2 Question 2 (How many liters of milk and kilograms of bread can be purchased for the average wage in the first and last comparable period?)

#### 6.2.1 Analysis Notes
- Analysis is based on the **primary final table** (`data_academy_content.t_martin_silbernagl_project_sql_primary_final`).
- The helper column `purchasable_units_per_avg_wage` is used to represent purchasing power:
  - `avg_wage_czk / avg_price_per_unit_czk`
- Because the primary final table has grain `industry × product × year`, purchasing power values are repeated across industries for the same `product × year`.
- To evaluate purchasing power by product correctly, values are first aggregated to **product × year** using `AVG(purchasable_units_per_avg_wage)`.
- The analysis is filtered to product names containing **milk** (`mléko`) and **bread** (`chléb`).
- The first and last available comparable years are identified from the filtered dataset (`MIN(year)`, `MAX(year)`).
- Results are presented as the number of standardized units (liters / kilograms) purchasable for the average wage in the first and last year.

### 6.3 Question 3 (Which food product is rising in price the slowest, i.e. has the lowest year-on-year percentage increase?)

#### 6.3.1 Analysis Notes
- Analysis is based on the **primary final table** (`data_academy_content.t_martin_silbernagl_project_sql_primary_final`).
- Because the primary final table has grain `industry × product × year`, price values are repeated across industries for the same `product × year`.
- To evaluate price trends correctly, prices are first aggregated to **product × year** using `AVG(avg_price_per_unit_czk)`.
- Year-over-year (YoY) price growth is then calculated for each product using a **window function** (`LAG`) and the formula:
  - `(current_year_price / previous_year_price) - 1`
- The first available year for each product has `NULL` YoY growth (no previous year for comparison) and is excluded from averaging.
- The final comparison ranks products by the **average YoY price growth** in ascending order.
- Lower values indicate slower price growth; negative values indicate an average decline over the observed period.

### 6.4 Question 4 (Is there a year in which food prices increased significantly more than wages, i.e., by more than 10 percentage points?)

#### 6.4.1 Analysis Notes
- Analysis is based on the **primary final table** (`data_academy_content.t_martin_silbernagl_project_sql_primary_final`).
- To compare overall wage and price dynamics, the data is aggregated to **year level**:
  - wages: `AVG(avg_wage_czk)` by year
  - prices: `AVG(avg_price_per_unit_czk)` by year
- Year-over-year (YoY) growth is calculated separately for wages and prices using **window functions** (`LAG`).
- The gap is then computed as:
  - `yoy_price - yoy_wage`
- The final query filters to years where the gap is **greater than 0.10** (i.e., food prices grew by more than 10 percentage points above wages).
- The first available year has `NULL` YoY values and is excluded from comparison.
- Positive gap values indicate faster price growth than wage growth; the threshold identifies years with a materially higher increase in food prices.
- In this project run, the final filtered query returned **no rows**, which is interpreted as a **valid negative finding** (no year met the `> 0.10` condition), not as a query error.
- The result was validated using step-by-step checks (yearly aggregates, YoY calculations without the threshold filter, and ranking years by the gap) to confirm that the absence of rows is caused by the `> 0.10` condition rather than missing data.

### 6.5 Question 5 (Does GDP growth influence changes in wages and food prices in the same or the following year?)

#### 6.5.1 Analysis Notes
- Analysis combines:
  - the **primary final table** (`data_academy_content.t_martin_silbernagl_project_sql_primary_final`) for Czech wage and food price indicators,
  - the **secondary final table** (`data_academy_content.t_martin_silbernagl_project_sql_secondary_final`) for macroeconomic indicators (`gdp`, `gini`, `population`) across European countries.
- From the primary final table, data is aggregated to **year level** (Czech Republic) to produce:
  - `AVG(avg_wage_czk)` as yearly wage indicator,
  - `AVG(avg_price_per_unit_czk)` as yearly food price indicator.
- From the secondary final table, records are filtered to **`country_name = 'Czech Republic'`** (adjusted if needed to match the actual label in the dataset).
- The yearly Czech wage/price series and Czech macro series are joined by **`year`**.
- Year-over-year (YoY) changes are calculated using **window functions** (`LAG`) for:
  - wages (`yoy_wage`)
  - food prices (`yoy_price`)
  - GDP (`yoy_gdp`)
- To inspect a possible delayed effect, the query then calculates **next-year** wage and price YoY values using **`LEAD`** on the already computed YoY columns (in the outer query).
- The first available year has `NULL` YoY values (no previous year for comparison), and the last available year has `NULL` next-year YoY values (no following year available).
- `gini` and `population` are included as contextual variables in the output but are not directly used in the YoY calculations.
- The output is intended as an **analytical comparison table** for interpretation of same-year and next-year patterns; it does **not** by itself prove causal influence of GDP on wages or food prices.