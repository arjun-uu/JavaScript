/* =========================================================
 SQL PRACTICE FILE - 1

   Topics Covered:
   1. JSON in SQL Server
   2. JSON Functions (VALUE, QUERY, OPENJSON, MODIFY)
   3. Working with JSON Arrays
   4. Real World JSON Scenarios
   5. Time-Series Data Queries
   6. Window Functions for Time-Series
   7. Temporal Tables
   8. Dynamic SQL
========================================================= */

-- 1. JSON IN SQL SERVER
---------------------------------------------------------

CREATE TABLE CustomerJSON (
    ID INT PRIMARY KEY,
    CustomerData NVARCHAR(MAX)
);

INSERT INTO CustomerJSON VALUES
(1, '{
    "CustomerName": "Aman Raj",
    "Email": "aman@example.com",
    "Country": "USA",
    "OrderAmount": 6500
}');

-- A. Extract CustomerName and Email from JSON

SELECT 
    JSON_VALUE(CustomerData, '$.CustomerName') AS CustomerName,
    JSON_VALUE(CustomerData, '$.Email') AS Email
FROM CustomerJSON;

-- B. Fetch records where Country = 'USA'

SELECT * FROM CustomerJSON
WHERE JSON_VALUE(CustomerData, '$.Country') = 'USA';

-- C. Retrieve orders where OrderAmount > 5000

SELECT j.CustomerName, j.Email,j.Country, j.OrderAmount  
FROM CustomerJSON
CROSS APPLY OPENJSON(CustomerData)
WITH (
    CustomerName NVARCHAR(50) '$.CustomerName',
    Email VARCHAR(50) '$.Email',
    Country VARCHAR(50) '$.Country',
    OrderAmount INT '$.OrderAmount'
) AS j
WHERE j.OrderAmount > 5000;

-- 2. JSON VALIDATION
---------------------------------------------------------

-- Check whether JSON is valid

SELECT UserID,ISJSON(UserProfile) AS IsValidJSON     
FROM UsersJSON;

-- Update only if JSON is valid

UPDATE UsersJSON
SET UserProfile = JSON_MODIFY(UserProfile, '$.City', 'Mohali')
WHERE ISJSON(UserProfile) = 1;

SELECT * FROM UsersJSON;

-- 3. JSON FUNCTIONS
---------------------------------------------------------

CREATE TABLE EmployeesJSON (
    EmployeeID INT PRIMARY KEY,
    EmployeeData NVARCHAR(MAX)
);

INSERT INTO EmployeesJSON VALUES
(1, '{
    "EmployeeName": "Arjun Kumar",
    "MiddleName": "Raj",
    "Designation": "Software Engineer",
    "Salary": 85000,
    "PhoneNumber": "9876543210",
    "IsActive": false,
    "Address": {
        "Street": "MG Road",
        "City": "Pune",
        "State": "MH"
    },
    "Skills": ["C++", "SQL", "React"],
    "Technologies": ["HTML", "CSS", "JavaScript", "SQL"]
}');

-- JSON_QUERY
---------------------------------------------------------

-- A. Extract Address object

SELECT JSON_QUERY(EmployeeData, '$.Address') AS Address
FROM EmployeesJSON;

-- B. Extract Skills array

SELECT JSON_QUERY(EmployeeData, '$.Skills') AS Skills
FROM EmployeesJSON;

-- OPENJSON
---------------------------------------------------------

CREATE TABLE ProductsJSON (
    ProductID INT PRIMARY KEY,
    ProductData NVARCHAR(MAX)
);

INSERT INTO ProductsJSON VALUES
(1, '{
    "Products": [
        {"ProductName": "Laptop", "Price": 70000},
        {"ProductName": "Mouse", "Price": 500},
        {"ProductName": "Keyboard", "Price": 1500}
    ]
}');

-- A. Convert JSON array into table

SELECT ProductID, ProductName,Price  
FROM ProductsJSON
CROSS APPLY OPENJSON(ProductData, '$.Products')
WITH (
    ProductName VARCHAR(50) '$.ProductName',
    Price MONEY '$.Price'
) AS json_products;

-- B. Extract key-value pairs

SELECT * FROM EmployeesJSON
CROSS APPLY OPENJSON(EmployeeData);

-- JSON_MODIFY
---------------------------------------------------------

-- A. Update PhoneNumber

UPDATE EmployeesJSON
SET EmployeeData =
    JSON_MODIFY(EmployeeData, '$.PhoneNumber', 7209016350);

-- B. Add IsActive field

UPDATE EmployeesJSON
SET EmployeeData =
    JSON_MODIFY(EmployeeData, '$.IsActive', 'true');

-- C. Remove MiddleName

UPDATE EmployeesJSON
SET EmployeeData =
    JSON_MODIFY(EmployeeData, '$.MiddleName', NULL);

-- 4. WORKING WITH JSON ARRAYS
---------------------------------------------------------

-- Extract array elements as rows

