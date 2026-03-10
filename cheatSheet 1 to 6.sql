/* =========================================================
   SQL PRACTICE FILE - 2

   Topics Covered:
   1. GROUP BY & HAVING
   2. User Defined Functions (UDF)
   3. ALTER TABLE Operations
   4. Subqueries
   5. Joins
   6. UNION / UNION ALL / INTERSECT
   7. Indexes
   8. Common Table Expressions (CTE)
   9. Cursors
   10. Error Handling (TRY...CATCH)
   11. Triggers
   12. Stored Procedures
========================================================= */
-- 1. GROUP BY and HAVING
---------------------------------------------------------

SELECT Age, COUNT(StudentID) AS StudentCount
FROM Students
GROUP BY Age
HAVING COUNT(StudentID) > 1;

-- 2. USER DEFINED FUNCTIONS (UDF)
---------------------------------------------------------

-- A. Scalar UDF: Calculate 10% discount

CREATE FUNCTION ufn_Discount(@Amount DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @Amount * 0.10;
END;
GO

SELECT CustomerName,
       OrderAmount,
       dbo.ufn_Discount(OrderAmount) AS Discount
FROM Orders;

-- B. Inline Table Valued Function: Recent Orders

CREATE FUNCTION ufn_RecentOrders()
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM Orders
    WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())
);
GO

SELECT * FROM dbo.ufn_RecentOrders();

-- 3. ALTER TABLE OPERATIONS
---------------------------------------------------------

-- A. Add new column

ALTER TABLE Employees
ADD Department VARCHAR(50);

SELECT * FROM Employees;

-- B. Rename Column

EXEC sp_rename 'Employees.Salary', 'MonthlySalary', 'COLUMN';

-- C. Rename Table

EXEC sp_rename 'Employees', 'Emps';

-- D. Drop Column

ALTER TABLE Employees
DROP COLUMN Email;

-- E. Drop Table

DROP TABLE Employees;


-- 4. SUBQUERIES
---------------------------------------------------------

-- A. Employees earning more than average salary

SELECT FirstName, MonthlySalary
FROM Employees
WHERE MonthlySalary >
(
    SELECT AVG(MonthlySalary)
    FROM Employees
);

-- B. Departments where an employee earns more than 60000

SELECT DepartmentID
FROM Employees
WHERE Salary > 60000
GROUP BY DepartmentID;

-- 5. JOINS
---------------------------------------------------------

-- A. INNER JOIN
-- Employees with their departments

SELECT E.FirstName,E.LastName, D.DepartmentName    
FROM Employees E
INNER JOIN Departments D
ON E.DepartmentID = D.DepartmentID;

-- B. LEFT JOIN
-- All employees even if department not assigned

SELECT E.FirstName,E.LastName,D.DepartmentName    
FROM Employees E
LEFT JOIN Departments D
ON E.DepartmentID = D.DepartmentID;

-- C. RIGHT JOIN
-- All departments even if employees not assigned

SELECT E.FirstName,E.LastName,D.DepartmentName     
FROM Employees E
RIGHT JOIN Departments D
ON E.DepartmentID = D.DepartmentID;

-- D. FULL OUTER JOIN

SELECT E.FirstName,E.LastName,D.DepartmentName    
FROM Employees E
FULL OUTER JOIN Departments D
ON E.DepartmentID = D.DepartmentID;

-- E. CROSS JOIN
-- All combinations

SELECT E.FirstName,D.DepartmentName    
FROM Employees E
CROSS JOIN Departments D;

-- F. SELF JOIN
-- Employees with their Managers

SELECT
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    M.FirstName + ' ' + M.LastName AS ManagerName
FROM Employees E
LEFT JOIN Employees M
ON E.ManagerID = M.EmployeeID;


-- 6. UNION, UNION ALL, INTERSECT
---------------------------------------------------------

CREATE TABLE Projects
(
    ProjectId INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName VARCHAR(100),
    EmployeeID INT
);

INSERT INTO Projects (ProjectName, EmployeeID)
VALUES
('Project Alpha', 2),
('Project Beta', 3),
('Project Gamma', 100);

-- A. UNION

SELECT EmployeeID FROM Employees
UNION
SELECT EmployeeID FROM Projects;

-- B. UNION ALL

SELECT EmployeeID FROM Employees
UNION ALL
SELECT EmployeeID FROM Projects;

-- C. INTERSECT

SELECT EmployeeID FROM Employees
INTERSECT
SELECT EmployeeID FROM Projects;

-- 7. INDEXES
---------------------------------------------------------

-- A. Filtered Index

CREATE NONCLUSTERED INDEX Idx_Employees_Active
ON Employees(Status)
WHERE Status = 'Active';

SELECT * FROM Employees WHERE Status = 'Active';

