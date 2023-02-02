--1.VIEW called forestation by joining 3 tables and a new column that
--provides percent of the land area that is designated as forest

CREATE VIEW forestation AS
(SELECT
f.country_code,
f.country_name,
f.year,f.forest_area_sqkm,
l.total_area_sq_mi, (f.forest_area_sqkm/(l.total_area_sq_mi*2.59))*100
AS forest_area_percent, (l.total_area_sq_mi*2.59) AS total_area_sqkm, r.region,
r.income_group
FROM forest_area f
LEFT JOIN land_area l
ON f.country_code = l.country_code AND f.year = l.year
FULL JOIN regions r
ON l.country_code = r.country_code);


--GLOBAL SITUATION
-- 1. What was the total forest area (in sq km) of the world in 1990?

SELECT
year,
forest_area_sqkm
FROM forestation
WHERE year = '1990' AND country_name = 'World';


-- 2. What was the total forest area (in sq km) of the world in 2016?

SELECT
year,
forest_area_sqkm
FROM forestation
WHERE year = '2016' AND country_name = 'World';

--3. What was the change (in sq km) in the forest area of the world
--from 1990 to 2016?

WITH area_1990 AS
(SELECT
country_name, forest_area_sqkm AS ar_1990
FROM forestation
WHERE year ='1990' AND country_name = 'World'),

area_2016 AS
(SELECT
country_name, forest_area_sqkm AS ar_2016
FROM forestation
WHERE year ='2016' AND country_name = 'World')

SELECT
area_1990.country_name,
area_1990.ar_1990,
area_2016.ar_2016,
(area_2016.ar_2016 - area_1990.ar_1990) AS chng_in_frst_area
FROM area_1990
JOIN area_2016
ON area_1990.country_name = area_2016.country_name;

-- 4. What was the percent change in forest area of the world
-- between 1990 and 2016?

WITH area_1990 AS
(SELECT
country_name, forest_area_sqkm AS ar_1990
FROM forestation
WHERE year ='1990' AND country_name = 'World'),

area_2016 AS
(SELECT country_name,
forest_area_sqkm AS ar_2016
FROM forestation
WHERE year ='2016' AND country_name = 'World')

SELECT
area_1990.country_name,
area_1990.ar_1990,
area_2016.ar_2016,
ROUND(((area_2016.ar_2016 - area_1990.ar_1990)*100/ area_1990.ar_1990)::numeric,2)
AS percent_chng_in_frst_area
FROM area_1990
JOIN area_2016
ON area_1990.country_name = area_2016.country_name;

--5. When compare the amount of forest area lost between 1990 and 2016,
--to which country's total area in 2016 is it closest to?

WITH area_1990 AS
(SELECT forest_area_sqkm AS ar_1990
FROM forestation
WHERE year = '1990' AND country_name = 'World'),

area_2016 AS
(SELECT forest_area_sqkm AS ar_2016
FROM forestation
WHERE year = '2016' AND country_name = 'World'),

change AS
(SELECT ABS(ar_2016 - ar_1990) chng_frst_area
FROM area_1990, area_2016)

SELECT
country_name,
total_area_sqkm,
ROUND(ABS(total_area_sqkm - chng_frst_area)::numeric,2)
AS diff_in_land_forest
FROM forestation,change
WHERE year = '2016'
GROUP BY country_name, total_area_sqkm, chng_frst_area
ORDER BY diff_in_land_forest ASC;

--REGIONAL OUTLOOK

-- 1.Regions and their percent forest area in 1990 and 2016.

WITH percentage_forest_1990 AS
(SELECT
region, ROUND((SUM(forest_area_sqkm)*100/SUM(total_area_sqkm)) ::numeric,2)
AS percent_forest_90
FROM forestation
WHERE year = '1990' AND forest_area_sqkm IS NOT NULL
GROUP BY region),

percentage_forest_2016 AS
(SELECT
region, ROUND((SUM(forest_area_sqkm)*100/SUM(total_area_sqkm)) ::numeric,2)
AS percent_forest_16
FROM forestation
WHERE year = '2016' AND forest_area_sqkm IS NOT NULL
GROUP BY region),

joined_1990_2016 AS
(SELECT percentage_forest_1990.region,
percent_forest_90, percent_forest_16
FROM percentage_forest_1990
JOIN percentage_forest_2016
ON percentage_forest_1990.region = percentage_forest_2016.region)

