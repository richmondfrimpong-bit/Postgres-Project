CREATE TABLE youth_unemployment (country varchar(100),
								country_code varchar(5),
								year_of_assessment integer,
								youth_unemployment_rate numeric(20,15));
								
COPY youth_unemployment
FROM 'C:\Users\pc\Downloads\archive (5)\youth_unemployment_global.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',');

--DROP TABLE youth_unemployment;

SELECT * FROM youth_unemployment;

--Returns list of countries with less than 34 years
--of recorded data
SELECT country, count(*)
FROM youth_unemployment
WHERE youth_unemployment_rate IS NOT NULL
GROUP BY country
HAVING count(*) < 34;

--Returns the maximum, minimum, average and median youth 
--unemployment rates
SELECT percentile_cont(.5) 
		WITHIN GROUP (ORDER BY youth_unemployment_rate) AS "median",
		round(max(youth_unemployment_rate),4) AS max_unemp_rate,
		round(min(youth_unemployment_rate),4) AS min_unemp_rate,
		round(avg(youth_unemployment_rate),4) AS averg_unemp_rate
FROM youth_unemployment
WHERE youth_unemployment_rate IS NOT NULL;

--Returns countries who experience youth unemployment rate
--greater than 65% in certain years
SELECT country, year_of_assessment, youth_unemployment_rate
FROM youth_unemployment
WHERE youth_unemployment_rate > 65
GROUP BY country, youth_unemployment_rate, year_of_assessment;

--Returns list of countries who experienced youth unemployment
--lower than 30% in certain years
SELECT country, year_of_assessment, youth_unemployment_rate
FROM youth_unemployment
WHERE youth_unemployment_rate < 30
GROUP BY country, youth_unemployment_rate, year_of_assessment;

--returns the name of the country with the lowest
--youth unemployment rate ever recorded within the 34 year
--period
SELECT country, year_of_assessment, youth_unemployment_rate
FROM youth_unemployment
WHERE youth_unemployment_rate = 0.2950 
GROUP BY country, year_of_assessment, youth_unemployment_rate;

--Returns the list of countries with unemploment rates within the 
--range of 13% to 19% between the years 2019 and 2020
SELECT DISTINCT country 
FROM youth_unemployment
WHERE (year_of_assessment BETWEEN 2019 AND 2020) AND (youth_unemployment_rate > 13 AND youth_unemployment_rate < 19)
GROUP BY country, year_of_assessment, youth_unemployment_rate;

--Returns the list of countries with unemploment rates within the 
--range of 13% to 19% in the year 2021
SELECT country, year_of_assessment, youth_unemployment_rate
FROM youth_unemployment
WHERE (year_of_assessment = 2021) AND (youth_unemployment_rate > 13 AND youth_unemployment_rate < 19)
GROUP BY country, year_of_assessment, youth_unemployment_rate;

--SELECT country, round(CAST())
--FROM youth_unemployment
--WHERE (year_of_assessment BETWEEN 2019 AND 2021) AND (youth_unemployment_rate > 13 AND youth_unemployment_rate < 19)
--GROUP BY country, year_of_assessment, youth_unemployment_rate;

--returns the list of countries and unemployment rates for
--for the year 2019
SELECT country, youth_unemployment_rate
FROM youth_unemployment
WHERE year_of_assessment = 2019;

--Returns countries with a blend of Euro, IDA or IBRD
SELECT DISTINCT country
FROM youth_unemployment
WHERE (country LIKE 'Eur%') OR (country LIKE '%ID%') OR (country LIKE '%IB%');

--The following two blocks creates temporary tables year19_rate
--and year20_rate
CREATE TEMPORARY TABLE year19_rate(tag bigserial, country varchar(100),youth_unemployment_rate numeric(20,13));
INSERT INTO year19_rate(country, youth_unemployment_rate)	
		(SELECT country, youth_unemployment_rate
		FROM youth_unemployment
		WHERE year_of_assessment = 2019);
		
CREATE TEMPORARY TABLE year20_rate(tag bigserial, country varchar(100), youth_unemployment_rate numeric(20,13));
INSERT INTO year20_rate(country, youth_unemployment_rate) 
	(SELECT country, youth_unemployment_rate
		FROM youth_unemployment
		WHERE year_of_assessment = 2020);

--This returns the percentage change in unemployment rate 
--between 2020 and 2019 for countries with rates between
--13% and 19% in 2020
SELECT y20r.country, y19r.youth_unemployment_rate,
		y20r.youth_unemployment_rate,
		(round(((y20r.youth_unemployment_rate::numeric(20,13)) - y19r.youth_unemployment_rate)
			  /y19r.youth_unemployment_rate * 100,4)) AS pct_change_2019_2020
FROM  year20_rate y20r LEFT JOIN year19_rate y19r 
ON y20r.tag = y19r.tag
WHERE (y20r.youth_unemployment_rate > 13 AND y20r.youth_unemployment_rate < 19)
GROUP BY y20r.country, pct_change_2019_2020, y19r.youth_unemployment_rate, y20r.youth_unemployment_rate;

--This block creates the table summary_unemployment to 
--preserve the output of the query above
CREATE TABLE summary_unemployment (country varchar(100), 
								   rate_19 numeric(20,13), 
								   rate_20 numeric(20,13),
								  pct_change_20_19);
INSERT INTO summary_unemployment(country, rate_19, rate_20, pct_change_20_19)
	 SELECT y20r.country, y19r.youth_unemployment_rate,
		y20r.youth_unemployment_rate,
		(round(((y20r.youth_unemployment_rate::numeric(20,13)) - y19r.youth_unemployment_rate)
			  /y19r.youth_unemployment_rate * 100,4)) AS pct_change_2019_2020
	FROM  year20_rate y20r LEFT JOIN year19_rate y19r 
	ON y20r.tag = y19r.tag
	WHERE (y20r.youth_unemployment_rate > 13 AND y20r.youth_unemployment_rate < 19)
	GROUP BY y20r.country, pct_change_2019_2020, y19r.youth_unemployment_rate, y20r.youth_unemployment_rate;

SELECT * FROM summary_unemployment;

--The following query returns the percentage change in 
--unemployment rate for countries captured in summary_unemployment
--between the years 2020 and 2019

SELECT country, round(rate_19,4) AS rate19,
		round(rate_20,4) AS rate20, 
		round(pct_change_20_19,4) AS pct_change
FROM summary_unemployment;

--The following lines drops the temporary tables
--created above

DROP TABLE year19_rate;
DROP TABLE year20_rate;