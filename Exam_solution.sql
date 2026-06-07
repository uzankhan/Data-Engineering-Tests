USE NEXT_COLA_OLTP
GO

/*=========================================================
    Q1. List top 5 customers by total order amount.
    Retrieve the top 5 customers who have spent the most across all sales orders. 
    Show CustomerID, CustomerName, and TotalSpent.
=========================================================*/

SELECT TOP 5
    c.CustomerID,
    c.Name AS CustomerName,
    SUM(s.TotalAmount) AS TotalSpent
FROM Customer c
INNER JOIN SalesOrder s
    ON c.CustomerID = s.CustomerID
GROUP BY
    c.CustomerID,
    c.Name
ORDER BY
    TotalSpent DESC;

/*=========================================================
-- Q2. Find the number of products supplied by each supplier.
-- Display SupplierID, SupplierName, and ProductCount. 
-- Only include suppliers that have more than 10 products.
=========================================================*/

SELECT
    s.SupplierID,
    s.Name AS SupplierName,
    COUNT(DISTINCT p.ProductID) AS ProductCount
FROM 
    Supplier s
INNER JOIN 
    PurchaseOrder po ON s.SupplierID = po.SupplierID
INNER JOIN 
    PurchaseOrderDetail p ON po.OrderID = p.OrderID
GROUP BY
    s.SupplierID,
    s.Name
HAVING COUNT(DISTINCT p.ProductID) > 10
ORDER BY ProductCount DESC;

/*=========================================================
-- Q3. Identify products that have been ordered but never returned.
-- Show ProductID, ProductName, and total order quantity.
=========================================================*/

SELECT
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.Quantity) AS TotalOrderQuantity
FROM 
    dbo.Product p
INNER JOIN 
    dbo.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE 
    p.ProductID NOT IN
    (
        SELECT ProductID
        FROM ReturnDetail
    )
GROUP BY
    p.ProductID,
    p.Name
ORDER BY
    TotalOrderQuantity DESC;

/*=========================================================
-- Q4. For each category, find the most expensive product.
-- Display CategoryID, CategoryName, ProductName, and Price. 
-- Use a subquery to get the max price per category.
=========================================================*/

SELECT
    c.CategoryID,
    c.Name AS CategoryName,
    p.Name AS ProductName,
    p.Price
FROM 
    Category c
INNER JOIN 
    Product p ON c.CategoryID = p.CategoryID
WHERE 
    p.Price =
    (
        SELECT MAX(p2.Price)
        FROM Product p2
        WHERE p2.CategoryID = p.CategoryID
    )
ORDER BY c.CategoryID;

/*=========================================================
-- Q5. List all sales orders with customer name, product name, category, and supplier.
-- For each sales order, display:
-- OrderID, CustomerName, ProductName, CategoryName, SupplierName, and Quantity.
=========================================================*/

SELECT
    so.OrderID,
    c.Name AS CustomerName,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    s.Name AS SupplierName,
    sod.Quantity
FROM SalesOrder so
INNER JOIN 
    Customer c ON so.CustomerID = c.CustomerID
INNER JOIN 
    SalesOrderDetail sod ON so.OrderID = sod.OrderID
INNER JOIN 
    Product p ON sod.ProductID = p.ProductID
INNER JOIN 
    Category cat ON p.CategoryID = cat.CategoryID
LEFT JOIN 
    PurchaseOrderDetail pod ON p.ProductID = pod.ProductID
LEFT JOIN 
    PurchaseOrder po ON pod.OrderID = po.OrderID
LEFT JOIN 
    Supplier s ON po.SupplierID = s.SupplierID
ORDER BY 
    so.OrderID;

/*=========================================================
-- Q6. Find all shipments with details of warehouse, manager, and products shipped.
-- Display:
-- ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.
=========================================================*/

SELECT
    sh.ShipmentID,
    w.WarehouseID,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    sd.Quantity AS QuantityShipped,
    sh.TrackingNumber