SELECT *
FROM joined_1990_2016;

--2.Percent forest of the entire world in 1990.Regions with HIGHEST
--and the LOWEST forest percent in 1990,to 2 decimal places.

SELECT
region,
ROUND((SUM(forest_area_sqkm))::nuremic,2) AS total_forest,
ROUND((SUM(forest_area_sqkm)*100/SUM(total_area_sqkm))::numeric,2)
AS percent_forest_90
FROM forestation
WHERE year = '1990' AND region != 'World'
GROUP BY region
ORDER BY percent_forest_90 DESC;

--3.Percent forest of the entire world in 2016. Regions with the HIGHEST
--and the LOWEST percent forest in 2016, to 2 decimal places.

SELECT
region,
ROUND((SUM(forest_area_sqkm))::nuremic,2) AS total_forest,
ROUND((SUM(forest_area_sqkm)*100/SUM(total_area_sqkm))::numeric,2)
AS percent_forest_16
FROM forestation
WHERE year = '2016' AND region != 'World'
GROUP BY region
ORDER BY percent_forest_16 DESC;

--COUNTRY-LEVEL-DETAILS

-- 1. Which 5 countries saw the largest amount decrease in forest area from
-- 1990 to 2016? What was the difference in forest area for each?

WITH forest_in_1990 AS
(SELECT
region,
country_name,
forest_area_sqkm AS forest_1990
FROM forestation
WHERE year = '1990' AND country_name <> 'World' AND
forest_area_sqkm IS NOT NULL),

forest_in_2016 AS
(SELECT
region,
country_name,
forest_area_sqkm AS forest_2016
FROM forestation
WHERE year = '2016' AND country_name <> 'World'
AND forest_area_sqkm IS NOT NULL)

SELECT
f_16.country_name,
f_90.region,
forest_1990,
forest_2016,
(forest_2016 - forest_1990) AS chng_in_forest_area,
ROUND(((forest_2016 - forest_1990)*100/forest_1990)::numeric,2)
AS percent_chng
FROM forest_in_1990 f_90
JOIN forest_in_2016 f_16
ON f_90.region = f_16.region AND f_90.country_name = f_16.country_name
ORDER BY chng_in_forest_area ASC;

--2. Which 5 countries saw the largest percent decrease in forest area
--from 1990 to 2016? What was the percent change to 2 decimal places for each?

WITH forest_in_1990
AS (SELECT
region,
country_name,
forest_area_sqkm AS forest_1990 FROM forestation
WHERE year = '1990' AND country_name <> 'World'
AND forest_area_sqkm IS NOT NULL),

forest_in_2016 AS
(SELECT
region,
country_name,
forest_area_sqkm AS forest_2016 FROM forestation
WHERE year = '2016' AND country_name <> 'World'
AND forest_area_sqkm IS NOT NULL)

SELECT
f_16.country_name,
f_90.region,
forest_1990,
forest_2016,
(forest_2016 - forest_1990) AS chng_in_forest_area,
ROUND(((forest_2016 - forest_1990)*100/forest_1990)::numeric,2)
AS percent_chng
FROM forest_in_1990 f_90
JOIN forest_in_2016 f_16
ON f_90.region = f_16.region AND f_90.country_name = f_16.country_name
ORDER BY percent_chng ASC;

-- 3. When countries were grouped by percent forestation in quartiles, which group
-- had the most countries in it in 2016?

WITH forest_area_2016 AS
(
SELECT
country_name,
region,
total_area_sqkm,
forest_area_sqkm
FROM forestation
WHERE year = '2016'
AND country_name != 'World'
AND forest_area_sqkm IS NOT NULL AND total_area_sqkm IS NOT NULL),

percent_forest_2016 AS
(
SELECT
fa_2016.country_name,
fa_2016.region,
ROUND((SUM(fa_2016.forest_area_sqkm)*100/ SUM(fa_2016.total_area_sqkm))::numeric,2)
AS pct_forest_2016
FROM forest_area_2016 AS fa_2016
GROUP BY fa_2016.region, fa_2016.country_name, fa_2016.forest_area_sqkm),

