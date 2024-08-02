SELECT TOP (1000) [show_id]
      ,[type]
      ,[title]
      ,[director]
      ,[cast]
      ,[country]
      ,[date_added]
      ,[release_year]
      ,[rating]
      ,[duration]
      ,[listed_in]
      ,[description]
  FROM [Project1].[dbo].[netflix_titles]

/*Number of Records imported*/
  select count(*)  FROM [Project1].[dbo].[netflix_titles]  --8807

  --create back up table
  select * into [Project1].[dbo].[netflix_titles_RAW] FROM [Project1].[dbo].[netflix_titles];

  /*CONTINUE TO USE FIRST TABLE AS MAIN TABLE FOR DATA CLEANING*/

/*FIND DUPLICATES*/
SELECT  [show_id]
      ,[type]
      ,[title]
      ,[director]
      ,[cast]
      ,[country]
      ,[date_added]
      ,[release_year]
      ,[rating]
      ,[duration]
      ,[listed_in]
      ,[description] 
	  FROM  [Project1].[dbo].[netflix_titles] 
	  GROUP BY  [show_id]
      ,[type]
      ,[title]
      ,[director]
      ,[cast]
      ,[country]
      ,[date_added]
      ,[release_year]
      ,[rating]
      ,[duration]
      ,[listed_in]
      ,[description]
	  HAVING COUNT(*) >1

/*REVIEW NULLS*/
  with dIRECTOR as (
  SELECT COUNT(*) as DIRECTOR FROM [Project1].[dbo].[netflix_titles] WHERE director IS NULL GROUP BY DIRECTOR),
	[cast] as (
    SELECT COUNT(*) as [cast] FROM [Project1].[dbo].[netflix_titles] WHERE [CAST] IS NULL GROUP BY[CAST])
	select DIRECTOR, [cast] from DIRECTOR, [cast]

/*Created stored proc for review all nulls in all fields within a table*/
EXEC [Project1].[dbo].FIND_NULLS '[Project1].[dbo].netflix_titles'

----NAME		NULLS found
----director	2634
----cast		825
----country		831
----date_added	98
----rating		4

/*FIX NULLS AND DATA REMODELING*/
select 'duration' AS NAME, COUNT(*) as NULLS from [Project1].[dbo].netflix_titles where [duration] IS NULL GROUP BY [duration] 

SELECT * from [Project1].[dbo].netflix_titles where [duration] IS NULL-- DATA SHIFTED, 3 RECORDS

UPDATE [Project1].[dbo].netflix_titles SET DURATION = RATING where [duration] IS NULL -- (3 rows affected)

/*RATING*/
SELECT RATING, COUNT(*)From [Project1].[dbo].netflix_titles GROUP BY RATING ORDER BY 2

SELECT * From [Project1].[dbo].netflix_titles WHERE RATING LIKE '%MIN' -- 3 RECORDS

UPDATE [Project1].[dbo].netflix_titles SET RATING = NULL WHERE RATING LIKE '%MIN'

SELECT * From [Project1].[dbo].netflix_titles WHERE RATING IS NULL -- 7 RECORDS


	 SELECT CONCAT('R',ROW_NUMBER() OVER (ORDER BY RATING)) RATE_ID, (RATING) AS RATING
	 INTO [Project1].[dbo].RATING
	 From [Project1].[dbo].netflix_titles WHERE RATING IS NOT NULL
	 GROUP BY RATING 

SELECT * FROM [Project1].[dbo].RATING

/*COUNTRY*/

SELECT DISTINCT COUNTRY FROM [Project1].[dbo].netflix_titles ORDER BY 1

SELECT COUNTRY,value
FROM [Project1].[dbo].netflix_titles  
CROSS APPLY STRING_SPLIT(Country, ',')

SELECT CONCAT('C',ROW_NUMBER() OVER (ORDER BY Country)) Country_ID, Country
INTO [Project1].[dbo].Countries
FROM (
SELECT distinct trim(value) as Country
FROM [Project1].[dbo].netflix_titles  
CROSS APPLY STRING_SPLIT(Country, ',')
where len(value) >1) AS A
order by Country


