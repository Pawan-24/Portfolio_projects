USE portfolio_project;

-- select everything from covid deaths
SELECT * 
FROM covid_deaths
ORDER BY location, date;

---------------------------------------------------------------------------------------------------

-- select everything from covid vaccinations
SELECT * 
FROM covid_vaccinations
ORDER BY location, date;

---------------------------------------------------------------------------------------------------

-- Filter data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY location, date;

---------------------------------------------------------------------------------------------------

-- Looking at total cases Vs total deaths
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location LIKE 'India'
ORDER BY location, date;

---------------------------------------------------------------------------------------------------

-- Lets filter the above query 
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location = 'India'
ORDER BY date DESC
-- (The above query shows the liklihood of dying
--   if you contract covid-19 in your country(India))

---------------------------------------------------------------------------------------------------

-- Looking total cases Vs total population
SELECT 
	location, 
	date, 
	population, 
	total_cases, (total_cases/population)*100 AS Population_Affected
FROM covid_deaths
WHERE location LIKE 'India'
ORDER BY location, date;
-- Shows that 2.50 percent of popultion is affected till now 
--  due to covid in India which implies that India did manage 
--   to control covid compared to other countries

---------------------------------------------------------------------------------------------------

-- Looking at countries with highest infection rate compared to population
SELECT 
	Location, 
	population, 
	MAX(total_cases) AS Highest_count, 
	MAX((total_cases/population)*100) AS Population_Affected
FROM covid_deaths
WHERE continent IS NOT NULL --AND location = 'India' -- Just to check for India
GROUP BY location, population
ORDER BY Population_Affected DESC;

---------------------------------------------------------------------------------------------------

-- countries with the highest death count per population
SELECT location, MAX(CONVERT(int, total_deaths)) AS Total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

---------------------------------------------------------------------------------------------------

-- Lets Break things down to continents
SELECT location, MAX(CONVERT(int, total_deaths)) AS Total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- OR

SELECT continent, MAX(CONVERT(int, total_deaths)) AS Total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;
-- Thisone is giving some wrong results so i have created a temp table to give correct results

---------------------------------------------------------------------------------------------------

-- Clear view of the abobe query
DROP TABLE IF EXISTS #Death_count_per_continent
CREATE TABLE #Death_count_per_continent(
location nvarchar(100), total_death_count int)

INSERT INTO #Death_count_per_continent
SELECT location, MAX(CONVERT(int, total_deaths)) AS Total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

DELETE FROM #Death_count_per_continent
WHERE location IN 
	('upper middle income', 
	'High income', 'world', 
	'lower middle income', 
	'low income', 
	'European Union', 
	'International')

SELECT * 
FROM #Death_count_per_continent
ORDER BY total_death_count DESC
-- This also gives us the continents with the highest death count

------------------------------------------------------------------------------------------------

-- GLOBAL NUMBERS
SELECT 
	date, 
	SUM(new_cases) AS new_cases_in_world, 
	SUM(CONVERT(int,new_deaths)) AS new_deaths_in_world, 
	(SUM(CONVERT(int,new_deaths))/SUM(new_cases))*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

------------------------------------------------------------------------------------------------

-- Looking at total population Vs vaccinations
SELECT 
	d.continent, 
	d.location,
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM (CAST(v.new_vaccinations AS int)) 
	OVER (Partition By d.location ORDER BY d.location, d.date) 
	AS Rolling_population_vaccinated

FROM covid_deaths d
JOIN covid_vaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location , d.date

------------------------------------------------------------------------------------------------

--USE CTE

WITH PopVsVac(
			continent,
			location,
			date,
			population,
			new_vaccinations,
			rolling_people_vaccinated
			)
AS
		(
		SELECT 
			d.continent, 
			d.location,
			d.date, 
			d.population, 
			v.new_vaccinations,
			SUM (CAST(v.new_vaccinations AS int)) 
			OVER (Partition By d.location ORDER BY d.location, d.date) 
			AS Rolling_population_vaccinated

		FROM covid_deaths d
		JOIN covid_vaccinations v
			ON d.location = v.location
			AND d.date = v.date
		WHERE d.continent IS NOT NULL
		)
		--ORDER BY d.location , d.date

SELECT *, (rolling_people_vaccinated/population)*100
FROM PopVsVac

------------------------------------------------------------------------------------------------

-- CREATING VIEWS TO STORE DATA FOR VISUALISATION -- 


-- 1. Population Vaccinated
CREATE VIEW population_vaccinated AS
SELECT 
	d.continent, 
	d.location,
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM (CAST(v.new_vaccinations AS int)) 
	OVER (Partition By d.location ORDER BY d.location, d.date) 
	AS Rolling_population_vaccinated

FROM covid_deaths d
JOIN covid_vaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location , d.date



-- 2. Continent wise affected population
CREATE VIEW continent_pop_affected AS
SELECT location, MAX(CONVERT(int, total_deaths)) AS Total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
--ORDER BY total_death_count DESC;


-- 3. Cases Vs Deaths in India
CREATE VIEW CasesVsDeaths AS
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location LIKE 'India'
--ORDER BY location, date;


SELECT *
FROM CasesVsDeaths



--------------------------------------------------------------------------------------------------

--Stored Procedure

CREATE PROCEDURE TEST 
AS
DROP TABLE IF EXISTS #Death_count_per_continent
CREATE TABLE #Death_count_per_continent(
location nvarchar(100), total_death_count int)

INSERT INTO #Death_count_per_continent
SELECT location, MAX(CONVERT(int, total_deaths)) AS Total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

DELETE FROM #Death_count_per_continent
WHERE location IN 
	('upper middle income', 
	'High income', 'world', 
	'lower middle income', 
	'low income', 
	'European Union', 
	'International')

SELECT * 
FROM #Death_count_per_continent
ORDER BY total_death_count DESC


EXEC TEST

----------------------------------------------------------------------------------------------------