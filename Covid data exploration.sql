--Covid deaths data exploration
--selecting top 1000 rows
SELECT TOP 1000 * FROM CovidDeaths_csv$ 
select  Top 1000 * from CovidVaccination_csv$



--All the column present in covid deaths dataset
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths_csv$'



--Looking at population vs total cases based on countries
select continent,location,population, max(cast(total_cases as int)) as TotalCovid19_cases
from CovidDeaths_csv$
where continent is not null
group by continent,location,population
order by TotalCovid19_cases desc;



--calculating percentage of population infected across different countries
select location, population, max(cast(total_cases as int)) as TotalCovid19_cases, (max(cast(total_cases as int)/population))*100 as PercentPopulationInfected 
from CovidDeaths_csv$
where continent is not null
group by location, population
order by PercentPopulationInfected desc;



--Looking at countries where the population is more than 20 cr
select location, population, max(cast(total_cases as int)) as TotalCovid19_cases, (max(cast(total_cases as int)/population))*100 as PercentPopulationInfected 
from CovidDeaths_csv$
where continent is not null
group by location, population
having population > 200000000
order by PercentPopulationInfected desc;



--Looking at peak covid 19 period in different countries
WITH MaxNewCasesByLocation AS (
    SELECT location, MAX(new_cases) AS max_new_cases
    FROM CovidDeaths_csv$
	where continent is not null
    GROUP BY location
	having max(new_cases) !=0
)

SELECT 
    cd.location, 
    CONCAT(DATENAME(MONTH, cd.date), ' ', YEAR(cd.date)) AS peak_period, 
    cd.population, 
    cd.new_cases AS MaxCasesRegistered
FROM CovidDeaths_csv$ cd
JOIN MaxNewCasesByLocation m ON cd.location = m.location AND cd.new_cases = m.max_new_cases
ORDER BY MaxCasesRegistered DESC;


--Looking at population vs total deaths based on countries
select continent, location, population, max(cast(total_deaths as int)) as Totalcovid19_deaths
from CovidDeaths_csv$
where continent is not null
group by continent, location, population
order by Totalcovid19_deaths desc


--calculating percentage of population died across different countries due to covid 19
select location, population, max(cast(total_deaths as int)) as TotalCovid19_deaths, (max(cast(total_deaths as int)/population))*100 as PercentPopulation_Died
from CovidDeaths_csv$
where continent is not null
group by location, population
order by PercentPopulation_Died desc;



--calculating the percentage of total cases died across different countries
select location, population, max(cast(total_cases as int)) as total_cases,max(cast(total_deaths as int)) as total_deaths,
max(cast(total_deaths as int))*100.0/max(cast(total_cases as int)) as Death_rate
from CovidDeaths_csv$
where continent is not null 
group by location, population
order by  Death_rate desc;


--Looking at new_cases and new_deaths
select location, date,population, new_cases,new_deaths,Round((new_deaths/new_cases),3) as death_rate
from CovidDeaths_csv$
where new_cases >0 and continent is not null
order by location,date;


--Global numbers grouped by date
select date, sum(new_cases) as Total_cases, sum(new_deaths) as Total_deaths
from CovidDeaths_csv$
where continent is not null
group by date
order by date desc


--Looking at average reproduction rate of different countries
select location, population, max(cast(total_cases as int)) as Total_cases, round(avg(cast(reproduction_rate as float)),3) as Avg_ReproductionRate
,case 
when round(avg(cast(reproduction_rate as float)),3)>1 then 'High'
when round(avg(cast(reproduction_rate as float)),3) is Null then 'N/A'
else 'low'
end
as RepRate_classification
from CovidDeaths_csv$
where continent is not null
group by location, population
order by location;



--Classifying reprate as High and Low
with RepRate
as
(select location, population, max(cast(total_cases as int)) as Total_cases, round(avg(cast(reproduction_rate as float)),3) as Avg_ReproductionRate
,case 
when round(avg(cast(reproduction_rate as float)),3)>1 then 'High'
when round(avg(cast(reproduction_rate as float)),3) is Null then 'N/A'
else 'low'
end
as RepRate_classification
from CovidDeaths_csv$
where continent is not null
group by location, population
--order by location;
)