select * from [Project1].[dbo].Countries

/*Director*/
SELECT DISTINCT Director FROM [Project1].[dbo].netflix_titles WHERE Director IS NOT NULL ORDER BY 1

select ROW_NUMBER() OVER (ORDER BY Director) Director_ID, director
INTO [Project1].[dbo].Director
	from (
	SELECT  DISTINCT trim(value) as Director
FROM [Project1].[dbo].netflix_titles  
CROSS APPLY STRING_SPLIT(Director, ',')) as a

select * FROM [Project1].[dbo].[Director]


/*[listed_in]*/

SELECT DISTINCT [listed_in] FROM [Project1].[dbo].netflix_titles WHERE [listed_in] IS NOT NULL ORDER BY 1

select ROW_NUMBER() OVER (ORDER BY [listed_in]) [listed_ID], [listed_in]
INTO [Project1].[dbo].Listed
	from (
	SELECT  DISTINCT trim(value) as [listed_in]
FROM [Project1].[dbo].netflix_titles  
CROSS APPLY STRING_SPLIT([listed_in], ',')) as a

select * from [Project1].[dbo].Listed

/*[CAST]*/

SELECT DISTINCT [CAST] FROM [Project1].[dbo].netflix_titles WHERE [CAST] IS NOT NULL ORDER BY 1

select ROW_NUMBER() OVER (ORDER BY [CAST]) [Actor_ID], [CAST] as Actor_Name
INTO [Project1].[dbo].Actors
	from (
	SELECT  DISTINCT trim(value) as [CAST]
FROM [Project1].[dbo].netflix_titles  
CROSS APPLY STRING_SPLIT([CAST], ',')) as a

select * from [Project1].[dbo].Actors


/*ANALYTICS*/

/*movies vs tv show*/

SELECT TYPE, COUNT(TYPE) From [Project1].[dbo].netflix_titles GROUP BY TYPE

SELECT COUNT(*)  as TOTAL From [Project1].[dbo].netflix_titles

SELECT TYPE,
		round(CONVERT(DOUBLE PRECISION, cast(COUNT(TYPE) AS decimal(6,2))/CAST((SELECT COUNT(*) From [Project1].[dbo].netflix_titles) AS  decimal(6,2))*100), 2) AS TYPE_PERCENT
From [Project1].[dbo].netflix_titles 
GROUP BY TYPE


/*RELEASE YEAR PIVOT*/

SELECT RELEASE_YEAR, TYPE, COUNT([show_id]) AS FLIX From [Project1].[dbo].netflix_titles GROUP BY RELEASE_YEAR, TYPE ORDER BY 1

 SELECT RELEASE_YEAR,[TV Show], [Movie]
From (SELECT RELEASE_YEAR, TYPE, COUNT([show_id]) AS FLIX From [Project1].[dbo].netflix_titles GROUP BY RELEASE_YEAR, TYPE 
) AS A
PIVOT
 ( 
 SUM(FLIX)
   FOR [TYPE] IN ([TV Show], [Movie])
 ) AS PivotTable 
 ORDER BY 1 DESC

/*DURATION LONGEST AND SHORTEST NETFILX FILM CTE, UNION, CASE STATEMENT*/
SELECT DISTINCT DURATION FROM [Project1].[dbo].netflix_titles ORDER BY 1

SELECT MAX(DURATION) From [Project1].[dbo].netflix_titles 

SELECT MIN(DURATION) From [Project1].[dbo].netflix_titles 

SELECT DISTINCT LEFT(DURATION,CHARINDEX(' ',DURATION)) TIM, TRIM(SUBSTRING(DURATION,CHARINDEX(' ',DURATION), 20))SPAN, DURATION  FROM [Project1].[dbo].netflix_titles ;

