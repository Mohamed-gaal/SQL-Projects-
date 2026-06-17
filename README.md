# 🗄️ SQL Projects

A collection of SQL-based exploratory data analysis (EDA) projects built on real-world datasets. Each project follows a consistent workflow: inspecting data quality, cleaning and validating records, and answering business or analytical questions through structured queries.

The goal is to demonstrate practical SQL skills across different domains and dataset types — from retail sales and product performance to entertainment content and audience ratings.

## 📂 Projects

| # | Project | Dataset | Focus |
|---|---|---|---|
| 1 | [AdventureWorks Sales EDA](./adventureworks-eda/) | AdventureWorks (bikes & accessories retailer) | Revenue, profit, orders, returns, monthly trends |
| 2 | [Netflix Content EDA](./netflix-eda/) | Netflix titles & credits (Kaggle/TMDB) | Content distribution, ratings, genres, cast & directors |

## 🛠️ Tech Stack

- **Database**: SQL Server
- **SQL Features used**: JOINs, aggregations, CTEs, window functions (`LAG`, `OVER`, `PARTITION BY`), subqueries, `OPENJSON` for array parsing, `FORMAT` for date grouping

## 📌 Notes

- Each project folder contains its own README with dataset details, query descriptions, and key findings.
- Raw datasets are not committed to the repository where license terms require it — download links are provided in each project's README.
- All scripts are written in T-SQL (SQL Server dialect).
