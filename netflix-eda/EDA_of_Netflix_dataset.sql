/* =============================================================================
   Netflix Content EDA
   Dataset : Netflix Titles & Credits (Kaggle / TMDB / UCI)
   Dialect : T-SQL (SQL Server)
   Description : Exploratory analysis covering data quality, content
                 distribution, ratings, genres, cast, and directors.
   Tables  : titles (6,002 rows), credits (77,801 rows)
============================================================================= */


-- Duplicate records check

SELECT * FROM (
    SELECT *,
           COUNT(*) OVER (PARTITION BY
               [title], [type], [description], [release_year],
               [age_certification], [runtime], [genres],
               [production_countries], [seasons], [imdb_id],
               [imdb_score], [imdb_votes], [tmdb_popularity], [tmdb_score]
           ) AS Dup_Count
    FROM titles
) AS T
WHERE Dup_Count > 1;


-- NULL count per column

SELECT
    COUNT(CASE WHEN [title]                IS NULL THEN 1 END) AS Nulls_Title,
    COUNT(CASE WHEN [type]                 IS NULL THEN 1 END) AS Nulls_Type,
    COUNT(CASE WHEN [description]          IS NULL THEN 1 END) AS Nulls_Description,
    COUNT(CASE WHEN [release_year]         IS NULL THEN 1 END) AS Nulls_Release_Year,
    COUNT(CASE WHEN [age_certification]    IS NULL THEN 1 END) AS Nulls_Age_Certification,
    COUNT(CASE WHEN [runtime]              IS NULL THEN 1 END) AS Nulls_Runtime,
    COUNT(CASE WHEN [genres]               IS NULL THEN 1 END) AS Nulls_Genres,
    COUNT(CASE WHEN [production_countries] IS NULL THEN 1 END) AS Nulls_Countries,
    COUNT(CASE WHEN [seasons]              IS NULL THEN 1 END) AS Nulls_Seasons,
    COUNT(CASE WHEN [imdb_id]              IS NULL THEN 1 END) AS Nulls_IMDB_ID,
    COUNT(CASE WHEN [imdb_score]           IS NULL THEN 1 END) AS Nulls_IMDB_Score,
    COUNT(CASE WHEN [imdb_votes]           IS NULL THEN 1 END) AS Nulls_IMDB_Votes,
    COUNT(CASE WHEN [tmdb_popularity]      IS NULL THEN 1 END) AS Nulls_TMDB_Popularity,
    COUNT(CASE WHEN [tmdb_score]           IS NULL THEN 1 END) AS Nulls_TMDB_Score,
    COUNT(*)                                                   AS Total_Records
FROM titles;


-- Movies vs Shows: count and percentage distribution

