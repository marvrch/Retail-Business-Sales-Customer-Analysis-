-- (1) Create the Database
CREATE DATABASE ITVentureDatViz2;

USE ITVentureDatViz2;

-- (2) Preview the tables to start exploring the data
SELECT * FROM [transaction];
SELECT * FROM [customer];
SELECT * FROM [store];
SELECT * FROM [product];

-- (3) Data Analysis
-- Below are the queries that I used to answer the business questions from stakeholders.

-- 1) What is our total revenue trend over time? (Are we growing month-over-month / year-over-year?)
-- Total Revenue Trend Over Time (Quarter over Quarter)
WITH QuarterlyAgg AS(
SELECT 
	[Year] = YEAR(created_at),
	[Quarter] = DATEPART(QUARTER, created_at),
	[TotalRevenue] = SUM([total])
FROM [transaction]
GROUP BY YEAR(created_at), DATEPART(QUARTER, created_at)
),
WithPrevCalculation AS (
SELECT
	*,
	[PrevQuarterTotalRevenue] = LAG([TotalRevenue], 1) OVER(ORDER BY [Year], [Quarter])
FROM QuarterlyAgg
)
SELECT 
	*,
	[TotalRevenueDiff] = [TotalRevenue] - [PrevQuarterTotalRevenue],
	[QoQ Revenue (%)] = CASE
							WHEN [PrevQuarterTotalRevenue] IS NULL OR [PrevQuarterTotalRevenue] = 0 THEN NULL
							ELSE ROUND(([TotalRevenue] - [PrevQuarterTotalRevenue])/[PrevQuarterTotalRevenue]*100.0, 2)
						END
FROM WithPrevCalculation;


-- Total Revenue Trend Over Time (Month over Month)
WITH MonthlyAgg AS(
SELECT 
	[Year] = YEAR(created_at),
	[Month] = DATEPART(MONTH, created_at),
	[TotalRevenue] = SUM([total])
FROM [transaction]
GROUP BY YEAR(created_at), DATEPART(MONTH, created_at)
),
WithPrevCalculation AS (
SELECT
	*,
	[PrevMonthTotalRevenue] = LAG([TotalRevenue], 1) OVER(ORDER BY [Year], [Month])
FROM MonthlyAgg
)
SELECT 
	*,
	[TotalRevenueDiff] = [TotalRevenue] - [PrevMonthTotalRevenue],
	[MoM Revenue (%)] = CASE
							WHEN [PrevMonthTotalRevenue] IS NULL OR [PrevMonthTotalRevenue] = 0 THEN NULL
							ELSE ROUND(([TotalRevenue] - [PrevMonthTotalRevenue])/[PrevMonthTotalRevenue]*100.0, 2)
						END
FROM WithPrevCalculation;


---------------------------------------------------------------------------------------
-- 2) Which store type (Online, Offline, Event, Partnership) contributes the most to revenue growth?
SELECT
	[Store ID] = S.id,
	[Store Name] = S.type,
	[Total Store Revenue] = SUM(total),
	[Percentage of Contribution (%)] = SUM(total)/SUM(SUM(total)) OVER()*100.0
FROM [transaction] T
JOIN [Store] S ON T.store_id = S.id
GROUP BY S.id, S.type
ORDER BY [Total Store Revenue] DESC;



