# Analýza změn mezd, cen a dostupnosti potravin v ČR

## Úvod

Tento projekt se zaměřuje na analýzu dostupnosti základních potravin v České republice v kontextu průměrných mezd a ekonomických ukazatelů.  
Cílem je odpovědět na pět výzkumných otázek týkajících se vývoje mezd, cen potravin, jejich dostupnosti a souvislostí s makroekonomickými ukazateli (HDP).

Výstupem projektu jsou:

- dvě datové tabulky uložené v SQL databázi,
- sada analytických SQL dotazů k výzkumným otázkám,
- komentáře a interpretace výsledků.

---
## Datové zdroje

V projektu byly použity datové zdroje z databáze data_academy_2025_09_10.

Projekt využívá následující primární zdroje:
- **Česká data o mzdách** (`czechia_payroll`)
- **Česká data o cenách potravin** (`czechia_price`)
- **Katalogy kategorií** (`czechia_payroll_industry_branch`, `czechia_price_category`)
- **Makroekonomická data světových států** (`economies`, `countries`)

SQL dotazy používájí následující dvě tabulky, které byly vytvořeny pomocí primárních zdrojů:
- t_martin_silbernagl_project_SQL_primary_final
- t_martin_silbernagl_project_SQL_secondary_final

Data byla agregována a sjednocena tak, aby bylo možné provádět meziroční a mezikategoriální porovnání.

---

## Struktura repozitáře

Složka SQL_table_generators obsahuje soubory pro vytvoření dvou finálních analytických tabulek z primárních dat.

Složka SQL_queries obsahuje SQL soubory pro zodpovězení výzkumných otázek.

---

## Přehled datového workflow

### **Extrakce**
- Import dat z jednotlivých zdrojových tabulek.
- Filtrování pouze relevantních hodnot (mzdy s value_type_code 5958, což odpovídá hrubé mzdě na zaměstnance, a calculation_code 200, tedy přepočtený počet na osoby, pro celostátní ceny potravin region_code null, roky 2006-2018).

### **Transformace**
- Konsolidace mezd na úroveň čtvrtletí.
- Agregace cen potravin na průměrné čtvrtletní ceny v letech 2006-2018.

### **Load**
- Vytvoření dvou finálních analytických tabulek:  
  - `t_martin_silbernagl_project_SQL_primary_final`  
  - `t_martin_silbernagl_project_SQL_secondary_final`

Tyto tabulky fungují jako jediný zdroj pravdy (Single Source of Truth) pro následné analýzy.

### Primární tabulka: `t_martin_silbernagl_project_SQL_primary_final`
Obsahuje data o mzdách a cenách potravin v ČR.

Tabulka byla vytvořena souborem `20251126 create primary table`.
Data do tabulky byla vložena pomocí příkazů `20251126 primary table insert wages` a `20251126 primary table insert prices`.

Z tabulky czechia payroll byly pouzity hodnoty s value_type_code 5958, což odpovídá hrubé mzdě na zaměstnance, a calculation_code 200, tedy přepočtený počet na osoby.

Při kopírování dat z tabulky czechia_price byly hodnoty aggregovány podle kvartálu.

| Sloupec | Popis |
|---------|-------|
| record_id | id záznamu po kopírování do tabulky |
| record_type | Typ záznamu (`wages` pro mzdy nebo `prices` pro ceny potravin) |
| payroll_value | Hodnota mzdy (pro `wages`) |
| record_year | Rok záznamu |
| record_quarter | Čtvrtletí záznamu |
| industry_branch | Odvětví (pro mzdy) |
| industry_branch_code | Kód odvětví (pro mzdy) |
| value_type_code | Typ hodnoty (pro mzdy) |
| calculation_code | Kód výpočtu (pro mzdy) |
| category | Kategorie potraviny (pro `prices`) |
| price_value | Cena potraviny (průměr, pro `prices`) |
| category_code | Kód kategorie potraviny |

### Sekundární tabulka: `t_martin_silbernagl_project_sql_secondary_final`

Obsahuje doplňující data o evropských státech včetně hrubého domácího produktu (gdp) pro roky 2006-2018.

Vytvoření souboru je popsáno v souborech `20251126 create secondary table` a `20251126 secondary table insert`.

| Sloupec | Popis |
|---------|-------|
|country |	Název země|
|record_year |	Rok záznamu|
|gdp |	Hrubý domácí produkt|
|population	| Počet obyvatel|
|gini	|GINI koeficient|

---
# Jak projekt spustit 

### Požadavky
Databázový systém: PostgreSQL
(používány funkce regr_slope, regr_intercept, corr, CTE).

Dataset se strukturou odpovídající zdrojovým tabulkám.

### Kroky spuštění

Volitelné: vyvoření primární a sekundární tabulky
- Vytvořte primární tabulku pomocí souboru `20251126 create primary table` 
- Spusťte INSERT skript pro mzdy a spusťte INSERT skript pro ceny potravin pomocí souborů `20251126 primary table insert wages` a `20251126 primary table insert prices`.
- Vytvořte sekundární tabulku pomocí souboru `20251126 create secondary table`
- Spusťte INSERT skript ekonomických dat pomocí souboru `20251126 secondary table insert`

Spustění výzkumných otázek

- Spouštějte jednotlivé analytické SQL dotazy dle výzkumných otázek.

---

# Výzkumné otázky a SQL dotazy

## 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SQL soubor: `20251126 question 1`

