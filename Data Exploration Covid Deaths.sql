-- Select the data I'll be using
SELECT location, date, total_cases, total_deaths, new_cases, population 
FROM ProjectPortfolio.CovidDeaths
ORDER BY 1, 2;

-- Looking at Total cases vs Total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths::float/NULLIF(total_cases, 0))*100
FROM ProjectPortfolio.CovidDeaths
ORDER BY 1, 2;

-- Converting string characters and analyzing
-- This shows the percentage (or probability) of dying if you contract covid in Colombia 
SELECT location, date, total_cases, total_deaths, (total_deaths::float/NULLIF(total_cases, 0))*100 AS Deathpercentage
FROM ProjectPortfolio.CovidDeaths
WHERE location LIKE '%colombia%'
ORDER BY 1, 2;

-- Analizing the Total cases vs Population
-- The following lines of code show the percentage of population that got covid on 2020
SELECT location, date, total_cases, population, (total_cases::float/population)*100 AS PercentageOfCases
FROM ProjectPortfolio.CovidDeaths
WHERE location LIKE '%colombia%'
ORDER BY 1, 2;

-- What countries have the highest infection rate? A population comparison
-- According to the results, countries like Cyprus had a PercentageOfCases of over 70%. This might seem like an irrational 
-- result. But after considering that the total number of cases take into account people who get covid a second or even
-- a third time between 2020 and 2023, the results are more acceptable but not as insightful.
SELECT location, population, max(cast(total_cases as int)) AS HighestCasesCount, max((total_cases/population))*100 AS PercentageOfCases
FROM ProjectPortfolio.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentageOfCases DESC;

-- How many people died from covid? (Countries with the highest death count per population)
SELECT location, population, max(cast(total_deaths as int)) AS HighestDeathCount
FROM ProjectPortfolio.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC;

-- Now let's break it down by continent
-- The numbers in this data are incorrect as for North America, the count only includes the USA, not Canada
SELECT continent, max(cast(total_deaths as int)) AS HighestDeathCount
FROM ProjectPortfolio.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC;

-- Let's break it by location to have a more accurate number per continent
-- Europe is the continent with the highest death count followed by Asia and North America. This information is reasonable as 
-- Asia and Europe are some of the biggest continents (by population) followed by North America. Africa should be in the top three
-- population-wise, but thanks to quick action from the government and public health measures covid in Africa was less deadly
SELECT location, max(cast(total_deaths as int)) AS HighestDeathCount
FROM ProjectPortfolio.CovidDeaths
WHERE location NOT LIKE '%income%' AND continent IS NULL
GROUP BY location
ORDER BY HighestDeathCount DESC;

-- Continents with the highest death count per population 
SELECT location, population, max(cast(total_deaths as int)) AS HighestDeathCount,
max((total_deaths/population))*100 AS PercentageOfDeaths
FROM ProjectPortfolio.CovidDeaths
WHERE location NOT LIKE '%income%' AND continent IS NULL
GROUP BY location, population
ORDER BY PercentageOfDeaths DESC;

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
       SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM ProjectPortfolio.CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
-- GROUP BY date
ORDER BY 1, 2;

-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM ProjectPortfolio.CovidDeaths dea
JOIN ProjectPortfolio.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(Cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio.CovidDeaths dea
JOIN ProjectPortfolio.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(Cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio.CovidDeaths dea
JOIN ProjectPortfolio.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TEMP TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(Cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio.CovidDeaths dea
JOIN ProjectPortfolio.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;
-- WHERE dea.continent IS NOT NULL 
-- ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated;

