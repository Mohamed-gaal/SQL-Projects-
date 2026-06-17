/* =============================================================================
   AdventureWorks Sales EDA
   Dataset : AdventureWorks (bikes & accessories retailer)
   Dialect : T-SQL (SQL Server)
   Description : Exploratory analysis covering revenue, profit, orders,
                 returns, product performance, and monthly trends.
============================================================================= */


-- Total Revenue

SELECT
    ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductPrice), 2) AS TotalRevenue
FROM dbo.[AdventureWorks Sales Data 2020] AS s
JOIN dbo.[AdventureWorks Product Lookup] AS p ON s.ProductKey = p.ProductKey;


-- Total Profit

SELECT
    ROUND(
        SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * (p.ProductPrice - p.ProductCost)), 2
    ) AS TotalProfit
FROM dbo.[AdventureWorks Sales Data 2020] AS s
JOIN dbo.[AdventureWorks Product Lookup] AS p ON s.ProductKey = p.ProductKey;


-- Total Orders

SELECT
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders
FROM dbo.[AdventureWorks Sales Data 2020] AS s;


-- Return Rate %
-- (Total Units Returned / Total Units Ordered * 100)

SELECT
    ROUND(
        100.0 * r.TotalReturns / NULLIF(s.TotalOrders, 0),
        2
    ) AS ReturnRatePct
FROM
    (SELECT SUM(OrderQuantity) AS TotalOrders
     FROM dbo.[AdventureWorks Sales Data 2020]) AS s
CROSS JOIN
    (SELECT SUM(ReturnQuantity) AS TotalReturns
     FROM dbo.[AdventureWorks Returns Data]) AS r;


-- Orders by Category
-- (with Revenue and Return Rate)

SELECT
    cat.CategoryName,
    COUNT(DISTINCT s.OrderNumber)                                           AS TotalOrders,
    ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        100.0 * SUM(r_agg.ReturnQuantity) / NULLIF(SUM(s.OrderQuantity), 0),
        2
    )                                                                       AS ReturnRatePct
FROM dbo.[AdventureWorks Sales Data 2020] AS s
JOIN dbo.[AdventureWorks Product Lookup] AS p
    ON s.ProductKey = p.ProductKey
JOIN dbo.[AdventureWorks Product Subcategories Lookup] AS sc
    ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN dbo.[AdventureWorks Product Categories Lookup] AS cat
    ON sc.ProductCategoryKey = cat.ProductCategoryKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS ReturnQuantity
    FROM dbo.[AdventureWorks Returns Data]
    GROUP BY ProductKey
) AS r_agg ON s.ProductKey = r_agg.ProductKey
GROUP BY cat.CategoryName
ORDER BY TotalOrders DESC;


-- Top 10 Products by Orders
-- (with Revenue and Return Rate)

SELECT TOP 10
    p.ProductName,
    cat.CategoryName,
    COUNT(DISTINCT s.OrderNumber)                                           AS TotalOrders,
    SUM(s.OrderQuantity)                                                    AS TotalUnitsSold,
    ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductPrice), 2) AS TotalRevenue,
    COALESCE(SUM(r_agg.ReturnQuantity), 0)                                  AS TotalReturns,
    ROUND(
        100.0 * COALESCE(SUM(r_agg.ReturnQuantity), 0)
              / NULLIF(SUM(s.OrderQuantity), 0),
        2
    )                                                                       AS ReturnRatePct
FROM dbo.[AdventureWorks Sales Data 2020] AS s
JOIN dbo.[AdventureWorks Product Lookup] AS p
    ON s.ProductKey = p.ProductKey
JOIN dbo.[AdventureWorks Product Subcategories Lookup] AS sc
    ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN dbo.[AdventureWorks Product Categories Lookup] AS cat
    ON sc.ProductCategoryKey = cat.ProductCategoryKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS ReturnQuantity
    FROM dbo.[AdventureWorks Returns Data]
    GROUP BY ProductKey
) AS r_agg ON s.ProductKey = r_agg.ProductKey
GROUP BY p.ProductKey, p.ProductName, cat.CategoryName
ORDER BY TotalOrders DESC;


-- Most Ordered Product Type (Subcategory)

SELECT TOP 1
    sc.SubcategoryName          AS MostOrderedProductType,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders
FROM dbo.[AdventureWorks Sales Data 2020] AS s
JOIN dbo.[AdventureWorks Product Lookup] AS p
    ON s.ProductKey = p.ProductKey
JOIN dbo.[AdventureWorks Product Subcategories Lookup] AS sc
    ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
GROUP BY sc.SubcategoryName
ORDER BY TotalOrders DESC;


-- Most Returned Product Type (Subcategory)

SELECT TOP 1
    sc.SubcategoryName      AS MostReturnedProductType,
    SUM(r.ReturnQuantity)   AS TotalReturns
FROM dbo.[AdventureWorks Returns Data] AS r
JOIN dbo.[AdventureWorks Product Lookup] AS p
    ON r.ProductKey = p.ProductKey
JOIN dbo.[AdventureWorks Product Subcategories Lookup] AS sc
    ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
