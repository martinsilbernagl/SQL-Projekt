# Projekt 4 – Projekt z SQL

Implementace zadání ze souboru `4 (z wordu).pdf`. Projekt analyzuje
dostupnost základních potravin široké veřejnosti v ČR na základě
průměrných mezd a cen potravin, doplněný o makroekonomický kontext
evropských zemí.

## Soubory

| Soubor | Popis |
|--------|-------|
| `create_final_tables.sql` | Vytvoření obou finálních tabulek |
| `research_questions.sql` | SQL dotazy k 5 výzkumným otázkám |
| `PRUVODNI_LISTINA.md` | Popis mezivýsledků, předpokladů a omezení |
| `README.md` | Stručný návod |

## Jak použít

1. Otevři `create_final_tables.sql`.
2. Zkontroluj jména finálních tabulek (v aktuální verzi `dominik_messer`).
3. Spusť skript nad akademickou databází s tabulkami:
   - `czechia_payroll`, `czechia_payroll_calculation`,
     `czechia_payroll_industry_branch`, `czechia_payroll_unit`,
     `czechia_payroll_value_type`
   - `czechia_price`, `czechia_price_category`
   - `czechia_region`, `czechia_district`
   - `countries`, `economies`
4. Spusť jednotlivé dotazy z `research_questions.sql`.

## Co projekt dodává

1. **Primární tabulku** – společné roky mezd (po odvětvích) a cen
   potravin (po kategoriích) za ČR.
2. **Sekundární tabulku** – HDP, GINI a populace evropských států
   ve stejném časovém rozmezí.
3. **5 SQL dotazů** odpovídajících na výzkumné otázky:
   1. Rostou mzdy ve všech odvětvích, nebo v některých klesají?
   2. Kolik litrů mléka a kg chleba lze koupit za první a poslední
      srovnatelné období?
   3. Která kategorie potravin zdražuje nejpomaleji?
   4. Existuje rok s meziročním nárůstem cen o více než 10 p.p.
      nad růstem mezd?
   5. Má výše HDP vliv na změny ve mzdách a cenách potravin?

## Poznámky

- SQL je psáno pro MySQL/MariaDB.
- Zdrojové tabulky se nijak nemodifikují – veškeré transformace jsou
  v nově vytvořených tabulkách.
- Podrobný popis předpokladů, filtrů a chybějících dat viz
  `PRUVODNI_LISTINA.md`.