WITH MAX1 AS (
SELECT TOP 1 *
From (

SELECT DISTINCT
	LEFT(DURATION,CHARINDEX(' ',DURATION)) TIMING, 
	TRIM(SUBSTRING(DURATION,CHARINDEX(' ',DURATION), 20))SPAN, 
	DURATION ,
	type	,title,
	CASE WHEN TRIM(SUBSTRING(DURATION,CHARINDEX(' ',DURATION), 20)) LIKE '%Season%'
		THEN CAST(LEFT(DURATION,CHARINDEX(' ',DURATION)) AS INT)*60
		ELSE CAST(LEFT(DURATION,CHARINDEX(' ',DURATION)) AS INT)
		END AS TIMING2
FROM [Project1].[dbo].netflix_titles ) AS A 
ORDER BY TIMING2 DESC),

MIN1 AS (
SELECT TOP 1 *
From (

SELECT DISTINCT
	LEFT(DURATION,CHARINDEX(' ',DURATION)) TIMING, 
	TRIM(SUBSTRING(DURATION,CHARINDEX(' ',DURATION), 20))SPAN, 
	DURATION ,
	type	,title,
	CASE WHEN TRIM(SUBSTRING(DURATION,CHARINDEX(' ',DURATION), 20)) LIKE '%Season%'
		THEN CAST(LEFT(DURATION,CHARINDEX(' ',DURATION)) AS INT)*60
		ELSE CAST(LEFT(DURATION,CHARINDEX(' ',DURATION)) AS INT)
		END AS TIMING2
FROM [Project1].[dbo].netflix_titles ) AS A 
ORDER BY TIMING2 ASC)

SELECT DURATION, 	type	,title FROM MIN1 
UNION
SELECT DURATION, 	type	,title FROM MAX1


/*recently added*/

SELECT DISTINCT date_added FROM [Project1].[dbo].netflix_titles where date_added is not null ORDER BY 1 

SELECT year(date_added) as [YEAR], count(*) [NUM_OF_ADDS] FROM [Project1].[dbo].netflix_titles where date_added is not null group by year(date_added) ORDER BY 1 

SELECT year(date_added) as [YEAR], [TYPE],count(*) [NUM_OF_ADDS] FROM [Project1].[dbo].netflix_titles where date_added is not null group by  [TYPE],year(date_added) ORDER BY 1 

SELECT DISTINCT  '[',year(date_added),'],' FROM [Project1].[dbo].netflix_titles where date_added is not null ORDER BY 1 
FOR XML PATH('') -- FOR PIVOT

SELECT DISTINCT  'ISNULL([',year(date_added),'],0) AS ', '[',year(date_added),'],' FROM [Project1].[dbo].netflix_titles where date_added is not null ORDER BY year(date_added) 
FOR XML PATH('') -- FOR PIVOT


--PIVOT TIME
 SELECT [TYPE],ISNULL([2008],0) AS [2008],ISNULL([2009],0) AS [2009],ISNULL([2010],0) AS [2010],ISNULL([2011],0) AS [2011],ISNULL([2012],0) AS [2012],ISNULL([2013],0) AS [2013],ISNULL([2014],0) AS [2014],ISNULL([2015],0) AS [2015],ISNULL([2016],0) AS [2016],ISNULL([2017],0) AS [2017],ISNULL([2018],0) AS [2018],ISNULL([2019],0) AS [2019],ISNULL([2020],0) AS [2020],ISNULL([2021],0) AS [2021]
From (SELECT year(date_added) as [YEAR], [TYPE],count(*) [NUM_OF_ADDS] FROM [Project1].[dbo].netflix_titles where date_added is not null group by  [TYPE],year(date_added)) AS A
PIVOT
 ( 
 SUM([NUM_OF_ADDS])
   FOR [YEAR] IN ([2010],[2021],[2013],[2008],[2016],[2019],[2020],[2014],[2011],[2017],[2012],[2018],[2009],[2015])
 ) AS PivotTable 
 ORDER BY 1 DESC
