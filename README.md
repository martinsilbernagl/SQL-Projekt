# SQL Project – Food Accessibility Analysis (CZ)

## Project Overview
This project prepares analytical data for evaluating food affordability in the Czech Republic based on the relationship between average wages and food prices over time.

The project outputs:
1. a **primary final table** combining Czech wages and food prices for comparable years,
2. a **secondary final table** with macroeconomic indicators (GDP, GINI, population) for European countries in the same comparable period,
3. a set of SQL scripts answering five research questions defined in the assignment.

## Final Output Tables
The following final tables are created in the database:

- `data_academy_content.t_martin_silbernagl_project_sql_primary_final`
- `data_academy_content.t_martin_silbernagl_project_sql_secondary_final`

## Results / Answers to Research Questions

### Q1) Are wages rising across all sectors over the years, or are they falling in some?
Wages generally trend upward over the observed period, but the data shows that **some industries experienced year-on-year declines in specific years**.

Industries with the most frequent declines:
- **Mining and quarrying**: declines in **4 years** (2009, 2013, 2014, 2016); worst decline **-3.74%**.
- **Electricity, gas, steam and air conditioning supply**: declines in **2013, 2015**; worst decline **-4.37%**.
- **Professional, scientific and technical activities**: declines in **2010, 2013**; worst decline **-2.91%**.
- **Public administration and defence; compulsory social security**: declines in **2010, 2011**; worst decline **-2.24%**.
- **Arts, entertainment and recreation**: declines in **2011, 2013**; worst decline **-1.38%**.
- **Accommodation and food service activities**: declines in **2009, 2011**; worst decline **-1.20%**.

Notable single-year drops:
- **Financial and insurance activities** had the largest single decline in the output: **-8.91% in 2013**.

Interpretation: The hypothesis “wages rise in all sectors every year” is **not fully supported**. While wages mostly increase, several industries show measurable year-to-year decreases, especially around **2013**.

---

### Q2) How many liters of milk and kilograms of bread can be purchased for the average wage in the first and last comparable period?
Purchasing power was evaluated using the helper metric:
`purchasable_units_per_avg_wage = avg_wage_czk / avg_price_per_unit_czk`.

Results (first vs last comparable year in the dataset):
- **Bread (Chléb konzumní kmínový)**: **1287.18** → **1342.33** units per average wage (increase).
- **Milk (Mléko polotučné pasterované)**: **1437.44** → **1641.64** units per average wage (increase).

Interpretation: For both selected staples, the number of purchasable standardized units **increased** from the first to the last comparable year.

---

### Q3) Which food product increases in price the slowest (lowest year-on-year percentage increase)?
For each product, year-on-year (YoY) price growth was calculated and then averaged across years. The lowest average YoY growth indicates the slowest long-term price increase.

Top 5 slowest-growing products (by average YoY growth):
1. **Cukr krystalový**: **-0.0192** (average decline)
2. **Rajská jablka červená kulatá**: **-0.0074** (average decline)
3. **Banány žluté**: **0.0081**
4. **Vepřová pečeně s kostí**: **0.0099**
5. **Přírodní minerální voda uhličitá**: **0.0103**

Interpretation: Some products show a **negative** average YoY change (prices decreased on average over the observed period). Among the listed products, sugar (“Cukr krystalový”) shows the slowest price development overall.

---

### Q4) Is there a year in which food prices increased significantly more than wages (by more than 10 percentage points)?
The query searched for years where:
`(yoy_price - yoy_wage) > 0.10`.

**Result:** No year met this condition (the query returned **0 rows**).  
To confirm the finding, the maximum observed gap was computed:
- **Max gap:** **0.0717** (7.17 percentage points) in **2013**

Interpretation: The hypothesis that there exists a year where food prices outpaced wages by **more than 10 percentage points** is **not supported** by the data for the comparable period.

---

