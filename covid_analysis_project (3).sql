-- ============================================================
-- COVID-19 Data Analysis Project
-- Author  : Rhytham suri
-- Tool    : MySQL
-- Data    : Our World in Data — CovidDeaths & CovidVaccinations
-- ============================================================
use company5;

-- ============================================================
-- SECTION 1 : GLOBAL DEATH ANALYSIS
-- ============================================================

-- How many people died out of confirmed cases each day, per country?
SELECT
    location,
    date,
    continent,
    new_cases,
    new_deaths,
    ROUND((new_deaths / new_cases) * 100) AS daily_death_percentage
FROM covid_deaths2;


-- What is the total worldwide cases, deaths and overall death percentage?
-- continent IS NOT NULL removes OWID summary rows like "World" or "Asia"
-- which would double-count the numbers.
SELECT
    SUM(new_cases)                           AS total_cases,
    SUM(new_deaths)                          AS total_deaths,
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS global_death_percentage
FROM covid_deaths2
WHERE continent IS NOT NULL;


-- ============================================================
-- SECTION 2 : REGIONAL TREND ANALYSIS
-- ============================================================

-- What were the peak cases per country per year in Europe?
SELECT
    continent,
    location,
    YEAR(date)        AS year,
    MAX(population)   AS population,
    MAX(total_cases)  AS peak_total_cases,
    MAX(new_cases)    AS peak_new_cases
FROM coviddeaths
WHERE continent = 'Europe'
GROUP BY continent, location, YEAR(date);


-- Which continent had the most cases each year?
SELECT
    continent,
    YEAR(date)       AS year,
    MAX(total_cases) AS peak_total_cases
FROM covid_deaths2
GROUP BY continent, YEAR(date)
ORDER BY continent, YEAR(date);


-- ============================================================
-- SECTION 3 : MONTHLY TIME-SERIES
-- ============================================================

-- How many new cases were reported globally each month?
SELECT
    YEAR(date)     AS year,
    MONTH(date)    AS month,
    SUM(new_cases) AS monthly_cases
FROM coviddeaths
GROUP BY YEAR(date), MONTH(date)
ORDER BY YEAR(date), MONTH(date);


-- How did the global case count build up month by month (running total)?
-- The inner query calculates monthly totals first.
-- The outer query adds them up cumulatively using a window function
-- so we can see the total pandemic growth over time.
SELECT
    year,
    month,
    SUM(monthly_cases) OVER (ORDER BY year, month) AS running_total_cases
FROM (
    SELECT
        YEAR(date)     AS year,
        MONTH(date)    AS month,
        SUM(new_cases) AS monthly_cases
    FROM coviddeaths
    GROUP BY YEAR(date), MONTH(date)
) AS monthly_aggregates;


-- ============================================================
-- SECTION 4 : VACCINATION ANALYSIS
-- ============================================================

-- How many vaccinations were given in India each day,
-- and what is the running total of vaccinations so far?
-- We join the deaths table (for population) with the vaccinations
-- table on location + date, then use a window function to keep
-- a running sum that resets for each country.
SELECT
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations)
        OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_vaccinations
FROM covid_deaths2       AS cd
JOIN covid_vaccinations2 AS cv
    ON cd.location = cv.location
    AND cd.date    = cv.date
WHERE cd.location = 'India';


-- What percentage of India's population was vaccinated on each day?
-- A CTE (named temporary result) first builds the rolling vaccination count.
-- Then the outer query divides it by population to get the daily percentage.
WITH rolling AS (
    SELECT
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(cv.new_vaccinations)
            OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_vaccinations
    FROM covid_deaths2       AS cd
    JOIN covid_vaccinations2 AS cv
        ON cd.location = cv.location
        AND cd.date    = cv.date
)
SELECT
    *,
    (rolling_vaccinations / population) * 100 AS vaccination_percentage
FROM rolling
WHERE location = 'India';


-- Save the above logic as a view so we can reuse it for any country
-- without rewriting the whole query every time.
-- Usage: SELECT * FROM rolling_vaccinations WHERE location = 'United States';
CREATE VIEW rolling_vaccinations AS
WITH rolling AS (
    SELECT
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(cv.new_vaccinations)
            OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_vaccinations
    FROM covid_deaths2       AS cd
    JOIN covid_vaccinations2 AS cv
        ON cd.location = cv.location
        AND cd.date    = cv.date
)
SELECT
    *,
    (rolling_vaccinations / population) * 100 AS vaccination_percentage
FROM rolling;


-- ============================================================
-- SECTION 5 : ADVANCED QUERIES
-- ============================================================

-- Which country had the most deaths within each continent?
-- RANK() numbers countries from 1 (worst) to last (least) inside
-- each continent separately using PARTITION BY.
SELECT
    continent,
    location,
    MAX(total_deaths) AS peak_total_deaths,
    RANK() OVER (
        PARTITION BY continent
        ORDER BY MAX(total_deaths) DESC
    ) AS rank_within_continent
FROM covid_deaths2
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY continent, rank_within_continent;


-- Did cases go up or down compared to the previous day?
-- LAG() fetches the previous day's value so we can subtract it
-- from today and calculate how much cases changed and by what %.
SELECT
    location,
    date,
    new_cases,
    LAG(new_cases) OVER (PARTITION BY location ORDER BY date) AS yesterday_cases,
    new_cases - LAG(new_cases) OVER (PARTITION BY location ORDER BY date) AS change_vs_yesterday,
    ROUND(
        (new_cases - LAG(new_cases) OVER (PARTITION BY location ORDER BY date))
        / NULLIF(LAG(new_cases) OVER (PARTITION BY location ORDER BY date), 0) * 100
    , 2) AS growth_rate_pct
