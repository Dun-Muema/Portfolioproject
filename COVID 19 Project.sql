--Inspecting the data I have imported
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
select *
from [dbo].[CovidDeaths]
where continent is not NULL
order by 3, 4

--Select*
--from [dbo].[CovidVaccination]
--order by 3, 4

--Select Data that I will be using for the project 

select location,date,total_cases,new_cases,total_deaths, population	
from [dbo].[CovidDeaths]
where continent is not NULL
order by 1,2

-- Looking at Total Cases Vs Total Deaths which shows the likelihood of dying if you contract COVID in each country

select location,date,total_cases,total_deaths, CONVERT(float,total_deaths)/Nullif(convert (float, total_cases),0)*100 as DeathPercentage
from [dbo].[CovidDeaths]
where location like '%kenya%'and continent is not NULL
order by 1,2

--Comaprison of total cases vs population


select location,date,population,total_cases, CONVERT(float,total_cases)/Nullif(convert (float, population),0)*100 as CovidRate
from [dbo].[CovidDeaths]
--where location like '%kenya%'
order by 1,2

--Analysis Countries with highest infection rate compared to populations

select location,population,max(convert(float,total_cases))/max(Nullif(convert (float, population),0))*100 as CovidinfectionRate
from [dbo].[CovidDeaths]
--where location like '%kenya%'
Group by location, population
order by CovidinfectionRate desc

--Grouping Countries with the highest Death Count per population

select location,max(convert(float,total_deaths)) as TotalDeath
from [dbo].[CovidDeaths]
--where location like '%kenya%'
where continent is not NULL
Group by location
order by TotalDeath desc

--Breakingdown COVID deaths rate by continent 
--showing continents with the highest death count per population 

select continent,max(convert(float,total_deaths)) as TotalDeath
from [dbo].[CovidDeaths]
--where location like '%kenya%'
where continent is not NULL
Group by continent
order by TotalDeath desc

--Global Numbers

--New Cases and Deaths per day
select date, SUM(cast(new_cases as int)) as NewCasesperDay,SUM(cast(new_deaths as int)) as NewDeathsperDay,
		case
		when SUM(cast(new_cases as int)) = 0 then Null
		Else (SUM(CAST(new_deaths AS INT)) * 100.0) / NULLIF(SUM(CAST(new_cases AS INT)), 0)
	end as Deathpercentageperday
From [dbo].[CovidDeaths]
--where location like '%kenya%'
where continent is not NULL
Group by date
order by 1,2

--Covid Cases and Deaths Globally from Jan 1st 2020 to Sept 6th 2023
select  SUM(cast(new_cases as int)) as TotalCases,SUM(cast(new_deaths as int)) as TotalDeaths,
		case
		when SUM(cast(new_cases as int)) = 0 then Null
		Else (SUM(CAST(new_deaths AS INT)) * 100.0) / NULLIF(SUM(CAST(new_cases AS INT)), 0)
	end as DeathpercentageGlobally
From [dbo].[CovidDeaths]
--where location like '%kenya%'
where continent is not NULL
order by 1,2

--Vaccination Analysis

------Inspecting the Total Population Vs Total Vaccination

Select*
from [dbo].[CovidVaccination]
order by 3, 4

select Deaths.continent,Deaths.location,Deaths.date,Deaths.population,Vacc.new_vaccinations,
SUM(Convert(float, Vacc.new_vaccinations)) over (Partition by Deaths.location order by Deaths.location, Deaths.date) as RollingPeopleVaccinated
from ..CovidDeaths Deaths
join ..CovidVaccination Vacc
	on Deaths.location = Vacc.location
	and Deaths.date = Vacc.date
where Deaths.continent is not Null
order by 2,3

--using a CTE to calculate the % of vaccination vs the Population per Country

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
select Deaths.continent,Deaths.location,Deaths.date,Deaths.population,Vacc.new_vaccinations,
SUM(Convert(float, Vacc.new_vaccinations)) over (Partition by Deaths.location order by Deaths.location, Deaths.date) as RollingPeopleVaccinated
from ..CovidDeaths Deaths
join ..CovidVaccination Vacc
	on Deaths.location = Vacc.location
	and Deaths.date = Vacc.date
where Deaths.continent is not Null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac

--TEMP table 

Drop table if exists #Percentpopulation
Create Table #Percentpopulation 
(continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #Percentpopulation
select Deaths.continent,Deaths.location,Deaths.date,Deaths.population,Vacc.new_vaccinations,
SUM(Convert(float, Vacc.new_vaccinations)) over (Partition by Deaths.location order by Deaths.location, Deaths.date) as RollingPeopleVaccinated
from ..CovidDeaths Deaths
join ..CovidVaccination Vacc
	on Deaths.location = Vacc.location
	and Deaths.date = Vacc.date
where Deaths.continent is not Null
--order by 2,3

Select *, (RollingPeopleVaccinated/population)*100
from #Percentpopulation



----Creating view to store data for later visualization

create view Percentpopulation as
select Deaths.continent,Deaths.location,Deaths.date,Deaths.population,Vacc.new_vaccinations,
SUM(Convert(float, Vacc.new_vaccinations)) over (Partition by Deaths.location order by Deaths.location, Deaths.date) as RollingPeopleVaccinated
from ..CovidDeaths Deaths
join ..CovidVaccination Vacc
	on Deaths.location = Vacc.location
	and Deaths.date = Vacc.date
where Deaths.continent is not Null
--order by 2,3

select *
from Percentpopulation