### Q5) Does GDP growth relate to wage and food price changes in the same year or the following year?
For the Czech Republic, yearly YoY changes were computed for:
- wages (`yoy_wage`)
- food prices (`yoy_price`)
- GDP (`yoy_gdp`)
and next-year wage/price changes were included (`yoy_wage_next_year`, `yoy_price_next_year`) to inspect possible delayed effects.

Observed patterns (examples from the output):
- When GDP growth was relatively high in **2007** (`yoy_gdp = 0.0557`), wages and prices also increased in the same year (`yoy_wage = 0.0684`, `yoy_price = 0.0656`), and the following year remained positive for wages (`yoy_wage_next_year = 0.0787`) while price growth slowed (`yoy_price_next_year = 0.0608`).
- In **2009**, GDP contracted (`yoy_gdp = -0.0466`) and wages declined (`yoy_wage = 0.0316` in 2008 shifted to **-0.0624** in 2009), while food prices still increased slightly in 2010 (`yoy_price_next_year = 0.0211`).
- A higher GDP growth in **2015** (`yoy_gdp = 0.0539`) coincided with wage growth (`yoy_wage = 0.0251`) and modest price growth (`yoy_price = 0.0133`), with the next-year indicators suggesting continued wage growth and slightly negative price growth in the following year (`yoy_price_next_year = -0.0107` in the shown output range).

Interpretation: The output suggests that GDP, wages, and food prices often move in the same general direction, but the relationship is **not uniform** across years. This analysis provides an exploratory basis for comparison (same-year and next-year), but does **not** establish causality.

> Note: Some scripts may need schema qualification adjustment depending on local DB setup.

## Repository Structure
- `sql/` – SQL scripts for exploration, staging views, final tables, and research-question analysis
- `docs/data_notes.md` – detailed data notes (data quality findings, assumptions, transformations, methodology notes, and analysis notes)
- `README.md` – project overview and execution guide

### Research question queries
- `sql/11_q1_yoy_wage_trends.sql`  
  Q1: Are wages rising across all sectors over the years, or are they falling in some?
- `sql/12_q2_purchasing_power.sql`  
  Q2: How much milk and bread can be purchased for an average wage in the first and last comparable period?
- `sql/13_q3_yoy_price_difference.sql`  
  Q3: Which food product increases in price the slowest (lowest YoY percentage increase)?
- `sql/14_q4_prices_vs_wages_gap.sql`  
  Q4: Is there a year in which food prices increased significantly more than wages (more than 10 percentage points)?
- `sql/15_q5_gdp_effect.sql`  
  Q5: Does GDP growth relate to wage and food price changes in the same year or the following year?

## How to Run (Execution Order)
If you want to rebuild the project outputs from scratch, run the scripts in this order:

1. `sql/01_explore_payroll.sql` (optional diagnostics)
2. `sql/02_staging_view_payroll.sql`
3. `sql/03_staging_view_prices.sql`
4. `sql/04_staging_view_common_years.sql`
5. `sql/t_martin_silbernagl_project_sql_primary_final.sql`
6. `sql/t_martin_silbernagl_project_sql_secondary_final.sql`
7. `sql/11_q1_yoy_wage_trends.sql`
8. `sql/12_q2_purchasing_power.sql`
9. `sql/13_q3_yoy_price_difference.sql`
10. `sql/14_q4_prices_vs_wages_gap.sql`
11. `sql/15_q5_gdp_effect.sql`

## SQL Scripts Overview (Quick Map)
- `01_explore_*.sql` – exploratory diagnostics (optional)
- `02–04_staging_*.sql` – build staging views + common years
- `t_*_primary_final.sql`, `t_*_secondary_final.sql` – build final tables
- `11–15_q*.sql` – answer research questions using only final tables

## Documentation
Detailed methodology and data-quality notes are documented in:
- `docs/data_notes.md`

## Notes / Assumptions
- Raw source tables were **not modified**.
- Data cleaning / interpretation fixes were handled in staging views and final-table logic.
- Results may support or refute the research questions depending on the observed data.

## Author
Martin Silbernágl