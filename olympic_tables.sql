DROP TABLE athlete_events
DROP TABLE noc_regions

CREATE TABLE athlete_events(
    ID int,
    Name varchar(255),
    Sex char(1),
    Age varchar(255),
    Height varchar(255),
    Weight varchar(255),
    Team varchar(255),
    NOC varchar(255),
    Games varchar(255),
    Year int,
    Season varchar(255),
    City varchar(255),
    Sport varchar(255),
    Event varchar(255),
    Medal varchar(255)
);


CREATE TABLE noc_regions(
    noc varchar(3),
    region varchar(255),
	notes varchar(255)
);



SELECT * 
FROM athlete_events


-- Q1. Write SQL query to identify the sport which was played in all summer Olympic games. 
-- total summer games count distint games with count(distinct)
with t1 as
(SELECT COUNT(DISTINCT games) as total_summer_games
FROM athlete_events
WHERE season = 'Summer'),

-- select distinct sports and games in the summer ordered by games
t2 as
(SELECT distinct sport, games
FROM athlete_events
where season = 'Summer'
order by games),

--lastly, select sport, and count of games from t2. group by sport.
t3 as
(select sport, count(games) as no_of_games
from t2
group by sport
)

-- select all from t3, join t1 with t3 on total games 29...
select * 
from t3
join t1 on t1.total_summer_games = t3.no_of_games


-- 2. fetch the top 5 atheletes who have won the most gold medals 
SELECT * 
FROM athlete_events

select name, team, sport, COUNT(medal) as num_of_gold_medals
from athlete_events
where medal = 'Gold'
group by name, medal, team, sport
order by num_of_gold_medals DESC
limit 5


-- 3. Q14 . List down total gold, silver, and bronze medals won by each country	
-- first query counts total medals for each type of medal for each county. 
select nr.region as country, medal, count(1) as total_medals
from athlete_events ae
LEFT JOIN noc_regions nr
	ON nr.noc = ae.noc
where medal <> 'NA'
group by nr.region, medal
order by nr.region, medal;
	
-- Crosstab allows me to have the medal values become columns.
--create extension tablefunc; 

select country,
coalesce(gold, 0) as gold,
coalesce(bronze, 0) as bronze,
coalesce(silver, 0) as silver
from crosstab('select nr.region as country, medal, count(1) as total_medals
				from athlete_events ae
				LEFT JOIN noc_regions nr
					ON nr.noc = ae.noc
				where medal <> ''NA''
				group by nr.region, medal
				order by nr.region, medal',
			 'values (''Bronze''), (''Gold''), (''Silver'')')
			as results(country varchar, bronze bigint, gold bigint, silver bigint)
order by gold DESC, bronze DESC, silver DESC;


--4. Q18 Fetch the total no of sports played in each olympic games.

SELECT games, COUNT(DISTINCT(sport)) as number_of_sports
FROM athlete_events
GROUP BY games
ORDER BY number_of_sports DESC;


--5. Which Sports were just played only once in the olympics.
SELECT *
FROM athlete_events
LIMIT 10;

with t1 as
          	(select distinct games, sport
          	from athlete_events),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;



6.-- male and female count increase by year/game... include sport? 
--total_num_of_games shows number of games per games , ex : 1936 games in the 1990 summer olymics
--main select statement then grabs the reamining columns. I also calculate the % of participant per gender per game. I join on games. Joining was key here....
with total_num_of_games (num_games) as 
	(SELECT COUNT(games)
	FROM athlete_events
	WHERE games = '1900 Summer'
	Group by games)
SELECT games, sex, COUNT(sex) as num_participants, tng.num_games, ROUND((COUNT(sex)::decimal/tng.num_games*100), 2) AS Perc_of_games_played_gender
FROM athlete_events, total_num_of_games tng
WHERE games = '1900 Summer'
GROUP BY sex, games,tng.num_games;


	SELECT year, count(*)
	FROM athlete_events
	GROUP BY year;


with total_num_of_games as 
	(SELECT year, COUNT(*) as num_games
	FROM athlete_events
	Group by year)
SELECT ae.year, ae.sex, COUNT(ae.sex) as num_participants, tng.num_games, ROUND((COUNT(ae.sex)::decimal/tng.num_games*100), 2) AS Perc_of_games_played_gender
FROM athlete_events AS ae
JOIN total_num_of_games AS tng ON ae.year = tng.year
GROUP BY ae.sex, ae.year,tng.num_games
ORDER BY ae.year;

7-- same query result as above except this time each row represents a distinct game with male and female stats as columns. (cross tab not used here. I can use that though)
WITH total_num_of_games AS (
    SELECT year, COUNT(*) AS num_games
    FROM athlete_events
    GROUP BY year
), gender_counts AS (
    SELECT
        ae.year,
        COUNT(CASE WHEN ae.sex = 'M' THEN ae.sex END) AS Male_Participants,
        COUNT(CASE WHEN ae.sex = 'F' THEN ae.sex END) AS Female_Participants,
        tng.num_games
    FROM
        athlete_events AS ae
        JOIN total_num_of_games AS tng ON ae.year = tng.year
    GROUP BY
        ae.year,
        tng.num_games
)
SELECT
    gc.year,
    gc.Male_Participants,
    gc.Female_Participants,
    gc.num_games,
    ROUND((gc.Male_Participants::decimal / gc.num_games * 100), 2) AS Male_Percentage,
    ROUND((gc.Female_Participants::decimal / gc.num_games * 100), 2) AS Female_Percentage
FROM
    gender_counts AS gc
ORDER BY
    gc.year;


8-- Find athletes that have won the most amount of medals and find total no of games played. Michael Phelps is num 1 at 30 olympics and 28 medals.
WITH t1 as 
	(SELECT COUNT(medal) as medal_count, name
	FROM athlete_events
	WHERE medal != 'NA'
	GROUP BY name)
SELECT 
	ae.name
	, ROUND(AVG(CASE WHEN age <> 'NA' THEN age::numeric END), 2) AS avg_age
	, ROUND(AVG(CASE WHEN weight <> 'NA' THEN weight::numeric END), 2) AS avg_weight
	, ROUND(AVG(CASE WHEN height <> 'NA' THEN height::numeric END), 2) AS avg_height
	, COUNT(*) as num_of_games_played
	, ae.sex
	, ae.team
	, t1.medal_count
FROM athlete_events as ae
JOIN t1 ON t1.name = ae.name
GROUP BY ae.name, ae.sex, ae.team, t1.medal_count
ORDER BY t1.medal_count DESC
LIMIT 5;



9-- find athletes that played more than 3 sports and deal count
SELECT name, team, COUNT(DISTINCT sport) AS num_of_sports_played, COUNT(medal) as medal_count
FROM athlete_events
GROUP BY name, medal, team
HAVING COUNT(DISTINCT sport) > 3
order by num_of_sports_played DESC;



SELECT *
FROM athlete_events;
