/*Examine the range of dates covered in the database. 1933 - 2016.*/

SELECT DISTINCT (yearid)
FROM allstarfull
ORDER BY yearid DESC;

/*Examine the heights of players in the league. */

SELECT playerid, namefirst, namelast, namegiven, height
FROM people
ORDER BY height ASC;

SELECT MIN(height)
FROM people;

SELECT playerid, namefirst, namelast, namegiven, height
FROM people
ORDER BY height ASC;

/*Using the fielding table, group players into three groups based on their position: 
position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/

SELECT SUM(po),
		CASE 
		WHEN CAST(pos AS text)= 'OF' THEN 'Outfield'
		WHEN CAST(pos AS text) = 'SS' OR CAST(pos AS text) = '1B' OR CAST(pos AS text) = '2B' OR CAST(pos AS text)= '3B' THEN 'Infield'
		WHEN CAST(pos AS text)= 'P' OR CAST(pos AS text) ='C' THEN 'Battery' END as pos_category
FROM fielding
WHERE yearID = '2016'
GROUP BY pos_category;

/* Find all players in the database who played at Vanderbilt University.
Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues.
Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?*/

SELECT * 
FROM schools
WHERE schoolname = 'Vanderbilt University';


WITH income_per_player AS
	(SELECT playerid, SUM(salary) AS income_per_player
	FROM salaries
	GROUP BY playerid)
SELECT DISTINCT ppl.playerid, sch.schoolname, ppl.namefirst, ppl.namelast, ipp.income_per_player::numeric::money
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_player AS ipp
	 ON ipp.playerid = ppl.playerid
WHERE sch.schoolname = 'Vanderbilt University'
ORDER BY ipp.income_per_player::numeric::money DESC;

/*Find the average number of strikeouts per game by decade since 1920. 
Same for home runs per game. */

-- avg. strikeouts per game per year
SELECT yearid AS year,
	   AVG((so + soa)/g) AS avg_strikeouts
FROM teams
GROUP BY year
ORDER BY year;

--nifty decades titling
SELECT CONCAT(CAST(EXTRACT(DECADE FROM(TO_DATE(CAST(yearid AS text), 'YYYY'))) *10 AS text), 's') AS decade,
	   ROUND(AVG((so + soa)/g), 2) AS avg_strikeouts
FROM teams
WHERE CONCAT(CAST(EXTRACT(DECADE FROM(TO_DATE(CAST(yearid AS text), 'YYYY'))) *10 AS text), 's') >= '1920s'
GROUP BY decade
ORDER BY decade;

-- by teams
SELECT CONCAT(CAST(EXTRACT(DECADE FROM(TO_DATE(CAST(yearid AS text), 'YYYY'))) *10 AS text), 's') AS decade,
	   ROUND(AVG((hr + hra)/g), 2) AS avg_homeruns
FROM teams
WHERE CONCAT(CAST(EXTRACT(DECADE FROM(TO_DATE(CAST(yearid AS text), 'YYYY'))) *10 AS text), 's') >='1920s'
GROUP BY decade
ORDER BY decade;

-- combined, remove the soa and hra
SELECT CONCAT(CAST(EXTRACT(DECADE FROM(TO_DATE(CAST(yearid AS text), 'YYYY'))) *10 AS text), 's') AS decade,
	   ROUND(AVG((so)/g), 2) AS avg_strikeouts,
	   ROUND(AVG((hr)/g), 2) AS avg_homeruns
FROM teams
WHERE CONCAT(CAST(EXTRACT(DECADE FROM(TO_DATE(CAST(yearid AS text), 'YYYY'))) *10 AS text), 's') >= '1920s'
GROUP BY decade
ORDER BY decade;

/* Find the player who had the most success stealing bases in 2016,
where success is measured as the percentage of stolen base attempts which are successful.
(A stolen base attempt results either in a stolen base or being caught stealing.)
Consider only players who attempted at least 20 stolen bases.*/

SELECT *
FROM batting
WHERE stint = 2 AND yearid = 2016
ORDER BY playerid
LIMIT 100;

SELECT DISTINCT playerid, g, ab, r
FROM batting
WHERE cs IS NOT NULL AND yearid = 2016
ORDER BY playerid
LIMIT 100;

-- Chris Owings had a 91% success rate in 2016.