qrt_2016 AS (
SELECT
pf.country_name,
pf.region,
pf.pct_forest_2016,
CASE WHEN pf.pct_forest_2016 >= 0 AND pf.pct_forest_2016 < 25
THEN 'first_quartile'
WHEN pf.pct_forest_2016 >= 25 AND pf.pct_forest_2016 < 50
THEN 'second_quartile'
WHEN pf.pct_forest_2016 >= 50 AND pf.pct_forest_2016 < 75
THEN 'third_quartile'
ELSE 'fourth_quartile'
END AS country_quartile
FROM percent_forest_2016 pf)

SELECT
country_quartile,
COUNT(*) AS country_count
FROM qrt_2016
GROUP BY country_quartile;

--4 List of all the countries that were in the 4th quartile
--(percent forest > 75%) in 2016.

WITH forest_area_2016 AS (
SELECT
country_name,
region,
total_area_sqkm,
forest_area_sqkm
FROM forestation
WHERE year = '2016'
AND country_name != 'World'
AND forest_area_sqkm IS NOT NULL
AND total_area_sqkm IS NOT NULL),

percent_forest_2016 AS
(
SELECT
fa_2016.country_name,
fa_2016.region,
ROUND((SUM(fa_2016.forest_area_sqkm)*100/ SUM(fa_2016.total_area_sqkm))::numeric,2)
AS pct_forest_2016
FROM forest_area_2016 AS fa_2016
GROUP BY fa_2016.region, fa_2016.country_name, fa_2016.forest_area_sqkm),

qrt_2016 AS
(
SELECT
pf.country_name,
pf.region,
pf.pct_forest_2016,
CASE WHEN pf.pct_forest_2016 >= 0 AND pf.pct_forest_2016 < 25
THEN 'first_quartile'
WHEN pf.pct_forest_2016 >= 25 ANDpf.pct_forest_2016 < 50
THEN 'second_quartile'
WHEN pf.pct_forest_2016 >= 50 AND pf.pct_forest_2016 < 75
THEN 'third_quartile'
ELSE 'fourth_quartile'
END AS country_quartile
FROM percent_forest_2016 pf
)

SELECT *
FROM qrt_2016
WHERE country_quartile = 'fourth_quartile'
ORDER BY pct_forest_2016 DESC;

-- 5. How many countries had a percent forestation higher than the
-- United States in 2016?

WITH forest_area_2016 AS
(
SELECT
country_name,
region,
total_area_sqkm,
forest_area_sqkm
FROM forestation
WHERE year = '2016'
AND country_name != 'World'
AND forest_area_sqkm IS NOT NULL AND total_area_sqkm IS NOT NULL),

percent_forest_2016 AS
(
SELECT
fa_2016.country_name,
fa_2016.region,
ROUND((SUM(fa_2016.forest_area_sqkm)*100/ SUM(fa_2016.total_area_sqkm))::numeric,2)
AS pct_forest_2016
FROM forest_area_2016 AS fa_2016
GROUP BY fa_2016.region, fa_2016.country_name, fa_2016.forest_area_sqkm),

united_states AS
(SELECT
pf.country_name,
pf.pct_forest_2016
FROM percent_forest_2016 pf
WHERE country_name = 'United States')

SELECT
pf.country_name,
pf.pct_forest_2016
FROM percent_forest_2016 AS pf,
united_states AS us
WHERE pf.pct_forest_2016 > us.pct_forest_2016
ORDER BY pf.pct_forest_2016;

--6.One bright spot at country level.

WITH forest_in_1990 AS (SELECT
region,
country_name,
total_area_sqkm, forest_area_sqkm AS forest_1990
FROM forestation
WHERE year = '1990' AND country_name <> 'World'
AND forest_area_sqkm IS NOT NULL),

forest_in_2016 AS
(SELECT
region,
country_name,
forest_area_sqkm AS forest_2016
FROM forestation
WHERE year = '2016' AND country_name <> 'World'
AND forest_area_sqkm IS NOT NULL)

SELECT
f_16.country_name,
f_90.region,
f_90.total_area_sqkm,
forest_1990,
forest_2016,
ROUND(ABS((forest_2016 - forest_1990))::numeric,2)
AS chng_in_forest_area,
ROUND(((forest_2016 - forest_1990)*100/forest_1990)::numeric,2)
AS percent_chng
FROM forest_in_1990 AS f_90
JOIN forest_in_2016 AS f_16
ON f_90.region = f_16.region
AND f_90.country_name = f_16.country_name
ORDER BY percent_chng DESC;