FROM covid_deaths2
WHERE continent IS NOT NULL
ORDER BY location, date;


-- What is the 7-day rolling average of new cases per country?
-- Instead of one noisy daily number, we average the last 7 days
-- to get a smoother trend — the same method used by WHO and CDC.
-- ROWS BETWEEN 6 PRECEDING AND CURRENT ROW sets the 7-day window.
SELECT
    location,
    date,
    new_cases,
    ROUND(
        AVG(new_cases) OVER (
            PARTITION BY location
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )
    , 2) AS seven_day_avg
FROM covid_deaths2
WHERE continent IS NOT NULL
ORDER BY location, date;


-- How deadly was COVID in each country?
-- Infection rate = % of population that caught COVID.
-- Case Fatality Rate (CFR) = % of infected people who died.
-- CASE labels each country as High / Medium / Low based on CFR.
SELECT
    location,
    MAX(population)                                         AS population,
    MAX(total_cases)                                        AS total_cases,
    MAX(total_deaths)                                       AS total_deaths,
    ROUND((MAX(total_cases)  / MAX(population))  * 100, 4) AS infection_rate_pct,
    ROUND((MAX(total_deaths) / MAX(total_cases)) * 100, 4) AS case_fatality_rate_pct,
    CASE
        WHEN (MAX(total_deaths) / MAX(total_cases)) * 100 >= 3 THEN 'High CFR'
        WHEN (MAX(total_deaths) / MAX(total_cases)) * 100 >= 1 THEN 'Medium CFR'
        ELSE 'Low CFR'
    END AS cfr_category
FROM covid_deaths2
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY case_fatality_rate_pct DESC;


-- Did higher vaccination rates lead to fewer deaths?
-- We join both tables and label each country into one of 4 buckets
-- based on whether they had high/low vaccination AND high/low deaths.
SELECT
    cd.location,
    cd.continent,
    MAX(cv.people_fully_vaccinated_per_hundred) AS fully_vaccinated_pct,
    MAX(cd.total_deaths_per_million)            AS deaths_per_million,
    CASE
        WHEN MAX(cv.people_fully_vaccinated_per_hundred) >= 60
             AND MAX(cd.total_deaths_per_million) < 1000  THEN 'Well Vaccinated, Low Deaths'
        WHEN MAX(cv.people_fully_vaccinated_per_hundred) >= 60
             AND MAX(cd.total_deaths_per_million) >= 1000 THEN 'Well Vaccinated, High Deaths'
        WHEN MAX(cv.people_fully_vaccinated_per_hundred) < 60
             AND MAX(cd.total_deaths_per_million) < 1000  THEN 'Low Vax, Low Deaths'
        ELSE                                                   'Low Vax, High Deaths'
    END AS category
FROM covid_deaths2       AS cd
JOIN covid_vaccinations2 AS cv
    ON cd.location = cv.location
    AND cd.date    = cv.date
WHERE cd.continent IS NOT NULL
GROUP BY cd.location, cd.continent
ORDER BY fully_vaccinated_pct DESC;


-- What were the 5 deadliest single days for each country?
-- DENSE_RANK() ranks each day by deaths inside each country.
-- We put it in a subquery and keep only rank 1 to 5.
SELECT *
FROM (
    SELECT
        location,
        date,
        new_deaths,
        DENSE_RANK() OVER (
            PARTITION BY location
            ORDER BY new_deaths DESC
        ) AS death_rank
    FROM covid_deaths2
    WHERE continent IS NOT NULL
) AS ranked
WHERE death_rank <= 5
ORDER BY location, death_rank;


-- Which 25% of countries were hit the hardest?
-- NTILE(4) splits all countries into 4 equal groups by death count.
-- Group 1 = least affected 25%, Group 4 = worst hit 25%.
SELECT
    location,
    MAX(total_deaths) AS peak_deaths,
    NTILE(4) OVER (
        ORDER BY MAX(total_deaths) DESC
    ) AS death_quartile
FROM covid_deaths2
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY death_quartile, peak_deaths DESC;


-- When did each country first reach 1 million total cases?
-- MIN(date) with a filter finds the exact day each country crossed
-- the milestone. Earlier dates show the first epicentres of the pandemic.
SELECT
    location,
    continent,
    MIN(date) AS date_crossed_1_million_cases
FROM covid_deaths2
WHERE total_cases >= 1000000
  AND continent IS NOT NULL
GROUP BY location, continent
ORDER BY date_crossed_1_million_cases;


-- A stored procedure that gives a full COVID summary for any country.
-- Write it once, call it for any country — no rewriting needed.
-- Usage: CALL GetCountrySummary('India');
--        CALL GetCountrySummary('Brazil');
DELIMITER $$

CREATE PROCEDURE GetCountrySummary(IN country_name VARCHAR(100))
BEGIN
    SELECT
        cd.location,
        MAX(cd.population)                                            AS population,
        MAX(cd.total_cases)                                           AS total_cases,
        MAX(cd.total_deaths)                                          AS total_deaths,
        ROUND((MAX(cd.total_deaths) / MAX(cd.total_cases)) * 100, 2) AS case_fatality_rate_pct,
        MAX(cv.people_fully_vaccinated_per_hundred)                   AS fully_vaccinated_pct,
        MAX(cv.total_vaccinations)                                    AS total_vaccinations
    FROM covid_deaths2       AS cd
    JOIN covid_vaccinations2 AS cv
        ON cd.location = cv.location
        AND cd.date    = cv.date
    WHERE cd.location = country_name;
END$$

DELIMITER ;

-- Run it like this:
CALL GetCountrySummary('India');