-- Breakdown by Quarter over Quarter
WITH QuarterlyAgg AS(
SELECT 
	[Year] = YEAR(created_at),
	[Quarter] = DATEPART(QUARTER, created_at),
	[Store ID] = S.id,
	[Store Name] = S.type,
	[TotalRevenue] = SUM([total])
FROM [transaction] T
JOIN [store] S ON T.store_id = S.id
GROUP BY YEAR(created_at), DATEPART(QUARTER, created_at), S.id,  S.type
),
WithPrevCalculation AS(
SELECT 
	*,
	[PrevQuarterTotalRevenue] = LAG([TotalRevenue], 1) OVER(PARTITION BY [Store ID] ORDER BY [Year], [Quarter])
	FROM QuarterlyAgg
)
SELECT 
	*,
	[TotalRevenueDiff] = [TotalRevenue] - [PrevQuarterTotalRevenue],
	[QoQRevenue (%)] = ROUND(([TotalRevenue] - [PrevQuarterTotalRevenue])/[PrevQuarterTotalRevenue]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [Store ID], [Quarter];

-- Breakdown by Month over Month
WITH MonthlyAgg AS(
SELECT
	[Year] = YEAR(created_at),
	[Month] = DATEPART(MONTH, created_at),
	[Store ID] = S.id,
	[Store Name] = S.type,
	[TotalRevenue] = SUM([total])
FROM [transaction] T
JOIN [store] S ON T.store_id = S.id
GROUP BY YEAR(created_at), DATEPART(MONTH, created_at), S.id,  S.type
),
WithPrevCalculation AS (
SELECT
	*,
	[PrevMonthTotalRevenue] = LAG([TotalRevenue], 1) OVER(PARTITION BY [Store ID] ORDER BY [Year], [Month])
	FROM MonthlyAgg
)
SELECT 
	*,
	[TotalRevenueDiff] = [TotalRevenue] - [PrevMonthTotalRevenue],
	[MoMRevenue (%)] = ROUND(([TotalRevenue] - [PrevMonthTotalRevenue])/[PrevMonthTotalRevenue]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [Store ID], [Month];


---------------------------------------------------------------------------------------
-- 3) Which cities are driving the highest revenue, and should we expand operations there?
SELECT 
	[City] = C.city,
	[Total City Revenue] = SUM(total),
	[Percentage of Contribution (%)] = (SUM(total)/SUM(SUM(total))OVER()*100.0)
FROM [transaction] T
JOIN [Customer] C ON T.customer_id = C.id
GROUP BY C.city
ORDER BY [Total City Revenue] DESC;


-- Breakdown by Quarter over Quarter
WITH QuarterlyAgg AS(
SELECT 
	[Year] = YEAR(created_at),
	[Quarter] = DATEPART(QUARTER, created_at),
	[City] = C.city,
	[TotalRevenue] = SUM([total])
FROM [transaction] T
JOIN [customer] C ON T.customer_id = C.id
GROUP BY YEAR(created_at), DATEPART(QUARTER, created_at), C.city
),
WithPrevCalculation AS (
	SELECT
		*,
		[PrevQuarterTotalRevenue] = LAG([TotalRevenue], 1) OVER(PARTITION BY [City] ORDER BY [Year], [Quarter])
	FROM QuarterlyAgg
)
SELECT 
	*,
	[TotalRevenueDiff] = [TotalRevenue] - [PrevQuarterTotalRevenue],
	[QoQRevenue (%)] = ROUND(([TotalRevenue] - [PrevQuarterTotalRevenue])/[PrevQuarterTotalRevenue]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [City], [Quarter];

-- Breakdown by Month over Month
WITH MonthlyAgg AS(
SELECT 
	[Year] = YEAR(created_at),
	[Month] = DATEPART(MONTH, created_at),
	[City] = C.city,
	[TotalRevenue] = SUM([total])
FROM [transaction] T
JOIN [customer] C ON T.customer_id = C.id
GROUP BY YEAR(created_at), DATEPART(MONTH, created_at), C.city
),
WithPrevCalculation AS(
SELECT
	*,
	[PrevMonthTotalRevenue] = LAG([TotalRevenue], 1) OVER(PARTITION BY [City] ORDER BY [Year], [Month])
	FROM MonthlyAgg
)
SELECT *,
[TotalRevenueDiff] = [TotalRevenue] - [PrevMonthTotalRevenue],
[MoMRevenue (%)] = ROUND(([TotalRevenue] - [PrevMonthTotalRevenue])/[PrevMonthTotalRevenue]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [City], [Month];


---------------------------------------------------------------------------------------
-- 4) What percentage of revenue comes from our top 10 customers (dependency risk)?
WITH RankedCustomers AS (
	SELECT 
		C.id,
		[TotalSpent] = SUM(Total),
		[rnk] = RANK() OVER(ORDER BY SUM(Total) DESC)
	FROM [customer] C
	JOIN [transaction] T ON C.id = T.customer_id
	GROUP BY C.id
), 
AllRevenue AS (
SELECT 
	[AllRevenue] = SUM(Total)
FROM [transaction] T)
SELECT 
	RC.id,
	RC.TotalSpent,
	[Percentage of Contribution (%)] = CONVERT(VARCHAR, RC.TotalSpent/AR.AllRevenue*100.0)
FROM RankedCustomers RC,  AllRevenue AR
WHERE rnk <=10;


---------------------------------------------------------------------------------------
--5) What is our Average Order Value (AOV), and how is it changing over time?
-- Basic AOV
SELECT 
	[Average Order Value (AOV)] = AVG(total)
FROM [transaction] T;

-- Breakdown by Quarter over Quarter
WITH QuarterlyAOV AS(
SELECT 
	[Year] = YEAR(created_at),
	[Quarter] = DATEPART(QUARTER, created_at),
	[Average Order Value (AOV)] = AVG(total)
FROM [transaction] T
GROUP BY YEAR(created_at), DATEPART(QUARTER, created_at)
),
WithPrevCalculation AS (
SELECT
	*,
	[PrevQuarterAOV] = LAG([Average Order Value (AOV)], 1) OVER(ORDER BY [Year], [Quarter])
FROM QuarterlyAOV
)
SELECT 
	*,
	[TotalAOVDiff] = [Average Order Value (AOV)] - [PrevQuarterAOV],
	[QoQ AOV (%)] = ROUND(([Average Order Value (AOV)] - [PrevQuarterAOV])/[PrevQuarterAOV]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [Quarter];

-- Breakdown by Month over Month
WITH MonthlyAOV AS(
SELECT 
	[Year] = YEAR(created_at),
	[Month] = DATEPART(MONTH, created_at),
	[Average Order Value (AOV)] = AVG(total)
FROM [transaction] T
GROUP BY YEAR(created_at), DATEPART(MONTH, created_at)
),
WithPrevCalculation AS (
SELECT *,
	[PrevMonthAOV] = LAG([Average Order Value (AOV)], 1) OVER(ORDER BY [Year], [Month])
FROM MonthlyAOV
)
SELECT 
	*,
	[TotalAOVDiff] = [Average Order Value (AOV)] - [PrevMonthAOV],
	[MoM AOV (%)] = ROUND(([Average Order Value (AOV)] - [PrevMonthAOV])/[PrevMonthAOV]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [Month];

---------------------------------------------------------------------------------------
-- Additional: What is our Average Basket Size, and how is it changing over time?
-- Basic Average Basket Size
SELECT 
	[Average Basket Size] = AVG(quantity*1.0)
FROM [transaction] T;

-- Breakdown by Quarter over Quarter
WITH QuarterlyABS AS(
SELECT 
	[Year] = YEAR(created_at),
	[Quarter] = DATEPART(QUARTER, created_at),
	[Average Basket Size] = AVG(quantity*1.0)
FROM [transaction] T
GROUP BY YEAR(created_at), DATEPART(QUARTER, created_at)
),
WithPrevCalculation AS (
SELECT
	*,
	[PrevQuarterAverageBasketSize] = LAG([Average Basket Size], 1) OVER(ORDER BY [Year], [Quarter])
FROM QuarterlyABS
)
SELECT 
	*,
	[AverageBasketSizeDiff] = [Average Basket Size] - [PrevQuarterAverageBasketSize],
	[QoQ Average Basket Size (%)] = ROUND(([Average Basket Size] - [PrevQuarterAverageBasketSize])/[PrevQuarterAverageBasketSize]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [Quarter];

-- Breakdown by Month over Month
WITH MonthlyABS AS(
SELECT 
	[Year] = YEAR(created_at),
	[Month] = DATEPART(MONTH, created_at),
	[Average Basket Size] = AVG(quantity*1.0)
FROM [transaction] T
GROUP BY YEAR(created_at), DATEPART(MONTH, created_at)
),
WithPrevCalculation AS (
SELECT 
	*,
	[PrevMonthAverageBasketSize] = LAG([Average Basket Size], 1) OVER(ORDER BY [Year], [Month])
FROM MonthlyABS
)
SELECT 
	*,
	[AverageBasketSizeDiff] = [Average Basket Size] - [PrevMonthAverageBasketSize],
	[MoM Average Basket Size (%)] = ROUND(([Average Basket Size] - [PrevMonthAverageBasketSize])/[PrevMonthAverageBasketSize]*100.0,2)
FROM WithPrevCalculation
ORDER BY [Year], [Month];

---------------------------------------------------------------------------------------
-- 6) Who are our most valuable customer segments (by gender, city, or behavior)?
-- A) By Gender -- Revenue, Orders, AOV, ABS, share, frequency
WITH base AS (
SELECT
	c.gender,
	t.customer_id,
	[Revenue] = total,
	[Items] = quantity
FROM [transaction] T
JOIN [customer] C ON T.customer_id = C.id 
),
agg AS (
SELECT 
	[Gender],
	[Revenue] = SUM([Revenue]),
	[Orders] = COUNT(*),
	[Items] = SUM([Items]),
	[Customers] = COUNT(DISTINCT customer_id)
FROM base
GROUP BY gender
)
SELECT
	[Gender],
	[Revenue],
	[Orders],
	[Customers],
	[AOV] = CASE 
		WHEN [Orders] = 0 THEN NULL
			ELSE ROUND([Revenue]/[Orders], 2) 
		END,
	[ABS] = CASE 
		WHEN [Orders] = 0 THEN NULL
			ELSE ROUND([Items]/[Orders], 2) 
		END,
	[FreqPerCustomer] = CASE 
		WHEN [Customers] = 0 THEN NULL
			ELSE ROUND([Orders]/[Customers]*1.0, 2)
		END,
	[Contribution Percentage (%)] = ROUND(100.0 * [Revenue]/NULLIF(SUM([Revenue]) OVER (), 0), 2)
FROM agg
ORDER BY [Revenue] DESC;

-- B) By City -- Revenue, Orders, AOV, ABS, share, frequency
WITH base AS (
SELECT
	c.city,
	t.customer_id,
	[Revenue] = total,
	[Items] = quantity
FROM [transaction] T
JOIN [customer] C ON T.customer_id = C.id 
),
agg AS (
SELECT 
	[City],
	[Revenue] = SUM([Revenue]),
	[Orders] = COUNT(*),
	[Items] = SUM([Items]),
	[Customers] = COUNT(DISTINCT customer_id)
FROM base
GROUP BY [City]
)
SELECT
	[City],
	[Revenue],
	[Orders],
	[Customers],
	[AOV] = CASE 
		WHEN [Orders] = 0 THEN NULL
			ELSE ROUND([Revenue]/[Orders], 2) 
		END,
	[ABS] = CASE 
		WHEN [Orders] = 0 THEN NULL
			ELSE ROUND([Items]/[Orders], 2) 
		END,
	[FreqPerCustomer] = CASE 
		WHEN [Customers] = 0 THEN NULL
			ELSE ROUND([Orders]/[Customers]*1.0, 2)
		END,
	[Contribution Percentage (%)] = ROUND(100.0 * [Revenue]/NULLIF(SUM([Revenue]) OVER (), 0), 2)
FROM agg
ORDER BY [Revenue] DESC;

-- C) By Behaviour -- RFM Analysis
WITH last_date AS (
SELECT 
	[max_dt] = MAX(created_at)
FROM [transaction] 
),
cust_rfm AS (
SELECT 
	T.customer_id,
	[Recency Days] = DATEDIFF(day, MAX(created_at), (SELECT [max_dt] FROM last_date)),
	[Frequency] = COUNT(DISTINCT id),
	[Monetary] = SUM(total)
FROM [transaction] T
GROUP BY T.customer_id
),
scored AS (
SELECT 
	[Customer ID] = customer_id,
	[Recency Days],
	[Frequency],
	[Monetary],
	R = NTILE(5) OVER(ORDER BY [Recency Days] DESC, customer_id),
	F = NTILE(5) OVER(ORDER BY [Frequency] ASC, customer_id),
	M = NTILE(5) OVER(ORDER BY [Monetary] ASC, customer_id)
	FROM cust_rfm
),
labeled AS (
SELECT 
	S.*,
	[RFM Sum] = R+F+M,
	Segment = 
		CASE
			WHEN R>=4 AND F>=4 AND M>=4 THEN 'Champions'
			WHEN R>=4 AND F>=3 AND M>=3 THEN 'Loyal'
			WHEN R>=3 AND F>=2 AND M>=2 THEN 'Potential'
			WHEN R<=2 AND F<=2 AND M<=2 THEN 'At-Risk'
			ELSE 'Others'
		END
FROM scored S		
)
SELECT 
	Seg.Segment,
	[Customers] = COUNT(*),
	[Revenue] = SUM(c.Monetary),
	[Avg AOV] = SUM(c.Monetary)/SUM(c.Frequency),
	[Avg Frequency] = AVG(c.Frequency),
	[Contribution Percentage (%)] = SUM(c.Monetary)*100.0/SUM(SUM(c.Monetary)) OVER()