WITH steal_attempts AS
	(SELECT DISTINCT playerid, cs AS caught_stealing, sb AS stolen_bases,
	 (cs + sb) AS steal_attempts
	 FROM batting
	 WHERE cs + sb <> 0 AND yearid = 2016), -- there are no playerid duplicates here, math adding up
    success_rate AS
	(SELECT DISTINCT bs.playerid, sa.caught_stealing, 
	 sa.stolen_bases, ROUND((sa.stolen_bases::decimal/sa.steal_attempts::decimal)::decimal, 4) AS success_rate
	FROM batting AS bs
	INNER JOIN steal_attempts AS sa
	ON bs.playerid = sa.playerid
	WHERE cs + sb <> 0 AND yearid = 2016)
SELECT DISTINCT bs.playerid, ppl.namelast, ppl.namefirst, sa.steal_attempts, sr.success_rate, bs.cs AS caught_stealing, bs.sb AS stolen_bases, bs.yearid, bs.teamid
FROM batting as bs
	 INNER JOIN people as ppl
	 ON bs.playerid = ppl.playerid
	 INNER JOIN steal_attempts as sa
	 ON bs.playerid = sa.playerid
	 INNER JOIN success_rate as sr
	 ON bs.playerid = sr.playerid
WHERE bs.yearid = 2016 AND sa.steal_attempts >= 20
ORDER BY sr.success_rate DESC, sa.steal_attempts DESC;

/* Analyze all the colleges in the state of Tennessee. 
Which college has had the most success in the major leagues. 
Use whatever metric for success you like - number of players, 
number of games, salaries, world series wins, etc.*/


SELECT *
FROM salaries
LIMIT 500;

SELECT *
FROM schools
WHERE schoolstate = 'TN';
-- There are 39 schools from TN that had players in the majors.

/*First, I looked to see which school had the player with the highest lifetime earnings.
This was Todd Helton from UT with $163Mil, followerd by David Price from Vanderbilt with $81Mil
and then Dan Uggla from University of Memphis with $63Mil.*/

WITH income_per_player AS
	(SELECT playerid, SUM(salary) AS income_per_player
	FROM salaries
	GROUP BY playerid)
SELECT DISTINCT ppl.playerid, sch.schoolname, ppl.namefirst, ppl.namelast, ipp.income_per_player::numeric::money
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_player AS ipp
	 ON ipp.playerid = ppl.playerid
WHERE sch.schoolstate = 'TN'
ORDER BY ipp.income_per_player::numeric::money DESC;

/*Next, I rewrote this query to group by college instead of individual player, University of Tennessee alumnai have totaled 556,433,230 million
more than Vandy and about 800 million more than university of Memphis in the major leagues at $985 million over time.*/

WITH income_per_school AS
	 (SELECT cp.schoolid AS schoolid, SUM(salary) AS income_per_school
	 FROM salaries as s
	 INNER JOIN collegeplaying as cp
	 ON s.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 GROUP BY cp.schoolid)
SELECT DISTINCT cp.schoolid, sch.schoolname, ips.income_per_school::numeric::money
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_school AS ips
	 ON cp.schoolid = ips.schoolid
WHERE sch.schoolstate = 'TN'
ORDER BY ips.income_per_school::numeric::money DESC;

/* Group more together with a bunch of CTEs. UT wins in pretty much any category but notably when you look at Hall of Fame players,
Tennessee Wesleyan - who had their latest mls player in 1995, is the only other school besides UT to have hall of fame players - 12, compared to 
UT's 64.*/

WITH income_per_player AS
	(SELECT playerid, SUM(salary) AS income_per_player
	FROM salaries
	GROUP BY playerid),
	income_per_school AS
	(SELECT cp.schoolid AS schoolid, SUM(salary) AS income_per_school
	FROM salaries as s
	 INNER JOIN collegeplaying as cp
	 ON s.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 GROUP BY cp.schoolid)
SELECT DISTINCT cp.schoolid, sch.schoolname, MAX(ips.income_per_school::numeric::money) AS income_per_school, 
	MAX(ipp.income_per_player::numeric::money) AS max_income_perplayer, COUNT(DISTINCT ppl.playerid) AS players_to_majors, 
	(MAX(ips.income_per_school)/COUNT(DISTINCT ppl.playerid))::numeric::money AS college_income_per_majors_player, 
	MIN(s.yearid) AS first_salariedin_majors, MAX(s.yearid) AS latest_salariedin_majors--, COUNT(hof.playerid)
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_player AS ipp
	 ON ipp.playerid = ppl.playerid
	 INNER JOIN income_per_school AS ips
	 ON cp.schoolid = ips.schoolid
	-- INNER JOIN halloffame as hof
	-- ON ppl.playerid = hof.playerid
WHERE sch.schoolstate = 'TN'
GROUP BY cp.schoolid, sch.schoolname
ORDER BY MAX(ips.income_per_school::numeric::money) DESC, MAX(ipp.income_per_player::numeric::money) DESC;