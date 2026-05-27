# Projekt 4 – Průvodní listina

## Cíl projektu

Analytické oddělení nezávislé společnosti zkoumá životní úroveň občanů ČR.
Cílem je připravit robustní datové podklady pro porovnání dostupnosti
základních potravin na základě průměrných příjmů za určité časové období
a doplnit je o mezinárodní kontext (HDP, GINI, populace evropských zemí).

## Výstupy

### Primární tabulka – `t_jmeno_prijmeni_project_SQL_primary_final`

Sjednocuje data o průměrných mzdách podle odvětví (`czechia_payroll`)
a průměrných cenách potravin (`czechia_price`) za **společné roky**
(roky, které existují v obou zdrojích současně).

Sloupce:

| Sloupec | Zdroj | Popis |
|---------|-------|-------|
| `year_value` | oba | Společný rok |
| `industry_branch_code` | `czechia_payroll` | Kód odvětví |
| `industry_branch_name` | `czechia_payroll_industry_branch` | Název odvětví |
| `average_payroll_czk` | `czechia_payroll` | Průměrná mzda v Kč (roční průměr) |
| `payroll_value_type` | `czechia_payroll_value_type` | Typ hodnoty mzdy |
| `payroll_unit` | `czechia_payroll_unit` | Jednotka mzdy |
| `category_code` | `czechia_price` | Kód kategorie potraviny |
| `price_category_name` | `czechia_price_category` | Název kategorie potraviny |
| `price_value` | `czechia_price_category` | Referenční množství |
| `price_unit` | `czechia_price_category` | Jednotka množství |
| `average_price_czk` | `czechia_price` | Průměrná cena v Kč (roční průměr) |

Filtry použité na zdrojová data:

- `value_type_code = 5958` – průměrná hrubá mzda na zaměstnance
- `calculation_code = 100` – přepočtený počet zaměstnanců
- Záznamy s `NULL` hodnotou mzdy nebo ceny jsou vyloučeny
- Záznamy bez odvětví (`industry_branch_code IS NULL`) jsou vyloučeny

### Sekundární tabulka – `t_jmeno_prijmeni_project_SQL_secondary_final`

Doplňkový datový podklad s makroekonomickými ukazateli evropských států
ve stejném časovém rozmezí jako primární tabulka.

Sloupce:

| Sloupec | Zdroj | Popis |
|---------|-------|-------|
| `country` | `countries` | Název státu |
| `continent` | `countries` | Kontinent (filtrováno na Europe) |
| `year` | `economies` | Rok |
| `GDP` | `economies` | HDP |
| `gini` | `economies` | GINI koeficient |
| `population` | `economies` | Populace |

Filtr: pouze `continent = 'Europe'` a záznamy s nenullovým HDP.

## Výzkumné otázky – postup řešení

### Otázka 1: Rostou mzdy ve všech odvětvích?

**Postup:** Window funkce `LAG()` porovná průměrnou mzdu v roce N
s rokem N-1 pro každé odvětví. Výstup obsahuje procentuální meziroční
změnu (`payroll_growth_pct`). Záporné hodnoty indikují pokles.

**Očekávaný výsledek:** Ve většině odvětví mzdy rostou, ale existují
roky, kdy v některých odvětvích meziroční průměr poklesl.

### Otázka 2: Kolik mléka a chleba lze koupit?

**Postup:** Pro první a poslední společný rok se spočítá celostátní
průměrná mzda (průměr přes všechna odvětví) a vydělí se cenou:
- `Mléko polotučné pasterované`
- `Chléb konzumní kmínový`

Výsledek `purchasable_units` udává, kolik litrů/kg si lze za průměrnou
mzdu pořídit.

**Pozn.:** Názvy kategorií musí přesně odpovídat hodnotám
v `czechia_price_category`. Pokud se liší, je nutné je upravit.

### Otázka 3: Nejpomaleji zdražující potravina

**Postup:** Pro každou kategorii se spočítá meziroční procentuální
změna ceny, a následně průměr těchto změn přes všechny dostupné roky.
Kategorie s nejnižším průměrným růstem zdražuje nejpomaleji (nebo zlevňuje).

### Otázka 4: Rok s nárůstem cen výrazně nad růstem mezd (>10 p.p.)

**Postup:** Porovnává se celkový meziroční růst cen potravin (průměr
přes všechny kategorie) s meziročním růstem mezd (průměr přes všechna
odvětví). Filtr `difference_pct > 10` vybere roky, kde ceny rostly
o více než 10 procentních bodů rychleji.

**Očekávaný výsledek:** Takový rok nemusí existovat – prázdný výsledek
je validní odpověď znamenající, že k tak výraznému rozchodu nedošlo.

### Otázka 5: Vliv HDP na mzdy a ceny

**Postup:** Pro ČR se spočítá meziroční růst HDP z sekundární tabulky
a porovná se s růstem mezd a cen ve stejném roce i roce následujícím.
Výstup poskytuje datový podklad pro interpretaci – kauzální závěr
vyžaduje hlubší analýzu.

## Předpoklady a omezení

- SQL je psáno pro MySQL/MariaDB (použití `YEAR()` funkce).
- Finální názvy tabulek obsahují zástupné `jmeno` a `prijmeni` –
  před spuštěním je nutné nahradit skutečnými hodnotami.
- Databáze není přiložena v repozitáři; SQL nebylo ověřeno exekucí
  proti reálným datům.
- Zdrojové primární tabulky se nemodifikují – všechny transformace
  probíhají v nově vytvořených tabulkách a pohledech.

## Kde mohou chybět hodnoty

- **GINI koeficient** – v tabulce `economies` není dostupný pro všechny
  roky a země, proto se v sekundární tabulce mohou vyskytovat `NULL` hodnoty.
- **Mzdy pro některá odvětví** – data v `czechia_payroll` nemusí pokrývat
  všechny roky pro všechna odvětví.
- **Ceny některých potravin** – `czechia_price` nemusí obsahovat data za
  celé období pro všechny kategorie, protože měření probíhalo v různých
  časových řadách.