FROM labeled Seg
JOIN cust_rfm c ON c.customer_id = Seg.[Customer ID]
GROUP BY Seg.Segment
ORDER BY [Revenue] DESC;


---------------------------------------------------------------------------------------
-- 7) What is the repeat purchase rate  how loyal are our customers?
-- A) Returning Customer Rate -- Explains % of customers in month who purchased before


-- First purchase (cohort) per customer
WITH first_purchase AS ( 
SELECT
	customer_id,
	first_date = MIN(created_at)
FROM [transaction] T
GROUP BY customer_id
),
-- Customers active in each month with their order count this month
monthly_customers AS(
SELECT
	[Year] = YEAR(created_at),
	[Month] = MONTH(created_at),
	customer_id,
	[Orders In Month] = COUNT(*)
FROM [transaction] t
GROUP BY YEAR(created_at), MONTH(created_at), customer_id
),
-- Classify new vs returning using the month start
classified AS(
SELECT
	MC.[Year],
	MC.[Month],
	MC.customer_id,
	[Is Returning] = CASE
						WHEN FP.first_date < DATEFROMPARTS(MC.[Year], MC.[Month], 1) THEN 1 ELSE 0
						END
FROM monthly_customers MC
JOIN first_purchase FP ON MC.customer_id = FP.customer_id
)
SELECT 
	[Period] = CONCAT([Year], '-', RIGHT('00' + CAST([Month] AS VARCHAR), 2)),
	[Customer This Month] = COUNT(DISTINCT customer_id),
	[Returning Customers] = SUM([Is Returning]),
	[New Customers] = COUNT(DISTINCT customer_id) - SUM([Is Returning]),
	[Returning Rate Percentage (%)] = ROUND(100.0 * SUM([Is Returning])/NULLIF(COUNT(DISTINCT customer_id),0),2)