FROM 
    Shipment sh
INNER JOIN 
    Warehouse w ON sh.WarehouseID = w.WarehouseID
LEFT JOIN 
    Employee e ON w.ManagerID = e.EmployeeID
INNER JOIN 
    ShipmentDetail sd ON sh.ShipmentID = sd.ShipmentID
INNER JOIN 
    Product p ON sd.ProductID = p.ProductID
ORDER BY 
    sh.ShipmentID;

/*=========================================================
-- Q7. Find the top 3 highest-value orders per customer using RANK(). 
-- Display CustomerID, CustomerName, OrderID, and TotalAmount.
=========================================================*/

WITH RankedOrders AS
(
    SELECT
        c.CustomerID,
        c.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER
        (
            PARTITION BY c.CustomerID
            ORDER BY so.TotalAmount DESC
        ) AS OrderRank
    FROM Customer c
    INNER JOIN SalesOrder so
        ON c.CustomerID = so.CustomerID
)

SELECT
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM RankedOrders
WHERE OrderRank <= 3
ORDER BY CustomerID, TotalAmount DESC;

/*=========================================================
-- Q8. For each product, show its sales history with the previous 
-- and next sales quantities (based on order date). 
-- Display ProductID, ProductName, OrderID, OrderDate, Quantity, PrevQuantity, and NextQuantity.
=========================================================*/

SELECT
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,

    prev.Quantity AS PrevQuantity,
    nxt.Quantity AS NextQuantity

FROM 
    Product p
INNER JOIN 
    SalesOrderDetail sod ON p.ProductID = sod.ProductID
INNER JOIN 
    SalesOrder so ON sod.OrderID = so.OrderID

LEFT JOIN 
    SalesOrderDetail prev ON prev.ProductID = sod.ProductID
    AND prev.OrderID =
    (
        SELECT MAX(sod2.OrderID)
        FROM 
            SalesOrderDetail sod2
        INNER JOIN 
            SalesOrder so2 ON sod2.OrderID = so2.OrderID
        WHERE 
            sod2.ProductID = sod.ProductID AND so2.OrderDate < so.OrderDate
    )

LEFT JOIN 
    SalesOrderDetail nxt ON nxt.ProductID = sod.ProductID AND nxt.OrderID =
    (
        SELECT MIN(sod3.OrderID)
        FROM 
            SalesOrderDetail sod3
        INNER JOIN 
            SalesOrder so3 ON sod3.OrderID = so3.OrderID
        WHERE 
            sod3.ProductID = sod.ProductID AND so3.OrderDate > so.OrderDate
    )

ORDER BY
    p.ProductID,
    so.OrderDate;
GO

/*=========================================================
Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.
=========================================================*/

CREATE OR ALTER VIEW vw_CustomerOrderSummary
AS
SELECT
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(so.OrderID) AS TotalOrders,
    SUM(so.TotalAmount) AS TotalAmountSpent,
    MAX(so.OrderDate) AS LastOrderDate
FROM 
    Customer c
LEFT JOIN 
    SalesOrder so ON c.CustomerID = so.CustomerID
GROUP BY
    c.CustomerID,
    c.Name;
GO

SELECT *
FROM vw_CustomerOrderSummary;

GO

/*=========================================================
Q10. Write a stored procedure sp_GetSupplierSales that takes a SupplierID as input
and returns the total sales amount for all products supplied by that supplier.
=========================================================*/

CREATE OR ALTER PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @SupplierID AS SupplierID,
        SUM(sod.TotalAmount) AS TotalSalesAmount
    FROM PurchaseOrder po
    INNER JOIN PurchaseOrderDetail pod
        ON po.OrderID = pod.OrderID
    INNER JOIN SalesOrderDetail sod
        ON pod.ProductID = sod.ProductID
    WHERE po.SupplierID = @SupplierID;
END;
GO


EXEC sp_GetSupplierSales @SupplierID = 1;