SELECT value AS Technology
FROM EmployeesJSON
CROSS APPLY OPENJSON(EmployeeData, '$.Technologies');

-- Update array index value

UPDATE EmployeesJSON
SET EmployeeData =
    JSON_MODIFY(EmployeeData, '$.Technologies[3]', 'MongoDB');

-- 5. REAL WORLD JSON SCENARIOS
---------------------------------------------------------

CREATE TABLE OrdersJSON (
    OrderID INT PRIMARY KEY,
    OrderData NVARCHAR(MAX)
);

INSERT INTO OrdersJSON VALUES
(1,'{
    "CustomerName": "Arjun",
    "Items": [
        {"ItemName": "Monitor", "Price": 12000, "Qty": 1},
        {"ItemName": "USB Cable", "Price": 500, "Qty": 2}
    ]
}'),
(2,'{
    "CustomerName": "Rahul",
    "Items": [
        {"ItemName": "Tablet", "Price": 25000, "Qty": 1}
    ]
}');

-- A. Extract items as rows

SELECT OrderID,ItemName,Price,Qty
FROM OrdersJSON
CROSS APPLY OPENJSON(OrderData, '$.Items')
WITH (
    ItemName VARCHAR(100) '$.ItemName',
    Price INT '$.Price',
    Qty INT '$.Qty'
);

-- B. Calculate total order value

SELECT  OrderID, SUM(Price * Qty) AS TotalAmount
FROM OrdersJSON
CROSS APPLY OPENJSON(OrderData, '$.Items')
WITH (
    Price INT '$.Price',
    Qty INT '$.Qty'
)
GROUP BY OrderID;

-- 6. TIME SERIES DATA
---------------------------------------------------------

-- A. Sales in last 30 days

SELECT * FROM SalesData
WHERE SaleDate >= DATEADD(DAY, -30, GETDATE());

-- B. Daily total sales

SELECT
    CAST(SaleDate AS DATE) AS SaleDay,
    SUM(Amount) AS TotalSales
FROM SalesData
GROUP BY CAST(SaleDate AS DATE)
ORDER BY SaleDay;

-- 7. FILTERING TIME BASED DATA
---------------------------------------------------------

-- Sales in current month

SELECT * FROM SalesData
WHERE MONTH(SaleDate) = MONTH(GETDATE())
AND YEAR(SaleDate) = YEAR(GETDATE());

-- Sales on weekends

SELECT * FROM SalesData
WHERE DATENAME(WEEKDAY, SaleDate) IN ('Saturday','Sunday');

-- 8. TIME SERIES ANALYTICS
---------------------------------------------------------

-- Monthly sales

SELECT
    YEAR(SaleDate) AS SaleYear,
    MONTH(SaleDate) AS SaleMonth,
    SUM(Amount) AS MonthlyTotal
FROM SalesData
GROUP BY YEAR(SaleDate), MONTH(SaleDate)
ORDER BY SaleYear, SaleMonth;

-- Highest sales day

SELECT TOP 1
    CAST(SaleDate AS DATE) AS SaleDay,
    SUM(Amount) AS TotalSales
FROM SalesData
GROUP BY CAST(SaleDate AS DATE)
ORDER BY TotalSales DESC;

-- Daily average sales

SELECT
    CAST(SaleDate AS DATE) AS SaleDay,
    AVG(Amount) AS DailyAverage
FROM SalesData
GROUP BY CAST(SaleDate AS DATE)
ORDER BY SaleDay;

-- 9. WINDOW FUNCTIONS
---------------------------------------------------------

-- A. Running total of sales

SELECT SaleDate,Amount,
    SUM(Amount) OVER (ORDER BY SaleDate) AS RunningTotal
FROM SalesData;

-- B. Previous day's sales

SELECT SaleDate, Amount,
    LAG(Amount) OVER (ORDER BY SaleDate) AS PreviousDayAmount
FROM SalesData;

-- C. Next day's sales

SELECT SaleDate, Amount,
    LEAD(Amount) OVER (ORDER BY SaleDate) AS NextDayAmount
FROM SalesData;

-- 10. TEMPORAL TABLES
---------------------------------------------------------

CREATE TABLE Employees_Temporal (
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Salary DECIMAL(10,2),

    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysEndTime   DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,

    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
)
WITH (SYSTEM_VERSIONING = ON
      (HISTORY_TABLE = dbo.Employees_Temporal_History));

GO

SELECT * FROM Employees_Temporal;
SELECT * FROM Employees_Temporal_History;

-- 11. DYNAMIC SQL
---------------------------------------------------------

DECLARE @ColumnName NVARCHAR(100);
DECLARE @Value NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);

SET @ColumnName = 'Department';
SET @Value = 'IT';

SET @SQL = 'SELECT * FROM Employee WHERE ' + @ColumnName + ' = @val';

-- Execution

EXEC(@SQL);

EXEC sp_executesql
    @SQL,
    N'@val NVARCHAR(100)',
    @val = @Value;