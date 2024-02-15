USE Customer;
--Using dynamic SQL for dynamic parameter Mcode
DROP PROCEDURE IF EXISTS dbo.Pro_Filter
GO
CREATE PROCEDURE Pro_Filter (@s_date DATE = '2011-01-01',@peri INT = 12, @kind NVARCHAR(20) ='per', @period NVARCHAR(20)='Month')
AS
BEGIN
	DECLARE @sqlToExecute NVARCHAR(MAX)=''
	DECLARE @sqlkind NVARCHAR(MAX)=''
	DECLARE @sqlselect NVARCHAR(MAX)='';
	IF (@kind ='average')
		BEGIN 
			SET @sqlkind = 'AVG(tb2.TotalDue)'
			SET @sqlselect = 'SELECT * FROM cohort_size'
		END 

	ELSE IF (@kind ='count')
		BEGIN 
			SET @sqlkind = 'COUNT(DISTINCT tb2.CustomerID)' 
			SET @sqlselect = 'SELECT * FROM cohort_size'
		END 
	ELSE 
		BEGIN 
			SET @sqlkind = 'COUNT(DISTINCT tb2.CustomerID)' 
			SET @sqlselect='SELECT 
			start_date, end_date, N_th, Name_th,
			CONVERT(FLOAT,Value_)/FIRST_VALUE(Value_) OVER (PARTITION BY start_date ORDER BY N_th) Value_
			FROM cohort_size'
		END 
	SET @sqlToExecute = N'
	DECLARE @maxdate DATE = (SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader);
	
	WITH first_date AS (
	SELECT
		CustomerID, MIN(OrderDate) first_date
	FROM Sales.SalesOrderHeader
	GROUP BY CustomerID
	),
		hie_data AS
	(
		SELECT @s_date AS start_date,
		DATEADD(DAY,-1,DATEADD('+@period+',1,@s_date)) end_date
		UNION ALL 
		SELECT
			DATEADD('+@period+',1,cte.start_date) AS start_date,
			DATEADD(DAY,-1,DATEADD('+@period+',2,cte.start_date)) end_date
		FROM hie_data cte
		WHERE cte.end_date< @maxdate
	),
		data_cus AS (
	SELECT
		cte.start_date, cte.end_date, h.OrderDate, h.CustomerID, h.TotalDue
	FROM hie_data cte INNER JOIN Sales.SalesOrderHeader h
	ON h.OrderDate>= cte.start_date AND h.OrderDate<= cte.end_date),
	cohort_size AS(
	SELECT 
		tb2.start_date, tb2.end_date,
		DATEDIFF('+@period+',tb2.start_date,tb3.start_date) N_th,
		@period +'' ''+ CONVERT(NVARCHAR(10),DATEDIFF('+@period+',tb2.start_date,tb3.start_date)) Name_th,
		'+@sqlkind+' AS value_
	FROM first_date tb1 INNER JOIN data_cus tb2 
	ON tb2.CustomerID = tb1.CustomerID AND tb1.first_date >= tb2.start_date AND tb1.first_date<= tb2.end_date
	INNER JOIN data_cus tb3
	ON tb2.start_date<= tb3.start_date AND DATEADD('+@period+',12,tb2.start_date)>= tb3.start_date AND tb2.CustomerID = tb3.CustomerID
	GROUP BY tb2.start_date, tb2.end_date,
		DATEDIFF('+@period+',tb2.start_date,tb3.start_date),
		@period +'' ''+ CONVERT(NVARCHAR(10),DATEDIFF('+@period+',tb2.start_date,tb3.start_date)))
		'+@sqlselect+''

EXEC sp_executesql @sqlToExecute, N'@s_date DATE ,@peri INT, @kind NVARCHAR(20), @period NVARCHAR(20)', @s_date,@peri, @kind, @period

WITH RESULT SETS
(
       (
       start_date date, end_date DATE,
       N_th INT, Name_th NVARCHAR(10), Value_ FLOAT
       ) 
)
END 
GO

EXEC dbo.Pro_Filter @peri = 12, @period ='Month', @kind = 'count'