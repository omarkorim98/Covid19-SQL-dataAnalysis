-- Percentage of total cases vs total deaths
-- Shows likelihood of cases or dying if you contract covid in your country
SELECT location,date,total_cases,total_deaths,( total_deaths/ total_cases) * 100 as Deaths_percentage
FROM Covid19..CovidDeaths$
WHERE total_deaths is not null 
AND location like '%egypt%'
ORDER BY 1, 2 

-- Percentage of total cases vs population
SELECT Location, date, population, total_cases, (total_cases/population) * 100 as cases_percentage
FROM Covid19..CovidDeaths$
ORDER BY 1,2 

-- Highest Infection Cases Per Population
SELECT location,MAX(total_cases) largest_cases, MAX((total_cases/population) * 100 ) largest_cases_percentage
FROM Covid19..CovidDeaths$
--WHERE location like '%egypt%'
GROUP BY location
ORDER BY largest_cases_percentage DESC

-- Highest Deaths Cases Per Cases
SELECT location,MAX(cast(total_deaths as int)) largest_deaths, MAX((cast(total_deaths as int)/total_cases) * 100 ) largest_deaths_percentage
FROM Covid19..CovidDeaths$
--WHERE location like '%egypt%'
GROUP BY location
ORDER BY largest_deaths_percentage DESC


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid19..CovidDeaths$
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

--Total Deaths per Continent
SELECT continent,MAX(cast(total_deaths as int)) as TotalDeathCount 
FROM Covid19..CovidDeaths$
Where continent is not null
Group By continent
ORDER BY 2 DESC


-- GLOBAL NUMBERS

-- Total Deaths Percentage
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid19..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Convert(int,vac.new_vaccinations)) Over (Partition By dea.location order by dea.location, dea.date)rolling_people_vaccinated
FROM Covid19..CovidDeaths$ dea 
JOIN Covid19..CovidVaccinations$ vac
  ON dea.location= vac.location
  and dea.date=vac.date
where dea.continent is not null
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query
with vacVspop(continent,location, date, population, new_vaccination,rolling_people_vaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Convert(int,vac.new_vaccinations)) Over (Partition By dea.location order by dea.location, dea.date)rolling_people_vaccinated
FROM Covid19..CovidDeaths$ dea 
JOIN Covid19..CovidVaccinations$ vac
  ON dea.location= vac.location
  and dea.date=vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (rolling_people_vaccinated/population) * 100 as vac_pop_percentage
From vacVspop



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
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19..CovidDeaths$ dea
Join Covid19..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100  vac_pop_percentage
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19..CovidDeaths$ dea
Join Covid19..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