SELECT
    [type],
    COUNT(*) AS Type_Count,
    CAST((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () AS DECIMAL(5, 2)) AS Percentage_Of_Total
FROM titles
GROUP BY [type]
ORDER BY Type_Count DESC;


-- Total movies released per year

SELECT
    [release_year],
    COUNT(*) AS Total_Movies
FROM titles
WHERE [type] = 'MOVIE'
GROUP BY [release_year]
ORDER BY Total_Movies DESC;


-- Total shows released per year

SELECT
    [release_year],
    COUNT(*) AS Total_Shows
FROM titles
WHERE [type] = 'SHOW'
GROUP BY [release_year]
ORDER BY Total_Shows DESC;


-- Age certification distribution (all content)

SELECT
    [age_certification],
    COUNT(*) AS Total_Count
FROM titles
WHERE [age_certification] IS NOT NULL
GROUP BY [age_certification]
ORDER BY Total_Count DESC;


-- Top 5 most common age certifications for movies

SELECT TOP 5
    [age_certification],
    COUNT(*) AS Certification_Count
FROM titles
WHERE [type] = 'MOVIE'
  AND [age_certification] IS NOT NULL
GROUP BY [age_certification]
ORDER BY Certification_Count DESC;


-- Genre distribution
-- (genres stored as string-encoded arrays; parsed using OPENJSON)

SELECT
    J.value     AS Genre_Name,
    COUNT(*)    AS Total_Count
FROM titles AS T
CROSS APPLY OPENJSON(REPLACE(T.[genres], '''', '"')) AS J
WHERE T.[genres] IS NOT NULL
GROUP BY J.value
ORDER BY Total_Count DESC;


-- Production country distribution
-- (production_countries stored as string-encoded arrays; parsed using OPENJSON)

SELECT
    J.value     AS Country_Code,
    COUNT(*)    AS Total_Count
FROM titles AS T
CROSS APPLY OPENJSON(REPLACE(T.[production_countries], '''', '"')) AS J
WHERE T.[production_countries] IS NOT NULL
GROUP BY J.value
ORDER BY Total_Count DESC;


-- Movies with an IMDB score above the dataset average

SELECT
    [title],
    [type],
    ROUND([imdb_score], 2) AS IMDB_Score
FROM titles
WHERE [type] = 'MOVIE'
  AND [imdb_score] > (SELECT AVG([imdb_score]) FROM titles)
ORDER BY [imdb_score] DESC;


-- Top 10 highest rated movies

SELECT TOP 10
    [title],
    ROUND([imdb_score], 2)  AS IMDB_Score,
    [imdb_votes],
    ROUND([tmdb_score], 2)  AS TMDB_Score
FROM titles
WHERE [type] = 'MOVIE'
  AND [imdb_score] IS NOT NULL
ORDER BY [imdb_score] DESC;


-- Top 10 highest rated shows

SELECT TOP 10
    [title],
    ROUND([imdb_score], 2)  AS IMDB_Score,
    [imdb_votes],
    ROUND([tmdb_score], 2)  AS TMDB_Score
FROM titles
WHERE [type] = 'SHOW'
  AND [imdb_score] IS NOT NULL
ORDER BY [imdb_score] DESC;


-- Highest rated movie and show side by side

SELECT
    M.Movie_Name,
    M.Movie_IMDB_Score,
    S.Show_Name,
    S.Show_IMDB_Score
FROM (
    SELECT TOP 1
        [title]                     AS Movie_Name,
        ROUND([imdb_score], 2)      AS Movie_IMDB_Score
    FROM titles
    WHERE [type] = 'MOVIE'
      AND [imdb_score] IS NOT NULL
    ORDER BY [imdb_score] DESC, [imdb_votes] DESC
) AS M
CROSS JOIN (
    SELECT TOP 1
        [title]                     AS Show_Name,
        ROUND([imdb_score], 2)      AS Show_IMDB_Score
    FROM titles
    WHERE [type] = 'SHOW'
      AND [imdb_score] IS NOT NULL
    ORDER BY [imdb_score] DESC, [imdb_votes] DESC
) AS S;


-- Cast members of the highest-rated movie

WITH Title_Credits AS (
    SELECT
        T.[title],
        T.[type],
        T.[imdb_score],
        C.[name],
        C.[character],
        C.[role]
    FROM titles AS T
    INNER JOIN credits AS C ON T.[id] = C.[id]
)
SELECT
    [name],
    [character],
    [title],
    ROUND([imdb_score], 2) AS IMDB_Score
FROM Title_Credits
WHERE [type] = 'MOVIE'
  AND [imdb_score] = (SELECT MAX([imdb_score]) FROM titles WHERE [type] = 'MOVIE');


-- Actors with the most movie roles

WITH Title_Credits AS (
    SELECT
        T.[title],
        T.[type],
        C.[name],
        C.[character],
        C.[role]
    FROM titles AS T
    INNER JOIN credits AS C ON T.[id] = C.[id]
)
SELECT
    [name],
    COUNT(*) OVER (PARTITION BY [name])     AS Movie_Role_Count,
    [character],
    [title]
FROM Title_Credits
WHERE [type] = 'MOVIE'
  AND [role] = 'ACTOR'
ORDER BY Movie_Role_Count DESC;


-- Directors with the most movies

WITH Title_Credits AS (
    SELECT
        T.[title],
        T.[type],
        C.[name],
        C.[role]
    FROM titles AS T
    INNER JOIN credits AS C ON T.[id] = C.[id]
)
SELECT
    [name],
    COUNT(*) OVER (PARTITION BY [name])     AS Movies_Directed,
    [title]
FROM Title_Credits
WHERE [type] = 'MOVIE'
  AND [role] = 'DIRECTOR'
ORDER BY Movies_Directed DESC;


-- Shows with the most seasons

SELECT
    [title],
    SUM([seasons]) AS Total_Seasons
FROM titles
WHERE [type] = 'SHOW'
GROUP BY [title]
ORDER BY Total_Seasons DESC;

/* ================================= END ================================= */
