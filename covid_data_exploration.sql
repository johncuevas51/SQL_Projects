DROP TABLE Covid_Deaths ;
DROP TABLE Covid_Vaccinations ;

SELECT *
FROM Covid_Deaths
WHERE continent is not null
order by 3,4;

SELECT *
FROM covid_vaccinations ;

-- select data I will use 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Deaths
order by 1,2;

-- Looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid
SELECT location, date, total_cases, total_deaths, (cast(total_deaths as decimal )/total_cases)*100 as death_percentage
FROM covid_deaths
WHERE location like '%States%'
order by 1,2;

-- look at total cases vs population 
SELECT location, date, total_cases, population, (cast(total_cases as decimal )/population)*100 as percent_population_infected
FROM covid_deaths
WHERE location like '%States%'
order by 1,2;

-- looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((cast(total_cases as decimal )/population))*100 as percent_population_infected
FROM covid_deaths
--WHERE location like '%States%'
GROUP BY location, population
order by percent_population_infected desc;


--showing countries with highest death count per population
SELECT location, MAX(CAST(total_deaths as int)) as total_death_count
FROM covid_deaths
--WHERE location like '%States%'
WHERE continent is not null
GROUP BY location
order by total_death_count desc;


-- LET'S BREAK IT DOWN BY CONTINENT



-- STOPPED VIDEO AT 41:01/1:17:08 MIN. RESUME AND FINISH PROJECT.
SELECT continent, MAX(CAST(total_deaths as int)) as total_death_count
FROM covid_deaths
--WHERE location like '%States%'
WHERE continent is not null
GROUP BY continent
order by total_death_count desc;


-- GLOBAL NUMBERS
SELECT date, 
SUM(new_cases) as total_cases, 
SUM(new_deaths) as total_deaths, 
CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE SUM(CAST(new_deaths as decimal))/SUM(new_cases)*100 END as death_percentage
FROM covid_deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;


--total
SELECT 
SUM(new_cases) as total_cases, 
SUM(new_deaths) as total_deaths, 
CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE SUM(CAST(new_deaths as decimal))/SUM(new_cases)*100 END as death_percentage
FROM covid_deaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2;

-- looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, 
dea.date) as rolling_ppl_vaccinated
--(rolling_ppl_vaccinated/population)*100 cannot use a column that we just created thus we use a CTE/temp table
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;


--USE CTE
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_ppl_vaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, 
dea.date) as rolling_ppl_vaccinated
--(rolling_ppl_vaccinated/population)*100 cannot use a column that we just created thus we use a CTE/temp table
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (rolling_ppl_vaccinated/population)*100
FROM popvsvac



-- Temp table option 

DROP TABALE IF EXIST percent_population_vaccinated

CREATE TEMPORARY TABLE percent_population_vaccinated(
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccinations numeric,
rolling_ppl_vaccinated numeric
);

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, 
dea.date) as rolling_ppl_vaccinated
--(rolling_ppl_vaccinated/population)*100 cannot use a column that we just created thus we use a CTE/temp table
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null;
--ORDER BY 2,3

SELECT *, (rolling_ppl_vaccinated/population)*100
FROM percent_population_vaccinated;

--create view to store data for later visualizations
CREATE VIEW percent_population_vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, 
dea.date) as rolling_ppl_vaccinated
--(rolling_ppl_vaccinated/population)*100 cannot use a column that we just created thus we use a CTE/temp table
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null;
--ORDER BY 2,3
