SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in Vietnam
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS decimal(10,2))/CAST(total_cases AS int))*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam' AND continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (CAST(total_cases AS decimal(10,2))/population)*100 AS cases_percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam' AND continent IS NOT NULL
ORDER BY 1,2;

--Looking at Countries with Highest Infection Rate compared to Population
WITH CTE_InfectionRate AS(
SELECT location, population, MAX(CAST(total_cases AS float)) AS HighestInfectionCount, MAX(CAST(total_cases AS float)/population)*100 AS MaxInfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
)
SELECT *, (HighestInfectionCount/population)*100 AS CheckMaxInfectionRate
FROM CTE_InfectionRate
ORDER BY MaxInfectionRate DESC

--Showing Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS bigint)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--Let's break things down by continent
--Showing continents with the highest death count
SELECT location, MAX(CAST(total_deaths AS bigint)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--Global number
SELECT SUM(ISNULL(new_cases,0)) AS total_cases, 
	SUM(ISNULL(new_deaths,0)) AS total_deaths,
	CASE WHEN SUM(ISNULL(new_cases,0)) = 0 THEN NULL ELSE SUM(ISNULL(new_deaths,0))/SUM(ISNULL(new_cases,0))*100 END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1

--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS VaccinationsOverDate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Use CTE
WITH CTE_PercentVaccinationsPopulation AS(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS VaccinationsOverDate
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, VaccinationsOverDate/population*100 AS PercentVaccinationsPopulation
FROM CTE_PercentVaccinationsPopulation
ORDER BY 2,3

--Use Temp table
DROP TABLE IF EXISTS #Temp_PercentVaccinationsPopulation
CREATE TABLE #Temp_PercentVaccinationsPopulation(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population float,
	new_vaccinations nvarchar(255),
	VaccinationsOverDate bigint
)
INSERT INTO #Temp_PercentVaccinationsPopulation
SELECT *
FROM (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS VaccinationsOverDate
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
) AS A

SELECT *, VaccinationsOverDate/population*100 AS PercentVaccinationsPopulation
FROM #Temp_PercentVaccinationsPopulation
ORDER BY 2,3

--Create view for later visullization
CREATE VIEW PercentVaccinationsPopulation
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS VaccinationsOverDate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL