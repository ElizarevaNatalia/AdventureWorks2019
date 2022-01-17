USE AdventureWorks2019;

-- Subtask.02.01: get a set of products with [ProductID], [Name], [Color] 
---from [Production].[Product] table for which color is not Silver.
SELECT P.ProductID,
       P.Name,
	   P.Color
FROM Production.Product AS P
WHERE P.Color NOT LIKE 'Silver';

-- Subtask.02.02: get a set of persons modified in April, 2014 from [Person].[Person] table. 
SELECT FirstName + ' ' + isnull (MiddleName,'') + ' ' + LastName AS FullName
FROM Person.Person
WHERE ModifiedDate > '20140331' AND ModifiedDate < '20140501';


-- Subtask.02.03: get a set of persons which have “an” in their First Name and their Middle Name starts with “B”
SELECT FirstName + ' ' + isnull (MiddleName,'') + ' ' + LastName AS FullName
FROM Person.Person
WHERE FirstName LIKE '%an%' AND MiddleName LIKE 'B%'
ORDER BY FullName;


-- Subtask.02.04: Get the list of employees of Adventure Works who are still in the job candidate table
SELECT FirstName + ' ' + isnull (MiddleName,'') + ' ' + LastName AS FullName
FROM Person.Person
WHERE BusinessEntityID IN
(SELECT BusinessEntityID FROM HumanResources.Employee
INTERSECT 
SELECT BusinessEntityID FROM HumanResources.JobCandidate);


-- Subtask.02.05: Get the list of employees of Adventure Works who are still in the job candidate table
SELECT P.FirstName + ' ' + isnull (P.MiddleName,'') + ' ' + P.LastName AS FullName,
       E.JobTitle as JobTitle
FROM Person.Person as P
RIGHT JOIN HumanResources.Employee as E
ON P.BusinessEntityID = E.BusinessEntityID
WHERE E.BusinessEntityID IN
(SELECT BusinessEntityID FROM HumanResources.JobCandidate);


-- Subtask.02.06: to get list of Products which were ordered in Central region of USA with Special Offer discount
SELECT P.Name,
       NT.Territory_name,
	   NT.Description, NT.DiscountPct
FROM Production.Product AS P
RIGHT JOIN 
           (SELECT SOD.SalesOrderID, SOD.ProductID, SOD.SpecialOfferID, 
                   T.Name + ' ' + T.CountryRegionCode AS Territory_name,
		           SO.Description, SO.DiscountPct
            FROM Sales.SalesOrderHeader AS SOH
			LEFT JOIN 
			Sales.SalesOrderDetail AS SOD
			ON SOD.SalesOrderID = SOH.SalesOrderID
			LEFT JOIN
			Sales.SalesTerritory AS T
			ON SOH.TerritoryID = T.TerritoryID 
			LEFT JOIN
			Sales.SpecialOffer AS SO
			ON SOD.SpecialOfferID = SO.SpecialOfferID
			WHERE T.Name like 'Central') AS NT
ON P.ProductID = NT.ProductID
ORDER BY NT.DiscountPct, P.Name;


-- Subtask.02.07: Get list of all people whose first name starts with 'Z'  
-- and for each of them get list of namesakes (person bearing the same last name).
SELECT P1.BusinessEntityID                                                AS ID,
       P1.FirstName + ' ' + isnull (P1.MiddleName,'') + ' ' + P1.LastName AS FullName,
	   P2.BusinessEntityID                                                AS NameSakeID,
	   P2.FirstName + ' ' + isnull (P2.MiddleName,'') + ' ' + P2.LastName AS NameSakeFullName
FROM Person.Person AS P1
LEFT JOIN Person.Person AS P2
ON P1.LastName = P2.LastName
WHERE P1.FirstName like 'Z%' AND P2.FirstName <> P1.FirstName;

-- Subtask.02.08: Find shipped orders with order date fitted the timeline for a specified date
DECLARE @Date DATETIME = '20130930 00:00:00.000'
SELECT S.SalesOrderID, S.OrderDate,            
       T.Name AS TerritoryName,
	   A.City AS ShipCity
FROM Sales.SalesOrderHeader AS S
        LEFT JOIN Sales.SalesTerritory AS T
            ON S.TerritoryID = T.TerritoryID
         LEFT JOIN Person.Address AS A
            ON S.ShipToAddressID = A.AddressID
WHERE S.OrderDate >= DATEFROMPARTS(YEAR(@Date) - 1, Month(@Date), 1)
       AND S.OrderDate < DATEFROMPARTS(YEAR(@Date), Month(@Date), 1);


-- Subtask.02.09: find customer orders with places 4-10 in the list of the most valuable orders in the rating ordered by total due 
SELECT S.CustomerID, 
    N.FirstName + ' ' + isnull (N.MiddleName,'') + ' ' + N.LastName AS FullName,
	   S.OrderDate,
	   S.TotalDue
FROM Sales.SalesOrderHeader AS S
LEFT JOIN 
   (SELECT C.CustomerID, P.FirstName, P.MiddleName, P.LastName
    FROM Sales.Customer as C
    LEFT JOIN Person.Person AS P
    ON C.PersonID = P.BusinessEntityID) AS N
ON S.CustomerID = N.CustomerID
WHERE YEAR(OrderDate) = 2014 
ORDER BY S.TotalDue DESC 
OFFSET 3 rows FETCH NEXT 7 rows ONLY;

-- Subtask.02.10: Get the list of employees aged 45 
DECLARE @Date DATE = GETDATE()
SELECT P.FirstName + ' ' + isnull (P.MiddleName,'') + ' ' + P.LastName AS FullName,
       E.BirthDate,
	   YEAR(E.BirthDate) AS BirthYear,
	   DATEDIFF(yy, E.BirthDate, @Date) - 
	           CASE WHEN (MONTH(E.BirthDate) > MONTH(@Date) 
				    OR (MONTH(E.BirthDate) = MONTH(@Date) AND DAY(E.BirthDate) > DAY(@Date)))
					      THEN 1 ELSE 0 END AS Current_age
FROM HumanResources.Employee AS E
LEFT JOIN
Person.Person AS P
ON E.BusinessEntityID = P.BusinessEntityID
WHERE DATEDIFF(yy, E.BirthDate, @Date) - 
	           CASE WHEN (MONTH(E.BirthDate) > MONTH(@Date) 
				    OR (MONTH(E.BirthDate) = MONTH(@Date) AND DAY(E.BirthDate) > DAY(@Date)))
					      THEN 1 ELSE 0 END = 45
ORDER BY E.BirthDate;




       


       








