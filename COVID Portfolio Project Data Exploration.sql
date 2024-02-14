SELECT TOP 5 *
FROM PortfolioProject..CovidDeaths ORDER BY Location

SELECT TOP 5 *
FROM PortfolioProject..CovidVaccinations

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
ORDER BY 3, 4

-- Select data that we are going to be using:
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
SELECT Location, Date, Total_cases, Total_deaths, 
CASE
	WHEN total_cases = 0 THEN NULL
	ELSE (total_deaths/total_cases)*100
END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%' AND continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
ORDER BY 1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT Location, Date, Population, Total_cases, 
CASE
	WHEN Population = 0 THEN NULL
	ELSE (Total_cases/Population)*100
END AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
ORDER BY 1, 2

-- Looking at countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(Total_cases) as HighestInfectionCount,
CASE
	WHEN Population = 0 THEN NULL
	ELSE MAX((Total_cases/ NULLIF(Population, 0))) * 100
END AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing the Countries with Highest Death Count per Population
SELECT Location, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Let's break this by down by CONTINENT

-- Showing continents with the highest death count per population
SELECT Continent, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL AND LTRIM(RTRIM(Continent)) <> ''
GROUP BY Continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
SELECT Date, SUM(New_cases) AS Total_Cases, SUM(New_deaths) AS Total_Deaths,
CASE
	WHEN SUM(New_cases) = 0 THEN NULL
	ELSE (SUM(New_deaths)/NULLIF(SUM(New_cases), 0))*100
END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
GROUP BY Date
ORDER BY 1, 2

SELECT SUM(New_cases) AS Total_Cases, SUM(New_deaths) AS Total_Deaths,
CASE
	WHEN SUM(New_cases) = 0 THEN NULL
	ELSE (SUM(New_deaths)/NULLIF(SUM(New_cases), 0))*100
END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
ORDER BY 1, 2

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as int) AS new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.Location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND LTRIM(RTRIM(dea.continent)) <> ''
ORDER BY 2, 3

-- Use CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollinPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as int) AS New_Vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.Location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND LTRIM(RTRIM(dea.continent)) <> ''
)
SELECT *, 
CASE
	WHEN Population = 0 THEN NULL
	ELSE (RollinPeopleVaccinated/Population)*100
END AS RP
FROM PopvsVac

-- TEMP Table

--DROP TABLE IF EXISTS #PercentPopulationVaccinated

IF OBJECT_ID('PortfolioProject..#PercentPopulationVaccinated') IS NOT NULL
	DROP TABLE #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent varchar(50), 
Location varchar(50), 
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollinPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as int) AS New_Vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.Location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND LTRIM(RTRIM(dea.continent)) <> ''

SELECT *, 
CASE
	WHEN Population = 0 THEN NULL
	ELSE (RollinPeopleVaccinated/Population)*100
END AS RP
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as int) AS New_Vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.Location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND LTRIM(RTRIM(dea.continent)) <> ''

SELECT *
FROM PercentPopulationVaccinated