USE Customer;
GO
-- Import data from Adventureworks2012
--SELECT * INTO Customer.Sales.SalesOrderHeader
--FROM AdventureWorks2012.Sales.SalesOrderHeader

--SELECT * INTO Customer.Sales.SalesOrderDetail
--FROM AdventureWorks2012.Sales.SalesOrderDetail

--SELECT * INTO Customer.Sales.SalesTerritory
--FROM AdventureWorks2012.Sales.SalesTerritory

-- Create Procedure in order to import .csv file
DROP PROCEDURE IF EXISTS dbo.update_data
GO 
CREATE PROCEDURE update_data
AS 
BEGIN 

BULK INSERT Sales.SalesOrderHeader
FROM 'D:\Update data.csv'
WITH (FIRSTROW =2, FORMAT ='CSV',
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
	)
END 
GO 

SELECT * FROM Sales.SalesOrderHeader
ORDER BY OrderDate DESC

--Job Schedule execution statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
--EXEC dbo.update_data

--Check data is imported from .csv file
--SELECT * FROM Sales.SalesOrderHeader
--WHERE OrderDate> '2014-06-30'
--ORDER BY SalesorderID asc

--Delete inserted data from .csv file
--DELETE FROM Sales.SalesOrderHeader
--WHERE OrderDate> '2014-06-30'
