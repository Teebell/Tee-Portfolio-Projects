--select *
--from portfolioproject..CovidDeaths
--order by 3,4

--select *
--from portfolioproject..CovidVaccinations 
--order by 3,4

--Select data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject..CovidDeaths
where continent is not null
order by 1,2

--looking at total cases vs total deaths
--Shows the likelyhood of dying if you contact covid in your country
select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From portfolioproject..CovidDeaths
where location like '%states%'
--where continent is not null
order by 1,2
--Looking at Total cases vs populations
--shows percentage of populations got covid

select location, date,population,total_cases,total_deaths,(total_cases/population)*100 as DeathPercentage
From portfolioproject..CovidDeaths
where location like '%states%' and continent is not null
order by 1,2

--looking at countries with highest infection rate compareed to population
select location, population, max(total_cases) as Highestinfectioncount,
max(total_cases/population)*100 as Percentpopulationinfected
From portfolioproject..CovidDeaths
--where location like '%states%'
where continent is not null
group by location, population
order by Percentpopulationinfected desc

--This is showing the countries with the highest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount
From portfolioproject..CovidDeaths
--where location like '%states%'
where continent is not null
group by location
order by TotalDeathCount desc

--Lets break things down by Continent
-- showing continet with highest death count
select continent, Max(cast(total_deaths as int)) as TotalDeathCount
From portfolioproject..CovidDeaths
--where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc

-- Global Numbers
select sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as total_deaths,
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From portfolioproject..CovidDeaths
--where location like '%states%'
where continent is not null
--group by date 
order by 1,2
--This is joinig the 2 tables together coviddeaths and Covidvaccinations using the 
--common dataname
select *
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

--Looking at total population vs vaccination

select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	order by 2,3

--adding total new vaccination (rolling over) using partition
--the result shows the addition of each date new vaccination added together
--I had to convert to Bigint instead of int bcos sum value has 
--exceeded 2,147,483,647

select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by
dea.location,dea.date) 
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--USING CTE , Popvsvac  is our CTE in this case.

with popvsvac (Continent,Location,date,population,new_vaccinations,
rollingpeoplevaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by
dea.location,dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (rollingpeoplevaccinated/population)*100
from popvsvac

--creating Temp Table, i have used drop table incase the table exist or i make changes
--to any of the column
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
New_vaccinations numeric,
rollingpeoplevaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by
dea.location,dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (rollingpeoplevaccinated/population)*100
from #PercentPopulationVaccinated

--Creating Views to store data for later visualisations

Go
CREATE VIEW
PercentPopulationVaccinated 
as 
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by
dea.location,dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