GROUP BY sc.SubcategoryName
ORDER BY TotalReturns DESC;


-- Monthly Orders

SELECT
    FORMAT(s.OrderDate, 'yyyy-MM')  AS YearMonth,
    COUNT(DISTINCT s.OrderNumber)   AS MonthlyOrders
FROM dbo.[AdventureWorks Sales Data 2020] AS s
GROUP BY FORMAT(s.OrderDate, 'yyyy-MM')
ORDER BY YearMonth;


-- Monthly Revenue

SELECT
    FORMAT(s.OrderDate, 'yyyy-MM')                                          AS YearMonth,
    ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductPrice), 2)  AS MonthlyRevenue
FROM dbo.[AdventureWorks Sales Data 2020] AS s
JOIN dbo.[AdventureWorks Product Lookup] AS p ON s.ProductKey = p.ProductKey
GROUP BY FORMAT(s.OrderDate, 'yyyy-MM')
ORDER BY YearMonth;


-- Monthly Returns

SELECT
    FORMAT(r.ReturnDate, 'yyyy-MM') AS YearMonth,
    SUM(r.ReturnQuantity)           AS MonthlyReturns
FROM dbo.[AdventureWorks Returns Data] AS r
GROUP BY FORMAT(r.ReturnDate, 'yyyy-MM')
ORDER BY YearMonth;


-- Revenue Growth Over Time
-- (month-over-month change and growth %)

WITH MonthlyRevenue AS (
    SELECT
        FORMAT(s.OrderDate, 'yyyy-MM')                                          AS YearMonth,
        ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductPrice), 2)  AS Revenue
    FROM dbo.[AdventureWorks Sales Data 2020] AS s
    JOIN dbo.[AdventureWorks Product Lookup] AS p ON s.ProductKey = p.ProductKey
    GROUP BY FORMAT(s.OrderDate, 'yyyy-MM')
)
SELECT
    YearMonth,
    Revenue,
    LAG(Revenue) OVER (ORDER BY YearMonth)              AS PrevMonthRevenue,
    ROUND(
        Revenue - LAG(Revenue) OVER (ORDER BY YearMonth),
        2
    )                                                   AS RevenueChange,
    ROUND(
        100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY YearMonth))
              / NULLIF(LAG(Revenue) OVER (ORDER BY YearMonth), 0),
        2
    )                                                   AS RevenueGrowthPct
FROM MonthlyRevenue
ORDER BY YearMonth;


-- Combined Monthly Summary
-- (Orders + Revenue + Returns in one view)

WITH MonthlyOrders AS (
    SELECT
        FORMAT(OrderDate, 'yyyy-MM')    AS YearMonth,
        COUNT(DISTINCT OrderNumber)     AS TotalOrders,
        SUM(OrderQuantity)              AS UnitsSold
    FROM dbo.[AdventureWorks Sales Data 2020]
    GROUP BY FORMAT(OrderDate, 'yyyy-MM')
),
MonthlyRevenue AS (
    SELECT
        FORMAT(s.OrderDate, 'yyyy-MM')                                              AS YearMonth,
        ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductPrice), 2)      AS Revenue,
        ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * p.ProductCost), 2)       AS Cost,
        ROUND(SUM(CAST(s.OrderQuantity AS DECIMAL(12,4)) * (p.ProductPrice - p.ProductCost)), 2) AS Profit
    FROM dbo.[AdventureWorks Sales Data 2020] AS s
    JOIN dbo.[AdventureWorks Product Lookup] AS p ON s.ProductKey = p.ProductKey
    GROUP BY FORMAT(s.OrderDate, 'yyyy-MM')
),
MonthlyReturns AS (
    SELECT
        FORMAT(ReturnDate, 'yyyy-MM')   AS YearMonth,
        SUM(ReturnQuantity)             AS TotalReturns
    FROM dbo.[AdventureWorks Returns Data]
    GROUP BY FORMAT(ReturnDate, 'yyyy-MM')
)
SELECT
    mo.YearMonth,
    mo.TotalOrders,
    mo.UnitsSold,
    mr.Revenue,
    mr.Cost,
    mr.Profit,
    COALESCE(ret.TotalReturns, 0)                               AS TotalReturns,
    ROUND(
        100.0 * COALESCE(ret.TotalReturns, 0) / NULLIF(mo.UnitsSold, 0),
        2
    )                                                           AS MonthlyReturnRatePct,
    LAG(mr.Revenue) OVER (ORDER BY mo.YearMonth)                AS PrevMonthRevenue,
    ROUND(
        100.0 * (mr.Revenue - LAG(mr.Revenue) OVER (ORDER BY mo.YearMonth))
              / NULLIF(LAG(mr.Revenue) OVER (ORDER BY mo.YearMonth), 0),
        2
    )                                                           AS RevenueGrowthPct
FROM MonthlyOrders AS mo
JOIN MonthlyRevenue AS mr ON mo.YearMonth = mr.YearMonth
LEFT JOIN MonthlyReturns AS ret ON mo.YearMonth = ret.YearMonth
ORDER BY mo.YearMonth;

/* ================================= END ================================= */
