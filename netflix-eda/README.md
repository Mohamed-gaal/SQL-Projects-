# 🎬 Netflix Content EDA

A SQL-based exploratory analysis of the Netflix titles and credits dataset sourced from Kaggle. The goal was to understand content distribution, audience ratings, genre and country trends, and cast/director patterns across movies and TV shows available on Netflix.

## 🎯 Project Goals

- Audit data quality: duplicates, nulls, and structural issues
- Understand the split between movies and shows on the platform
- Explore release year trends and content volume over time
- Analyse age certification and genre distributions
- Identify top-rated content and high-performing cast members and directors

## 📁 Project Structure

```
netflix-eda/
├── EDA_of_Netflix_dataset.sql   # All analysis queries
├── datasets/
│   ├── titles.csv               # 6,002 Netflix titles with metadata
│   └── credits.csv              # 77,801 cast and crew records
└── README.md
```

## 🧹 Data Notes

The dataset contains two tables joined on `id`:

- **titles** (6,002 rows, 15 columns) — title, type, description, release year, age certification, runtime, genres, production countries, seasons, IMDB/TMDB scores
- **credits** (77,801 rows, 6 columns) — person name, character, role (ACTOR / DIRECTOR), linked to titles via `id`

Genres and production countries are stored as string-encoded arrays (e.g. `['drama', 'crime']`), parsed using `OPENJSON` with string replacement.

## 📊 Queries Covered

| Query | Description |
|---|---|
| Duplicate check | Window function `COUNT(*) OVER(PARTITION BY ...)` across all columns |
| NULL audit | NULL count per column across all 15 fields |
| Movies vs Shows split | Count and percentage distribution by type |
| Movies per year | Total movies released per release year |
| Shows per year | Total shows released per release year |
| Age certification distribution | Count of titles per certification category |
| Top 5 movie certifications | Most common age ratings for movies |
| Genre counts | Total occurrences of each genre using `OPENJSON` |
| Country counts | Total occurrences of each production country using `OPENJSON` |
| Above-average IMDB movies | Movies scoring above the dataset average |
| Top 10 movies by IMDB score | Highest rated movies with vote counts |
| Top 10 shows by IMDB score | Highest rated shows with vote counts |
| Best movie & show side by side | Single-row result comparing top-rated movie and show |
| Cast of highest-rated movie | Names and characters joined from credits table |
| Most prolific actors | Actors with the most movie roles using `COUNT() OVER(PARTITION BY)` |
| Most prolific directors | Directors with the most movies directed |
| Shows with most seasons | Total seasons per show title |

## 🛠️ Tech Stack

- **Database**: SQL Server
- **SQL Features**: JOINs, CTEs, subqueries, window functions (`COUNT OVER`, `PARTITION BY`), `OPENJSON` for array parsing, `CROSS JOIN` for side-by-side comparisons, `COALESCE`, `NULLIF`

## 📌 Notes

- Genres and countries are stored as Python-style string arrays in the raw data. `OPENJSON` is used after replacing single quotes with double quotes to parse them as valid JSON.
- The `credits` table uses a surrogate `New_PK` column; the natural join key to `titles` is the `id` column.
- IMDB scores and votes contain nulls for a portion of titles — these are excluded from rating-based queries using `IS NOT NULL` filters.
- Dataset source: [Kaggle — Netflix Movies and TV Shows](https://www.kaggle.com/)