***Výsledek a komentář:*** Pro vyhodnocení dlouhodobého trendu mezd v jednotlivých sektorech byl použit fit daty lineární regresí. Sklon přímky (slope) vyjadřuje průmerný mezičtvdletní růst mzdy. Tento sklon je pro všechna odvětví kladný, což znamená, že dlouhodobě mezi sledovaným časovým úsekem 2000-2021 mzdy rostou ve všech odvětvích. Nejrychleji mzdy rostou v odvětví Informační a komunikační činnosti a nejpomaleji v odvětví Ubytování, stravování a pohostinství. Metrika kvality modelu R², která je vysoká (0,56–0,91), což znamená, že čas skutečně vysvětluje většinu variability mezd a trend je robustní. 

## 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd??
SQL soubor: `20251126 question 2`

***Výsledek a komentář:*** Dotaz propojuje průměrné mzdy s cenami chleba a mléka ve stejných letech a čtvrtletích, aby vypočítal, kolik jednotek dané potraviny lze koupit za průměrnou mzdu. Pomocí číslování řádků pak vybere nejstarší a nejnovější dostupné období pro každou potravinu, takže lze jednoduše porovnat vývoj kupní síly v čase.

Výsledky ukazují, že v roce 2006 v prvním kvartálu mohl průměrný zaměstnanec koupit přibližně 1243 bochníků chleba nebo 1287 litrů mléka, zatímco v roce 2018 v posledním kvartálu to bylo už 1425 bochníků chleba a 1747 litrů mléka. To znamená, že i přes nárůst cen potravin rostly mzdy rychleji, a kupní síla ve sledovaných kategoriích se tak zřetelně zvýšila. Nejvýraznější zlepšení je patrné u mléka, kde počet dostupných jednotek vzrostl o více než 35 %, což naznačuje, že zdražení mléka v daném období bylo relativně mírné ve srovnání s růstem mezd. 

## 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
SQL soubor: `20251126 question 3`

***Výsledek a komentář:*** Pro odstranění vlivu výkyvů cen byla spočítána pro jednotlivé kategorie meziroční procentuální změna ceny a poté průměr těchto změn mezi lety. To umožňuje zjistit dlouhodobý trend ve sledovaném období 2006-2018. Výsledek ukazuje, že nejpomaleji zdražující potravinou je cukr krystalový, který dokonce v dlouhodobém průměru o 1,92 % meziročně zlevňoval.

## 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (>10%)?
SQL soubor: `20251126 question 4`

***Výsledek a komentář:*** Dotaz nejprve vypočítá průměrné roční mzdy a jejich meziroční procentuální změny, stejným způsobem pak vypočítá meziroční změny průměrných cen potravin napříč jednotlivými kategoriemi. Tyto změny cen následně zprůměruje pro všechny kategorie za každý rok, aby vznikl jeden agregovaný ukazatel růstu cen potravin. V hlavní části pak spojí meziroční růst mezd a průměrný růst cen potravin podle roku a vypočítá jejich rozdíl.

Výsledky ukazují, že žádný rok ve sledovaném obodbí 2007-2018 nepřekročil rozdíl 10% – nejvyšší zaznamenaný rozdíl byl v roce 2013 (+6,14%), což znamená, že i v nejméně příznivém roce se růst cen potravin neoddělil od růstu mezd tak výrazně, aby přesáhl stanovený limit 10 %.

## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
SQL soubory: `20251126 question 5a` a `20251126 question 5b`

***Výsledek a komentář:*** Analýza nejprve vypočítává meziroční procentuální změny HDP, mezd a cen potravin a poté je porovnává v čase, aby bylo možné sledovat, zda výraznější růst HDP doprovází také rychlejší růst mezd nebo cen potravin ve stejném či následujícím roce. První dotaz 20251126 question 5a poskytuje časovou řadu změn, která ukazuje, že mezi růsty těchto tří veličin neexistuje jednoznačná pravidelnost: v některých letech HDP klesá (např. 2009, 2012), ale mzdy přesto rostou, a naopak v letech s velmi silným růstem HDP (např. 2007, 2015, 2017) se růst cen či mezd pohybuje různými směry a s různou intenzitou.

Druhý dotaz 20251126 question 5b pak pomocí lineární regrese a korelace ukazuje, že vztah mezi růstem HDP a růstem mezd či cen potravin je spíše slabý. Korelace se pohybují mezi 0,04 a 0,48 pro současný rok, což naznačuje nízkou souvislost. Výjimkou je vztah mezi růstem HDP a růstem mezd v následujícím roce, kde je korelace 0,70 a R² = 0,49 – jde tedy o středně silný vztah, který naznačuje, že růst HDP se může výrazněji projevit v dynamice mezd až se zpožděním.

U cen potravin je však vliv HDP velmi omezený, a to jak ve stejném roce (korelace 0,42, nízké R² = 0,18), tak v roce následujícím (prakticky nulový vztah s korelací 0,04 a R² = 0,00). Celkově tedy data naznačují, že vývoj HDP má jen částečný a nestabilní vliv na změny mezd a téměř žádný přímý vliv na vývoj cen potravin, přičemž nejvýrazněji se efekt projevuje u mezd s ročním zpožděním.

## Závěr
Celkově analýza výzkumných otázek ukazuje, že mzdy mají dlouhodobě rostoucí trend ve všech odvětvích, ceny potravin se vyvíjejí různorodě, kupní síla se zpravidla zlepšuje a širší makroekonomický kontext, jako je vývoj HDP, má na tyto procesy omezený, ale stabilní vliv. Bylo by zajímavé tuto analýzu provést i pro roky 2021-2024, protože vysoké hodnoty inflace (15,1% v roce 2022, 10,7% v roce 2023) předčily inflaci během období v našem datasetu, který umožňoval srovnání ceny a mezd pro roky 2006-2018. Lze očekávat, že vývoj cen, mezd a kupní síly v tomto období může ukazovat zajímavé změny.



