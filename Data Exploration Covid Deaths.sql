-- Select the data I'll be using

select location, date, total_cases, total_deaths, new_cases, population 
from ProjectPortfolio..CovidDeaths$
order by 1,2

-- Looking at Total cases vs Total deaths

select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases), 0))*100
from ProjectPortfolio..CovidDeaths$
order by 1,2

-- Converting string characters and analyzing
-- This shows the percentage (or probability) of dying if you contract covid in Colombia 
Select location, date, total_cases,total_deaths, (CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases), 0))*100 AS Deathpercentage
from ProjectPortfolio..CovidDeaths$
where location like '%colombia%'
order by 1,2

-- Analizing the Total cases vs Population
-- The following lines of code show the percentage of population that got covid on 2020
Select location, date, total_cases, population, (total_cases/population)*100 AS PercentageOfCases
from ProjectPortfolio..CovidDeaths$
where location like '%colombia%'
order by 1,2

-- What countries have the highest infection rate? A population comparison
-- According to the results, countries like Cyprus had a PercentageOfCases of over 70%. This might seem like an irrational 
-- result. But after considering that the total number of cases take into account people who get covid a second or even
-- a third time between 2020 and 2023, the results are more acceptable but not as insightful.
Select location, population, max(cast(total_cases as int)) as HighestCasesCount, max((total_cases/population))*100 as PercentageOfCases
from ProjectPortfolio..CovidDeaths$
where continent is not null
group by location, population
order by PercentageOfCases desc


-- How many people died from covid? (Countries with the highest death count per population)
-- 
Select location, population, max(cast(total_deaths as int)) as HighestDeathCount
from ProjectPortfolio..CovidDeaths$
where continent is not null
group by location, population
order by HighestDeathCount desc

-- Now let's break it donw by continent
-- The numbers in this data are incorrect as for North America, the count only includes the USA, not Canada
Select continent, max(cast(total_deaths as int)) as HighestDeathCount
from ProjectPortfolio..CovidDeaths$
where continent is not null
group by continent
order by HighestDeathCount desc

-- Let's break it by location to have a more accurate number per continent
-- Europe is the continent with the highest death count followed by Asia and North America. This information is reasonable as 
-- Asia and Europe are some of the biggest continents (by population) followed by North America. Africa should be in the top three
-- population-wise, but thanks to quick action from the goverment and public health measures covid in Africa was less deadly
Select location, max(cast(total_deaths as int)) as HighestDeathCount
from ProjectPortfolio..CovidDeaths$
where location not like '%income%' and continent is null
group by location
order by HighestDeathCount desc

-- Continents with the highest death count per population 
Select location, population, max(cast(total_deaths as int)) as HighestDeathCount,
max((total_deaths/population))*100 as PercentageOfDeaths
from ProjectPortfolio..CovidDeaths$
where location not like '%income%' and continent is null
group by location, population
order by PercentageOfDeaths desc

--GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From ProjectPortfolio..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Shows Percentage of Population that has received at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
