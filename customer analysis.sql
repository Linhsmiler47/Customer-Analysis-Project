USE Customer;
-- Calculate RFM and Segment
DROP VIEW IF EXISTS dbo.RFM_Segment
GO 
CREATE VIEW RFM_Segment
AS 
WITH Rfm_raw AS(
SELECT
	CustomerID, MAX(OrderDate) Recency,
	COUNT(*) Frequency,
	SUM(TotalDue) Monetary
FROM Sales.SalesOrderHeader
GROUP BY CustomerID)
	,calc_rfm AS(
	SELECT
	rfm_raw.*, NTILE(5) OVER (ORDER BY Recency) AS R_S,
	NTILE(5) OVER (ORDER BY Frequency) AS F_S,
	NTILE(5) OVER (ORDER BY Monetary) AS M_S,
	CONVERT(NVARCHAR(5),NTILE(5) OVER (ORDER BY Recency)) + CONVERT(NVARCHAR(5),NTILE(5) OVER (ORDER BY Frequency)) AS RFM_S
FROM Rfm_raw)
SELECT 
	calc_rfm.*,
	(CASE WHEN RFM_S LIKE '[1-2][1-2]'THEN 'Hibernating'
		WHEN RFM_S LIKE '[1-2][3-4]' THEN 'At risk'
		WHEN RFM_S LIKE '[1-2][5]' THEN 'Can not loose'
		WHEN RFM_S LIKE '3[1-2]' THEN 'About to sleep'
		WHEN RFM_S LIKE '33' THEN 'Need attention'
		WHEN RFM_S LIKE '[3-4][4-5]' THEN 'Loyal customers'
		WHEN RFM_S LIKE '41' THEN 'Promising'
		WHEN RFM_S LIKE '51' THEN 'New customers'
		WHEN RFM_S LIKE '[4-5][2-3]' THEN 'Potential loyalist'
		WHEN RFM_S LIKE '5[4-5]' THEN 'Champions'
		END ) AS RFM_segment 
FROM calc_rfm
GO 
--SELECT * FROM dbo.RFM_Segment
--ORDER BY Recency DESC, F_S desc

 -- Calculate CLTV Customer Lifetime Value

 --Average monthly revenue per user ARPU
 DECLARE @mindate date= (SELECT MIN(OrderDate) FROM Sales.SalesOrderHeader)
 DECLARE @ARPU FLOAT, @churn_rate FLOAT;

 WITH monthly_revenue AS 
 (SELECT
	CustomerID, DATEDIFF(MONTH,@mindate, OrderDate) AS visit_month,
	SUM(TotalDue) AS revenue
FROM Sales.SalesOrderHeader
GROUP BY CustomerID, DATEDIFF(MONTH,@mindate, OrderDate))
	,ARPU_table AS 
(SELECT 
	visit_month, AVG(revenue) AS ARPU
FROM monthly_revenue
GROUP BY visit_month)
SELECT @ARPU =  AVG(ARPU) FROM ARPU_table;
------------------------------------
 WITH monthly_visit AS
 (SELECT
	CustomerID, DATEDIFF(MONTH,@mindate, OrderDate) AS visit_month
FROM Sales.SalesOrderHeader
GROUP BY CustomerID, DATEDIFF(MONTH,@mindate, OrderDate)
)

	,churn_retain AS(
	SELECT 
	past_month.CustomerID, past_month.visit_month+1 current_month,
	CASE WHEN current_month.CustomerID IS NULL THEN 'churn' ELSE 'retained' END AS type
FROM monthly_visit past_month LEFT JOIN monthly_visit current_month
ON past_month.CustomerID = current_month.CustomerID AND 
	current_month.visit_month = past_month.visit_month+1)
	,churn_rate AS (
SELECT 
	current_month, 
	SUM(CASE type WHEN 'churn' THEN 1 ELSE 0 end)/CONVERT(FLOAT,COUNT(customerID)) AS churn_rate
FROM churn_retain
GROUP BY current_month)

SELECT @churn_rate = AVG(churn_rate) FROM churn_rate

-- CLTV
SELECT @ARPU/@churn_rate AS CLTV