

use PortfolioProject;

select *
from PortfolioProject..CovidDeaths
where continent = 'asia'
order by 2,4

--select * 
--from PortfolioProject..CovidVaccination
--order by 3,4

-- select data that we are going to use.

select location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths
order by 1,2

-- for total cases vs total deaths
-- shows the likelyhood of dying if you contract covid in India.

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
from PortfolioProject..CovidDeaths
where location like 'india'
order by 1,2


-- looking at total cases vs population
-- shows what % of population got covid.

select location, date, population, total_cases, (total_cases/population)*100 as CovidPopulation 
from PortfolioProject..CovidDeaths
where location like 'india'
order by 1,2

--looking at country with highest infection rate  to pupalation

select location, population, max(cast(total_cases as int)) as MaxCases, max((total_cases/population)*100) as CovidPopulation 
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by 4 desc

-- showing countries with highest death count with population

select location, population, max(cast(total_deaths as int)) as MaxDeaths, max((cast(total_deaths as float)/population)*100) as CovidDeathPopulation 
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
--having location like 'india'
order by 3 desc

-- looking the data now by continent

select  continent
		,sum(population) as ContinentPopulation
		,sum(total_deaths) as deaths
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by 2 desc

-- looking data globally

select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths
		,sum(new_deaths)/sum(new_cases)*100 as GlobalDeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null

/*--------------------------------------------------------------------------------------------
using covidvaccination table
----------------------------------------------------------------------------------------------*/

select * from PortfolioProject..CovidVaccination
order by 3,4


-- looking at total population vs vaccinations

with popvsvac (continent, location, date, population, New_vaccination, RollingPeopleVaccinated)
as (
		select dea.continent
				, dea.location
				, dea.date
				, dea.population
				,vac.new_vaccinations
				,sum(convert(float,vac.new_vaccinations)) 
					over (partition by dea.location order by dea.location,dea.date) as TotalVac
		from PortfolioProject..CovidDeaths dea
		join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		and vac.new_vaccinations is not null
		--order by 2,3
	)
select *, (RollingPeopleVaccinated/population)*100 per_vaccinated
from popvsvac
order by 2,3

-- creating a TEMP table for the same (above) output... i.e totalpopulation and vaccination

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
	continent nvarchar(250)
	, location nvarchar(250)
	, [date] datetime
	, population float
	, New_vaccination float
	, RollingPeopleVaccinated float
)
insert into #PercentPopulationVaccinated
	select dea.continent
				, dea.location
				, dea.date
				, dea.population
				,vac.new_vaccinations
				,sum(convert(float,vac.new_vaccinations)) 
					over (partition by dea.location order by dea.location,dea.date) as TotalVac
		from PortfolioProject..CovidDeaths dea
		join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		and vac.new_vaccinations is not null

select *, (RollingPeopleVaccinated/population)*100 per_vaccinated
from #PercentPopulationVaccinated


/*-----------------------------------------------------------------------------
	CREATING VIEWS FOR THE VISUALIZATION
-----------------------------------------------------------------------------*/

-- 1. VIEW FOR CASES VS DEATH i.e Case_Death

create view Case_Death as
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
from PortfolioProject..CovidDeaths
where continent is not null

-- running view
select * 
from case_death

-- 2. view for Population and case i.e PopulationVsCase

create view PopulationVsCase as
select location, date, population, total_cases, (total_cases/population)*100 as CovidPopulation 
from PortfolioProject..CovidDeaths
where continent is not null


-- running the view
/* Below query shows the peak of each country and for how long that peak existed. */

select location,date, CovidPopulation as PeakCovidPopulation
from PopulationVsCase
where CovidPopulation in (select max(CovidPopulation) from PopulationVsCase group by location)
order by 1,3

-- 3. view for Population vs death i.e PopulationDeath

create view PopulationDeath as
select location, population, max(cast(total_deaths as int)) as MaxDeaths, max((cast(total_deaths as float)/population)*100) as CovidDeathPopulation 
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population

-- checking the above view for the top 10 countries where deaths are maximum.
select top 10 *
from PopulationDeath
order by 3 desc

--4. view for geting the detail of continent

create view ContinentDetail as
select  continent
		,sum(population) as ContinentPopulation
		,sum(total_deaths) as deaths
from PortfolioProject..CovidDeaths
where continent is not null
group by continent

-- checking the continent detail
select * from ContinentDetail


--5. Global Detail

create view GlobalDetail as
select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths
		,sum(new_deaths)/sum(new_cases)*100 as GlobalDeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null

-- checking the GlobalDetail view
select * from GlobalDetail


--6. View for Vaccination detail of each country

create view CountryVaccination as
with popvsvac (continent, location, date, population, New_vaccination, RollingPeopleVaccinated)
as (
		select dea.continent
				, dea.location
				, dea.date
				, dea.population
				,vac.new_vaccinations
				,sum(convert(float,vac.new_vaccinations)) 
					over (partition by dea.location order by dea.location,dea.date) as TotalVac
		from PortfolioProject..CovidDeaths dea
		join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		and vac.new_vaccinations is not null
		
	)
select *, (RollingPeopleVaccinated/population)*100 per_vaccinated
from popvsvac

-- checking the CountryVaccination view
select location
		, population
		, sum(cast(New_vaccination as float)) Vaccinated_Population
		, max(per_vaccinated) PercentagePopulationVaccinated
from CountryVaccination
group by location, population
order by location, population