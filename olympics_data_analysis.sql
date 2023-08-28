--How many olympics games have been held?
SELECT COUNT(DISTINCT(games)) AS total_olympics_games
FROM athlete_events_2;

--List down all Olympics games held so far

SELECT DISTINCT(year), season, city
FROM athlete_events_2
ORDER BY year ;

--Mention the total no of nations who participated in each olympics game?
WITH all_countries AS(
SELECT games, region
FROM athlete_events_2 AS ae
JOIN noc_regions AS nc ON ae.noc = nc.noc
GROUP BY games, region)
	SELECT games, COUNT(region) as total_countries
	FROM all_countries
	GROUP BY games
	ORDER BY games;

--Which year saw the highest and lowest no of countries participating in olympics
WITH all_countries AS (
	SELECT games, Count(region) as total_countries
	FROM athlete_events_2 AS ae
	JOIN noc_regions AS nc ON ae.noc = nc.noc
	GROUP BY games)
SELECT DISTINCT
CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries), '-', FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) AS Lowest_countries,
CONCAT(FIRST_VALUE(games) OVER (ORDER BY total_countries DESC), '-', FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS Highest_countries
FROM all_countries;

--Which nation has participated in all of the olympic games
WITH total_games AS(
		SELECT COUNT(DISTINCT(games)) AS total_game_count
		FROM athlete_events_2 ),
    countries_count AS(
		SELECT region, COUNT(games) AS total_game_count
		FROM athlete_events_2 AS ae
		JOIN noc_regions AS nr ON ae.noc = nr.noc
		Group by region)
SELECT cc.region, cc.total_game_count
FROM countries_count AS cc
JOIN total_games AS tg ON cc.total_game_count = tg.total_game_count
ORDER BY total_game_count;


--Identify the sport which was played in all summer olympics. 
--1. total number of summer olympics games
--2. find for each sport how my game the were play i
--3. compared 1 & 2
WITH t1 AS(
		Select Count(Distinct(games)) AS total_games
		From athlete_events_2
		where season = 'Summer'),
		t2 AS(
		Select sport, COUNT(games) as total_games
		from athlete_events_2
		Where season = 'Summer'
		Group by sport)
Select sport,  t2.total_games
FROM t2
JOIN t1 ON t2.total_games = t1.total_games


--Which Sports were just played only once in the olympics?
With t1 AS(
		Select DISTINCT(games), sport
		From athlete_events_2),
	t2 as(
		Select sport, COUNT(games) AS total_count_game
		From t1
		Group by sport)
SELECT t2.*, t1.games
From t2
JOIN t1 ON t2.sport = t1.sport
WHERE total_count_game = 1
ORDER BY t1.games

--Fetch the total no of sports played in each olympic games

Select  Count(Distinct(sport)), games
from athlete_events_2
Group by games
Order by games;

--Fetch oldest athletes to win a gold medal
With t1 AS(
		Select name, sex, age, height, weight, team, noc, games, sport, events, medal, Rank() OVER (ORDER BY age DESC) as ranking
		from athlete_events_2
		WHERE medal = 'Gold')
SELECT *
FROM t1
WHERE ranking = 1;

--Find the male and female athletes participated in all olympic games.
SELECT games, 
  SUM(CASE WHEN sex = 'M' Then 1 Else 0 END) AS male_count,
  SUM(CASE WHEN sex = 'F' Then 1 Else 0 END) AS female_count
from athlete_events_2
Group by games
ORDER BY games

--Find the Ratio of male and female athletes participated in all olympic games.
WITH t1 AS(
		SELECT sex, count(*) as cnt
		from athlete_events_2
		Group by sex),
	 t2 AS(
		SELECT * , row_number() OVER(ORDER BY cnt ) as ranking
		FROM t1),
	male_count AS(
		SELECT cnt FROM t2 WHERE ranking = 2),
	female_count AS(
		SELECT cnt FROM t2 WHERE ranking = 1)
SELECT  CONCAT('1 : ', round(male_count.cnt::decimal/female_count.cnt,1)) as ration
FROM male_count, female_count

--Fetch the top 5 athletes who have won the most gold medals
WITH t1 AS
		(Select name,team, COUNT(1) as total_medals
		from athlete_events_2
		Where medal = 'Gold'
		Group BY name,team
		ORDER BY total_medals DESC),
	t2 AS
	(SELECT *, DENSE_Rank() OVER(ORDER BY total_medals DESC) AS rnk
    FROM t1)
SELECT * FROM t2
WHERE rnk   <= 3;
 
--Fetch the top 5 athletes who have won the most medals (gold/silver/bronze) 
 

WITH t1 AS
		(Select name,team, COUNT(1) as total_medals
		from athlete_events_2
		Group BY name,team
		ORDER BY total_medals DESC),
	t2 AS
	(SELECT *, DENSE_Rank() OVER(ORDER BY total_medals DESC) AS rnk
    FROM t1)
SELECT * FROM t2
WHERE rnk   <= 3;

-- Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

WITH t1 AS
        (SELECT  nr.region, COUNT(ae.medal) as total_medals
		from athlete_events_2 AS ae
		JOIN noc_regions AS nr ON ae.noc = nr.noc
		WHERE medal <> 'NA'
		Group by nr.region
		ORDER BY total_medals DESC),
	t2 AS
		(SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rnk
		FROM t1)
SELECT * FROM t2
WHERE rnk <= 5;

--List down total gold, silver and bronze medals won by each country.	

WITH t1 AS
		(SELECT nr.region, ae.medal 
		FROM athlete_events_2  AS ae
		JOIN noc_regions AS nr ON ae.noc = nr.noc
		WHERE medal <> 'NA')
	SELECT t1.region,
	SUM(CASE WHEN t1.medal = 'Gold' THEN 1 ELSE 0 END) AS gold_count,
	SUM(CASE WHEN t1.medal = 'Silver' THEN 1 ELSE 0 END) AS silver_count,
	SUM(CASE WHEN t1.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_count
	FROM t1
	GROUP BY t1.region
	ORDER BY gold_count DESC;

-- USING PIVOT IN MOTHOD |

SELECT  country
, COALESCE(gold, 0) AS gold,
  COALESCE(silver, 0) AS silver,
  COALESCE(bronze, 0) AS bronze
FROM CROSSTAB('SELECT nr.region as country, ae.medal, COUNT(ae.medal) AS count_of_medal 
		FROM athlete_events_2  AS ae
		JOIN noc_regions AS nr ON ae.noc = nr.noc
		WHERE medal <> ''NA''
		GROUP BY country, ae.medal
	    ORDER BY country, ae.medal',
	    'Values (''Bronze''), (''Gold''), (''Silver'')')
		AS RESULT ( country VARCHAR, bronze bigint, gold bigint, silver bigint)
		ORDER BY gold desc, silver desc, bronze desc
 
 
 
 
--List down total gold, silver and bronze medals won by each country corresponding to each olympic games. 
 
SELECT SUBSTRING(games_region, 1,POSITION('-' in games_region) -1) as game,
	   SUBSTRING(games_region, POSITION('-' in games_region) +2) as country,
       COALESCE(gold, 0) AS gold,
	   COALESCE(silver,0)AS silver,
	   COALESCE(bronze,0) AS bronze	   
FROM CROSSTAB('SELECT concat(games, '' - '', region) as games_region, medal,COUNT(medal) as total_count
				FROM athlete_events_2 ae
				JOIN noc_regions nr ON nr.noc = ae.noc
				WHERE medal <> ''NA''
				GROUP BY  games, region, medal
				ORDER BY  games, region, medal DESC',
				'VALUES (''Bronze''), (''Gold''), (''Silver'')')
	AS RESULT (games_region VARCHAR, Bronze bigint, Gold bigint, Silver bigint)
	ORDER BY games_region;



--SELECT SUBSTRING('1900 Summer - Denmark', 1,11)

--Write SQL query to display for each Olympic Games, which country won the highest gold, silver and bronze medals

WITH temp AS
			(SELECT SUBSTRING(games_region, 1,POSITION('-' in games_region) -1) as game,
				   SUBSTRING(games_region, POSITION('-' in games_region) +2) as country,
				   COALESCE(gold, 0) AS gold,
				   COALESCE(silver,0)AS silver,
				   COALESCE(bronze,0) AS bronze	   
			FROM CROSSTAB('SELECT concat(games, '' - '', region) as games_region, medal,COUNT(medal) as total_count
							FROM athlete_events_2 ae
							JOIN noc_regions nr ON nr.noc = ae.noc
							WHERE medal <> ''NA''
							GROUP BY  games, region, medal
							ORDER BY  games, region, medal DESC',
							'VALUES (''Bronze''), (''Gold''), (''Silver'')')
				AS RESULT (games_region VARCHAR, Bronze bigint, Gold bigint, Silver bigint)
				ORDER BY games_region)
SELECT  DISTINCT game,
	 CONCAT(first_value(country) OVER(PARTITION BY game ORDER BY GOLD DESC) , '-',
			first_value(gold) OVER(PARTITION BY game ORDER BY gold DESC) ) as Max_Gold,
	 CONCAT(first_value(country) OVER(PARTITION BY game ORDER BY silver DESC) , '-',
			first_value(silver) OVER(PARTITION BY game ORDER BY silver DESC) ) as Max_Silver,
	 CONCAT(first_value(country) OVER(PARTITION BY game ORDER BY bronze DESC) , '-',
			first_value(bronze) OVER(PARTITION BY game ORDER BY bronze DESC) ) as Max_Bronze
from temp
ORDER BY game

--Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games
--CREATE EXTENSION TABLEFUNC;
WITH temp AS
		(SELECT SUBSTRING(game_region, 1, POSITION('-' in game_region) -1) as game,
			   SUBSTRING(game_region, POSITION('-' in game_region) +1) as country,
			   COALESCE(gold, 0) as Gold,
			   COALESCE(bronze, 0) as bronze,
			   COALESCE(silver, 0) as silver
		FROM CROSSTAB
				('SELECT concat(games, ''-'', nr.region)as game_region, medal,COUNT(medal) as total_medal
				from athlete_events_2 ae
				JOIN noc_regions nr ON nr.noc = ae.noc
				WHERE medal <> ''NA''
				GROUP BY games,medal, region
				ORDER BY games,medal, region, total_medal',
				'VALUES (''Gold''), (''Bronze''), (''Silver'')')
				AS RESULT (game_region VARCHAR, gold bigint, bronze bigint, silver bigint )
				ORDER BY game, country),
		 t2 AS
				(SELECT games, nr.region as country, medal,COUNT(medal) as total_medal
						from athlete_events_2 ae
						JOIN noc_regions nr ON nr.noc = ae.noc
						WHERE medal <> 'NA'
						GROUP BY games,medal, region
						ORDER BY games,medal, region, total_medal)
SELECT DISTINCT game, 
 CONCAT(FIRST_VALUE(t.country) OVER(PARTITION BY t.game ORDER BY t.gold DESC ),  '-' ,
	   FIRST_VALUE(t.gold) OVER(PARTITION BY t.game ORDER BY t.gold DESC)) as gold,
 CONCAT(FIRST_VALUE(t.country) OVER(PARTITION BY t.game ORDER BY t.silver DESC ),  '-' ,
	   FIRST_VALUE(t.silver) OVER(PARTITION BY t.game ORDER BY t.silver DESC)) as silver,
 CONCAT(FIRST_VALUE(t.country) OVER(PARTITION BY t.game ORDER BY t.bronze DESC ),  '-' ,
	   FIRST_VALUE(t.bronze) OVER(PARTITION BY t.game ORDER BY t.bronze DESC)) as bronze,
  CONCAT(FIRST_VALUE(t2.country) OVER(PARTITION BY t2.games ORDER BY t2.total_medal DESC  nulls last),  '-' ,
	   FIRST_VALUE(t2.total_medal) OVER(PARTITION BY t2.games ORDER BY t2.total_medal DESC  nulls last)) as MAX_medal
FROM TEMP as t
JOIN t2 ON t.game = t2.games


--Which countries have never won gold medal but have won silver/bronze medals?
--CREATE EXTENSION TABLEFUNC;

WITH t1 AS
		(SELECT region,
			   COALESCE(gold, 0) as gold,
			   COALESCE(silver, 0) as silver,
			   COALESCE(bronze, 0) as bronze
		FROM CROSSTAB
					('SELECT nr.region, medal, COUNT(medal) as total_count 
					from athlete_events_2 ae
					JOIN noc_regions nr ON ae.noc = nr.noc
					WHERE medal <> ''NA''
					Group by nr.region, medal',
					'VALUES (''Gold''), (''Silver''), (''Bronze'')')
					AS RESULT(region VARCHAR, gold bigint, silver bigint, bronze bigint)
					ORDER BY silver DESC, bronze DESC)
SELECT * from t1
WHERE gold = 0 AND (silver > 0 OR bronze > 0)

--In which Sport/event, USA has won highest medals.
WITH t1 AS
		(SELECT sport,COUNT(medal) as total_count 
		from athlete_events_2 ae
		JOIN noc_regions nr ON ae.noc = nr.noc
		WHERE medal <> 'NA' AND region in ('USA')
		Group by sport
		ORDER BY  total_count),
	 t2 as
		(SELECT sport,total_count  ,
			   DENSE_RANK() OVER (ORDER BY total_count DESC) as rnk
		FROM t1)
select sport, total_count from t2
WHERE rnk = 1;

--Break down all olympic games where USA won medal for SWIMMING and how many medals in each olympic games


SELECT games,nr.region, sport,medal, COUNT(*) as total_count 
FROM athlete_events_2 ae
JOIN noc_regions nr ON ae.noc = nr.noc
WHERE medal <> 'NA' AND nr.region in ('USA') AND sport in ('Rowing')
GROUP BY nr.region,games,sport, medal
ORDER BY games,total_count












 
 
 
 
 
 
 
 
 
 
 
 