FROM classified
GROUP BY [Year], [Month]
ORDER BY [Year], [Month]

-- B) Repeat within 30/60/90 days from the first purchase in month
-- All purchases per customer with next purchase date
WITH tx AS (
  SELECT
      customer_id,
      created_at,
      next_dt = LEAD(created_at) OVER (PARTITION BY customer_id ORDER BY created_at)
  FROM [transaction]
),
-- First-ever purchase per customer and whether they returned within X days
firsts AS (
  SELECT
      customer_id,
      first_dt = MIN(created_at)
  FROM tx
  GROUP BY customer_id
),
joined AS (
  -- join the row of the first purchase to its next_dt
  SELECT
      f.customer_id,
      f.first_dt,
      next_dt = (SELECT TOP 1 t2.next_dt
                 FROM tx t2
                 WHERE t2.customer_id = f.customer_id AND t2.created_at = f.first_dt)
  FROM firsts f
),
bucket AS (
  SELECT
      [Year]  = YEAR(first_dt),
      [Month] = MONTH(first_dt),
      returned_30 = CASE WHEN next_dt IS NOT NULL AND DATEDIFF(day, first_dt, next_dt) <= 30 THEN 1 ELSE 0 END,
      returned_60 = CASE WHEN next_dt IS NOT NULL AND DATEDIFF(day, first_dt, next_dt) <= 60 THEN 1 ELSE 0 END,
      returned_90 = CASE WHEN next_dt IS NOT NULL AND DATEDIFF(day, first_dt, next_dt) <= 90 THEN 1 ELSE 0 END
  FROM joined
)
SELECT
  Period          = CONCAT([Year], '-', RIGHT('00' + CAST([Month] AS varchar(2)), 2)),
  NewCustomers    = COUNT(*),
  Ret30Pct        = ROUND(100.0 * SUM(returned_30) / NULLIF(COUNT(*), 0), 2),
  Ret60Pct        = ROUND(100.0 * SUM(returned_60) / NULLIF(COUNT(*), 0), 2),
  Ret90Pct        = ROUND(100.0 * SUM(returned_90) / NULLIF(COUNT(*), 0), 2)
FROM bucket
GROUP BY [Year], [Month]
ORDER BY [Year], [Month];
