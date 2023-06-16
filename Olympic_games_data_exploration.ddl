/* DATA EXPLORATION IN POSTGRESQL - 120 years of Olympic history: athletes and results */

--- Load the data
CREATE TABLE ATHLETE_EVENTS
(id     INT,
 name   VARCHAR,
 sex    VARCHAR,
 age    VARCHAR,
 height VARCHAR,
 weight VARCHAR,
 team   VARCHAR,
 noc    VARCHAR,
 games  VARCHAR,
 year   INT,
 season VARCHAR,
 city   VARCHAR,
 sport  VARCHAR,
 event  VARCHAR,
 medal  VARCHAR);

CREATE TABLE NOC_REGIONS
(noc    VARCHAR,
 region VARCHAR,
 notes  VARCHAR);
 
 -- View the data
SELECT * 
FROM ATHLETE_EVENTS
LIMIT 10;

SELECT * 
FROM NOC_REGIONS
LIMIT 10;

------- 1) Gender Analysis

-- Number and percentage of female and male participants in each olympic game.
-- Some participants participated in more than one sport, but they are counted as one person in this query.
SELECT games,
       COUNT(DISTINCT CASE WHEN Sex = 'M' THEN id END) AS male_count,
       COUNT(DISTINCT CASE WHEN Sex = 'F' THEN id END) AS female_count,
	   COUNT(DISTINCT id) AS gender_count,
       ROUND((COUNT(DISTINCT CASE WHEN Sex = 'M' THEN id END) * 100.0 / COUNT(DISTINCT id))::numeric, 2) AS male_percentage,
       ROUND((COUNT(DISTINCT CASE WHEN Sex = 'F' THEN id END) * 100.0 / COUNT(DISTINCT id))::numeric, 2) AS female_percentage	
FROM ATHLETE_EVENTS
GROUP BY games;

---- What about France ? 
WITH all_countries AS (SELECT games,
  					  	      ROUND((COUNT(DISTINCT CASE WHEN sex = 'F' THEN id END) * 100.0 / COUNT(DISTINCT id))::numeric, 2) AS pct_female_all_countries
					  FROM ATHLETE_EVENTS
					  GROUP BY games),
					  
		    france AS (SELECT games,
					          ROUND((COUNT(DISTINCT CASE WHEN sex = 'F' THEN id END) * 100.0 / COUNT(DISTINCT id))::numeric, 2) AS pct_female_france
				      FROM ATHLETE_EVENTS ae
					  JOIN NOC_REGIONS nr ON nr.noc = ae.noc
					  WHERE region = 'France'
					  GROUP BY games)
					 					  
SELECT ac.games,
       pct_female_france,
	   pct_female_all_countries       
FROM all_countries ac
JOIN france f ON f.games = ac.games
-- WHERE pct_female_france > pct_female_all_countries

---- Let's examine the percentage of female athletes in the more recent Olympic Games, specifically starting from the 2000 Games.				 					  
SELECT ROUND((COUNT(DISTINCT CASE WHEN sex = 'F' THEN id END) * 100.0 / COUNT(DISTINCT id))::numeric, 2) AS pct_female_france, 
       (SELECT ROUND((COUNT(DISTINCT CASE WHEN sex = 'F' THEN id END) * 100.0 / COUNT(DISTINCT id))::numeric, 2) AS pct_female_all_countries 
		FROM ATHLETE_EVENTS
	    WHERE year > 2000)
FROM ATHLETE_EVENTS ae
JOIN NOC_REGIONS nr ON nr.noc = ae.noc
WHERE region = 'France'
AND year > 2000

------- 2) Age analysis

-- What is the average age of male and female participants ? Comparison between French athletes and the global average.
WITH avg_age_all_athletes AS (SELECT sex, 
							         ROUND(AVG(age::numeric), 1) AS avg_all_athletes
  					          FROM ATHLETE_EVENTS
  					          WHERE age <> 'NA'
  					          GROUP BY sex),
					 
  avg_age_french_athletes AS (SELECT sex, 
							         ROUND(AVG(age::numeric), 1) AS avg_french_athletes
  					          FROM ATHLETE_EVENTS oh
  				              JOIN NOC_REGIONS nr ON nr.noc = oh.noc
  					          WHERE age <> 'NA' AND nr.region = 'France'
  				              GROUP BY sex)
 