--Count of reprate classification
select RepRate_classification,count(RepRate_classification) AS NumberOfCountries
from RepRate
group by RepRate_classification



--Looking at new cases and new tests
select dth.continent,dth.location,dth.date,max(cast(vcn.new_tests as int)) as new_tests,max(cast(dth.new_cases as int)) as new_cases
from CovidDeaths_csv$ Dth
join CovidVaccination_csv$ vcn
on dth.date=vcn.date
where dth.continent is not null 
group by dth.continent, dth.location, dth.date
order by dth.location,dth.date;


--Comparing countries with respect to Human Development Index(HDI)
select dth.location,dth.population,vcn.human_development_index,max(cast(dth.total_cases as int)) as total_cases,
max(cast(dth.total_deaths as int)) as total_deaths,
max(cast(total_deaths as int))*100.0/max(cast(total_cases as int)) as Death_rate
from CovidDeaths_csv$ dth
join CovidVaccination_csv$ vcn
on dth.location=vcn.location
where dth.continent is not null
group by dth.location,dth.population,vcn.human_development_index
order by Death_rate desc;



--Looking at data with respect to stringency index
SELECT dth.location, dth.date, dth.population, CAST(vcn.new_tests AS INT) as new_tests, dth.new_cases, 
       dth.new_cases / NULLIF(CAST(NULLIF(vcn.new_tests, 0) AS FLOAT), 0) * 100 AS DailyPositiveRate,
       dth.new_deaths, 
       dth.new_deaths / NULLIF(dth.new_cases, 0) * 100 AS DailyDeathRate,
       vcn.stringency_index 
FROM CovidDeaths_csv$ dth
JOIN CovidVaccination_csv$ vcn ON dth.location = vcn.location AND dth.date = vcn.date
WHERE dth.continent IS NOT NULL
      AND GREATEST(vcn.new_tests, dth.new_cases, dth.new_deaths) > 0
	  order by 1,2




--Viewing the percentage of population Fully Vaccinated 
select dth.continent,dth.location,dth.population,max(cast(dth.total_cases as int)) as Total_cases,
max(cast(vcn.people_fully_vaccinated as int)) as Total_people_vaccinated,
max(cast(vcn.people_fully_vaccinated as int))*100.0/dth.population as PercentPeopleVaccinated,
max(cast(vcn.total_boosters as int)) as Total_Boosters,
max(cast(vcn.total_boosters as int))*100.0/max(cast(vcn.people_fully_vaccinated as int)) as PercentPeopleTakenBooster
from CovidDeaths_csv$ dth
join CovidVaccination_csv$ vcn
on dth.location=vcn.location
where dth.continent is not null
group by dth.continent,dth.location,dth.population
order by 2;



--Looking at total deaths and total cases against different parameters

SELECT
    dth.continent, dth.location, dth.population,
    MAX(CAST(dth.total_cases AS INT)) AS Total_cases,
    MAX(CAST(total_deaths AS INT)) AS total_deaths,
    MAX(CAST(total_deaths AS INT)) * 100.0 / MAX(CAST(total_cases AS INT)) AS Death_rate,
    MAX(CAST(vcn.extreme_poverty AS FLOAT)) AS extreme_poverty,
    MAX(vcn.cardiovasc_death_rate) AS cardiovasc_death_rate,
    MAX(CAST(vcn.male_smokers AS FLOAT)) + MAX(CAST(vcn.female_smokers AS FLOAT)) AS PercentPeopleSmoking,
    MAX(vcn.median_age) AS median_age
FROM CovidDeaths_csv$ dth
JOIN CovidVaccination_csv$ vcn ON dth.location = vcn.location
WHERE dth.continent IS NOT NULL
GROUP BY dth.continent, dth.location, dth.population
ORDER BY dth.location;