-- B. Covering Index

CREATE NONCLUSTERED INDEX Idx_Employees_Covering
ON Employees(Name)
INCLUDE (EmployeeID, Salary);

SELECT EmployeeID, Name, Salary
FROM Employees
WHERE Name = 'Arjun';

-- C. Composite Index

CREATE NONCLUSTERED INDEX Idx_Employees_Dept_Salary
ON Employees(DepartmentID, Salary);

SELECT * FROM Employees

WHERE DepartmentID = 10
AND Salary > 70000;

-- 8. COMMON TABLE EXPRESSIONS (CTE)
---------------------------------------------------------

-- A. Employees with salary > 60000

WITH HighestSalary AS
(
    SELECT EmployeeID, Name, Salary
    FROM Employees
    WHERE Salary > 60000
)
SELECT * FROM HighestSalary;

-- B. Average salary per department

WITH AvgSalaryPerDept AS
(
    SELECT DepartmentID,
           AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY DepartmentID
)
SELECT *
FROM AvgSalaryPerDept;

-- C. Employees with department and salary above average

WITH EmployeeWithDept AS
(
    SELECT e.EmployeeID,e.Name,e.Salary,d.DepartmentName,
    AVG(e.Salary) OVER () AS AvgSalary
    FROM Employees e
    INNER JOIN Departments d
    ON e.DepartmentID = d.DepartmentID
)
SELECT *
FROM EmployeeWithDept
WHERE Salary > AvgSalary;

-- 9. CURSORS
---------------------------------------------------------

DECLARE @EmpName VARCHAR(100);
DECLARE @Salary DECIMAL(18,2);

DECLARE Emp_Cursor CURSOR FOR
SELECT Name, Salary FROM Employee;

OPEN Emp_Cursor;

FETCH NEXT FROM Emp_Cursor
INTO @EmpName, @Salary;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Employee: ' + @EmpName +
          ' | Salary: ' + CAST(@Salary AS VARCHAR(20));

    FETCH NEXT FROM Emp_Cursor
    INTO @EmpName, @Salary;
END;

CLOSE Emp_Cursor;
DEALLOCATE Emp_Cursor;

-- 10. ERROR HANDLING (TRY...CATCH)
---------------------------------------------------------

BEGIN TRY

    BEGIN TRANSACTION;

    INSERT INTO Employee (Name, Salary)
    VALUES ('Dipak Kumar', -60000);

    IF EXISTS
    (
        SELECT * FROM Employee
        WHERE Salary < 0
    )
    BEGIN
        ROLLBACK
        PRINT 'Employee Salary cannot be negative.'
    END
    ELSE
    BEGIN
        COMMIT
        PRINT 'Employee inserted successfully.'
    END

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;

        PRINT 'Transaction rolled back.'
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10))
        PRINT 'Message: ' + ERROR_MESSAGE()
    END

END CATCH;

-- 11. TRIGGERS
---------------------------------------------------------

CREATE TABLE EmployeeAudit
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    OperationType VARCHAR(50),
    ChangeDate DATETIME DEFAULT GETDATE(),
    Details VARCHAR(255)
);


GO

CREATE TRIGGER trg_AfterInsertEmployee
ON EmployeeNew
AFTER INSERT
AS
BEGIN

    SET NOCOUNT ON;

    INSERT INTO EmployeeAudit
    (
        EmployeeID,
        OperationType,
        Details
    )
    SELECT
        EmployeeID,
        'INSERT',
        'New employee ' + Name + ' added.'
    FROM inserted;

END;

GO

-- 12. STORED PROCEDURES
---------------------------------------------------------

-- A. Stored Procedure with OUTPUT parameter

CREATE PROCEDURE GetEmployeeCountByDept
    @DepartmentID INT,
    @EmpCount INT OUTPUT
AS
BEGIN

    SELECT @EmpCount = COUNT(*)
    FROM Employees
    WHERE DepartmentID = @DepartmentID;

END;
GO


DECLARE @Count INT;

EXEC GetEmployeeCountByDept
    @DepartmentID = 10,
    @EmpCount = @Count OUTPUT;

PRINT 'Total Employees: ' + CAST(@Count AS VARCHAR(50));

-- B. Stored Procedure with TRY...CATCH
---------------------------------------------------------

CREATE PROCEDURE DeleteEmployee
    @EmployeeID INT
AS
BEGIN

    BEGIN TRY

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employees
            WHERE EmployeeID = @EmployeeID
        )
        THROW 51000,
              'Employee not found with this EmployeeID',
              1;

        DELETE FROM Employees
        WHERE EmployeeID = @EmployeeID;

    END TRY

    BEGIN CATCH

        SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;

    END CATCH

END;

GO

EXEC DeleteEmployee @EmployeeID = 10;