SELECT aaaa.sex,
       aaaa.avg_all_athletes,
       aafa.avg_french_athletes
FROM avg_age_all_athletes aaaa
JOIN avg_age_french_athletes aafa ON aafa.sex = aaaa.sex

-- What is the average participant age in each sport ?
SELECT sport, 
	   sex, 
	   ROUND(AVG(CAST(age AS REAL))) AS avg_age
FROM ATHLETE_EVENTS
WHERE age <> 'NA'
GROUP BY sport, sex
ORDER BY avg_age DESC

-- Average participants age in each sport for recent olympic games.
SELECT sport, 
	   sex, 
	   ROUND(AVG(CAST(age AS REAL))) AS avg_age
FROM ATHLETE_EVENTS
WHERE age <> 'NA'
AND year > 2000
GROUP BY sport, sex
ORDER BY avg_age DESC

-- What is the average age of medal winners ?
SELECT medal, 
       ROUND(AVG(age::numeric), 1) AS avg_age_gold_medal
FROM ATHLETE_EVENTS 
WHERE age <> 'NA'
GROUP BY medal

-- What are the individual average characteristics by sport and gender ? 
SELECT sport,
		sex,
       ROUND(AVG(CAST(age AS REAL))) AS avg_age, 
       ROUND(AVG(CAST(height AS REAL))) AS avg_height, 
	   ROUND(AVG(CAST(weight AS REAL))) AS avg_weight
FROM ATHLETE_EVENTS
WHERE age <> 'NA'
AND height <> 'NA'
AND weight <> 'NA'
GROUP BY sex,sport
ORDER BY avg_weight
-- Interesting fact : 
-- The sport where the athlete are the smallest is Gymnastic with an average height of 156cm for women and 168cm for men; followed by weightlifting.

-------- 3) Medal Analysis

-- Who has won the most medals ?
WITH step1 AS (SELECT ae.name AS name,
			   	      nr.region AS region,
			   		  COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals_count,
			   	      COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals_count,
			          COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals_count,
	   		  	      COUNT(ae.medal) AS total_medals	   		  		 
			  FROM ATHLETE_EVENTS ae
		      JOIN NOC_REGIONS nr ON nr.noc = ae.noc
			  WHERE ae.medal <> 'NA'
			  GROUP BY ae.name, nr.region)

SELECT name,
	   region,
	   gold_medals_count,
	   silver_medals_count,
	   bronze_medals_count,
	   total_medals	   
FROM step1
WHERE total_medals = (SELECT MAX(total_medals) FROM step1)

-- How many medals each country won in summer Olympics ?
SELECT nr.region AS region,
	   COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals_count,
	   COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals_count,
	   COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals_count,
	   COUNT(ae.medal) AS total_medals,
	   ROUND(COUNT(ae.medal)*100/(SELECT COUNT(medal) FROM ATHLETE_EVENTS WHERE medal <> 'NA')::numeric,4) AS percentage_total
FROM ATHLETE_EVENTS ae
JOIN NOC_REGIONS nr ON nr.noc = ae.noc
WHERE ae.medal <> 'NA'
AND season = 'Summer'
GROUP BY nr.region
ORDER BY total_medals DESC

-- What are the top 5 sports in which France has won the most medals in summer olympics ?
SELECT sport,
       COUNT(medal) AS medals_count
FROM ATHLETE_EVENTS ae
JOIN NOC_REGIONS nr ON nr.noc = ae.noc
WHERE nr.region = 'France'
AND medal <> 'NA'
AND season = 'Summer'
GROUP BY sport
ORDER BY 2 DESC
LIMIT 5;

