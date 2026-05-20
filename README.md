# 🦠 COVID-19 Data Analysis with SQL

A complete end-to-end SQL project exploring global COVID-19 deaths and vaccinations using MySQL. The analysis covers everything from basic death percentages to advanced window functions, CTEs, and stored procedures.

---

## 📁 Dataset

| File | Description |
|---|---|
| `covid_deaths2.csv` | Daily cases, deaths, hospitalizations by country |
| `covid_vaccinations2.csv` | Daily vaccinations, testing, and demographic data |

**Source:** [Our World in Data (OWID)](https://ourworldindata.org/covid-deaths)  
**Coverage:** Global · Jan 2020 – 2021

---

## 🛠️ Tools Used

- **MySQL 8.0**
- **MySQL Workbench**

---

## 📊 What This Project Covers

### 1 · Global Death Analysis
- Daily death percentage per country (deaths ÷ confirmed cases)
- Worldwide total cases, total deaths, and overall death rate

### 2 · Regional Trend Analysis
- Year-wise peak cases per country in Europe
- Continental case comparison across years

### 3 · Monthly Time-Series
- Global new cases grouped by month
- Cumulative running total of cases over time using window functions

### 4 · Vaccination Analysis
- Daily rolling vaccination count per country (India focus)
- Cumulative vaccination percentage of population using CTEs
- Reusable `rolling_vaccinations` VIEW for any country

### 5 · Advanced Queries
| Query | Technique Used |
|---|---|
| Country death rankings within each continent | `RANK()` + `PARTITION BY` |
| Day-over-day case growth | `LAG()` window function |
| 7-day rolling average of new cases | `AVG() OVER` with sliding frame |
| Infection rate vs case fatality rate per country | Multi-metric aggregation + `CASE` |
| Vaccination coverage vs death rate comparison | `JOIN` + 4-category `CASE` labeling |
| Top 5 deadliest days per country | `DENSE_RANK()` + subquery |
| Countries bucketed into death quartiles | `NTILE(4)` |
| First date each country crossed 1 million cases | `MIN(date)` milestone tracking |
| Full country summary on demand | Stored Procedure (`CALL`) |

---

## 💡 Key SQL Concepts Demonstrated

- **Window Functions** — `RANK()`, `DENSE_RANK()`, `LAG()`, `NTILE()`, `AVG() OVER`, `SUM() OVER`
- **CTEs** — Clean, readable multi-step logic with `WITH`
- **Stored Procedures** — Parameterised, reusable queries
- **Views** — Saved query logic for repeated use
- **Joins** — Combining deaths and vaccinations tables on location + date
- **CASE statements** — Classifying countries into risk/performance categories
- **NULLIF** — Safe division to avoid divide-by-zero errors
- **Subqueries** — Feeding aggregated results into window functions

---

## 🚀 How to Run

1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/covid-sql-analysis.git
   ```

2. Open **MySQL Workbench** and connect to your local server

3. Download the CSV files from [OWID](https://ourworldindata.org/covid-deaths) and place them in your MySQL upload directory:
   ```
   C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
   ```

4. Run the SQL file
   ```sql
   SOURCE covid_analysis_project.sql;
   ```

5. To call the stored procedure for any country:
   ```sql
   CALL GetCountrySummary('India');
   CALL GetCountrySummary('United States');
   ```

---

## 📌 Sample Insights

- 🌍 The **global case fatality rate** across the dataset period was approximately **2.1%**
- 💉 Countries with **60%+ full vaccination** generally showed significantly lower deaths per million
- 📈 The **7-day moving average** reveals wave patterns clearly invisible in raw daily data
- 🏆 Using `RANK()`, we can instantly see which country was the worst hit **within each continent**

---

## 📂 Project Structure

```
covid-sql-analysis/
│
├── covid_analysis_project.sql   # All queries — analysis + advanced
├── README.md                    # This file
└── data/
    ├── covid_deaths2.csv        # Source data (download from OWID)
    └── covid_vaccinations2.csv  # Source data (download from OWID)
```

 🙋 Author= RHYTHAM SURI
[LinkedIn]= https://www.linkedin.com/in/rhytham-suri-990799206/

---

## 📜 License

This project is open source under the [MIT License](LICENSE).
