--Subtask.03.01: get set of Employees [HumanResources].[Employee] contained:
-- Full name - [FullName]
-- Number of years old - [YearsOld]
-- Number of years before retirement (according to Russian Federation laws) - [YearsBeforeRetirement] Use simple 65 for man and 63 for woman 
-- Mark if the person overcome retirement age (Yes or No) - [OvercomeRetirementAge]
-- order the list by full name of employees

DECLARE @Date DATE = GETDATE();
WITH Emp AS(
           SELECT E.BusinessEntityID, 
		   DATEDIFF(yy, E.BirthDate, @Date) - 
	           CASE WHEN (MONTH(E.BirthDate) > MONTH(@Date) 
				    OR (MONTH(E.BirthDate) = MONTH(@Date) AND DAY(E.BirthDate) > DAY(@Date)))
					      THEN 1 ELSE 0 END AS Years_old,
			Gender
		    FROM HumanResources.Employee AS E
			) 
SELECT 
       Years_old,P.FirstName + ' ' + isnull (P.MiddleName,'') + ' ' + P.LastName AS FullName,
	   CASE WHEN Years_old > 65 THEN 'Yes' ELSE (CASE WHEN (Years_old > 63 AND Gender = 'F') THEN 'Yes' ELSE 'No' END) END AS OvercomeRetirementAge,
	   CASE WHEN (Years_old < 63 AND Gender = 'F') THEN (63 - Years_old) ELSE
	                                               (CASE WHEN (Years_old < 65 AND Gender = 'M') THEN (65 - Years_old) ELSE NULL END)
												   END AS YearsBeforeRetirement
FROM Emp
LEFT JOIN Person.Person AS P
ON Emp.BusinessEntityID = P.BusinessEntityID
ORDER BY P.FirstName + ' ' + isnull (P.MiddleName,'') + ' ' + P.LastName;

--Subtask.03.02: Get the list of bikes which have been bought by "Vista" cardholders
SELECT P.Name, P.Color
FROM Production.Product AS P
RIGHT JOIN 
     (SELECT SOH.SalesOrderID, CC.CardType, SOD.ProductID
	 FROM Sales.SalesOrderHeader AS SOH
	 LEFT JOIN 
	 Sales.SalesOrderDetail AS SOD
	 ON SOH.SalesOrderID = SOH.SalesOrderID
	 LEFT JOIN 
	 Sales.CreditCard AS CC
	 ON SOH.CreditCardID = CC.CreditCardID
	 WHERE CC.CardType = 'Vista') AS NT
ON NT.ProductID = P.ProductID
WHERE P.ProductSubcategoryID IN
      (SELECT PC.ProductCategoryID
	  FROM Production.ProductCategory AS PC
	  LEFT JOIN
	  Production.ProductSubcategory AS PSC
	  ON PC.ProductCategoryID = PSC.ProductCategoryID
	  WHERE PC.Name = 'Bikes');

--Subtask.03.03: For each product in Production.Product, select special offer 
SELECT P.ProductID, P.Name, NT.Description
FROM Production.Product AS P
CROSS APPLY
      (SELECT SOD.ProductID, SOD.SpecialOfferID, SO.Description, SO.DiscountPct
	  FROM Sales.SalesOrderDetail AS SOD
	  RIGHT JOIN 
	  Sales.Specialoffer AS SO
	  ON SOD.SpecialOfferID = SO.SpecialOfferID
	  WHERE SO.DiscountPct <> 0 AND SOD.ProductID = P.ProductID
	  ) AS NT;

--Subtask.03.04: Get customers and count of their orders splitted by years with order's sum more than 20 000
WITH PivotData AS
(
    SELECT P.FirstName + ' ' + isnull (P.MiddleName,'') + ' ' + P.LastName AS FullName,
	       SOH.CustomerID, 
	       YEAR(SOH.OrderDate) AS OrderYear,
		   SalesOrderID
	FROM Sales.SalesOrderHeader AS SOH
	LEFT JOIN Sales.Customer AS C
	ON SOH.CustomerID = C.CustomerID
	LEFT JOIN Person.Person AS P
	ON C.PersonID = P.BusinessEntityID
	WHERE SOH.TotalDue > 20000
)
SELECT 
FullName,  [2011], [2012], [2013], [2014]
FROM PivotData
PIVOT(COUNT (SalesOrderID) FOR OrderYear IN ([2011], [2012], [2013], [2014])) AS P
ORDER BY FullName;

--Subtask.03.05: Get list of [ProductName] in alphabetical order as a single line separated by semicolons
SELECT STRING_AGG(CAST(Production.Product.Name AS NVARCHAR(MAX)), ';') AS ProductNames
FROM Production.Product;

--Subtask.03.07:  Get a dataset consisting of the following columns: 
-- [ProductSubCategoryName] - Product subcategory name. If there is no subcategory name, display 'N/A'; 
-- [ProductName] - Product name; 
-- [ProductStandardCost] - Product standard cost; 
-- [ProductSubCategoryMaxStandardCost] - The maximum standard product cost for this product subcategory; 
-- [ProductSubCategoryMinStandardCost] - The minimum standard product cost for this product subcategory; 
-- [ProductSubCategoryAvgStandardCost]- Average standard product cost for this product subcategory; 
-- The selection must be made for those products for which the standard price is different from zero. 

SELECT ISNULL(PSC.Name,'N/A')  AS ProductSubCategoryName, 
       P.Name AS ProductName,
	   P.StandardCost,
	   MAX(P.StandardCost) OVER(PARTITION BY PSC.Name) AS ProductSubCategoryMaxStandardCost,
	   MIN(P.StandardCost) OVER(PARTITION BY PSC.Name) AS ProductSubCategoryMinStandardCost,
	   AVG (P.StandardCost) OVER(PARTITION BY PSC.Name) AS ProductSubCategoryAvgStandardCost
FROM Production.Product AS P
LEFT JOIN Production.ProductSubcategory AS PSC
ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
WHERE P.StandardCost <> 0;


--Subtask.03.08: The company wants to see the changing of the total due of orders in the different countries on the year base
SELECT T.Name AS TerritoryName,
       YEAR(SOH.OrderDate) AS OrderYear, 
	   SUM(SOH.TotalDue) OVER 
	         (PARTITION BY YEAR(SOH.OrderDate), T.Name ORDER BY T.Name, YEAR(SOH.OrderDate)) AS TotalDue,
	   SUM(SOH.TotalDue) OVER 
	         (PARTITION BY YEAR(SOH.OrderDate), T.Name ORDER BY T.Name, YEAR(SOH.OrderDate)
			 ROWS	BETWEEN	UNBOUNDED PRECEDING    AND 1 PRECEDING
			 ) AS PreviousTotalDue
FROM Sales.SalesOrderHeader AS SOH
LEFT JOIN Sales.SalesTerritory AS T
ON SOH.TerritoryID = T.TerritoryID
ORDER BY T.Name, YEAR(SOH.OrderDate);
--The resulting table doesn't aggregate results for territory names and for Years. I haven't found the solution.


--Subtask.03.09: For each PostalCode in Person.Address table, show the first address (ordered by AddressID)
WITH RankedAddress AS(
	SELECT
	   PostalCode, 
       AddressID,
	   AddressLine1, AddressLine2,
	   City,
	   ROW_NUMBER() OVER(PARTITION BY PostalCode ORDER BY AddressID) AS rnum
	FROM Person.Address
)
SELECT PostalCode, 
       AddressID,
	   AddressLine1, AddressLine2,
	   City 
FROM RankedAddress
WHERE rnum=1
ORDER BY PostalCode;

--Subtask.03.10--
WITH ProductsCTE AS(
	SELECT
	   ProductAssemblyID,
	   ComponentID,
	   EndDate,
	   0 AS D	   
	FROM Production.BillOfMaterials
			 LEFT JOIN Production.Product AS P
             ON ComponentID = P.ProductID
	WHERE P.Name = 'Road-450 Red, 60'

	UNION ALL

	SELECT
	   BOM.ProductAssemblyID,
	   BOM.ComponentID,
	   BOM.EndDate,
	   PCTE.D+1 AS D	   
	FROM ProductsCTE AS PCTE
			 JOIN Production.BillOfMaterials AS BOM
             ON PCTE.ComponentID = BOM.ProductAssemblyID
)
SELECT ComponentID, CONCAT(REPLICATE('-',D),P.Name) AS Name
FROM ProductsCTE
     LEFT JOIN Production.Product AS P
	 ON ComponentID = P.ProductID
WHERE EndDate IS NUll
;













	   
	   

			





