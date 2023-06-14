/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "03 - ����������, CTE, ��������� �������".
������� ����������� � �������������� ���� ������ WideWorldImporters.
����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak
�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ��� ���� �������, ��� ��������, �������� ��� �������� ��������:
--  1) ����� ��������� ������
--  2) ����� WITH (��� ����������� ������)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices.
*/

WITH Invoice_CTE ([SalespersonPersonID])
AS (SELECT [SalespersonPersonID]
    FROM [Sales].[Invoices]
    WHERE [InvoiceDate] = '2015-07-04')
SELECT [PersonID], [FullName]
FROM [Application].[People] t1 
LEFT JOIN Invoice_CTE t2 ON t1.PersonID = t2.SalespersonPersonID
WHERE [IsSalesperson] = 1 AND t2.SalespersonPersonID IS NULL


SELECT [PersonID], [FullName]
FROM [Application].[People] t1
LEFT JOIN (SELECT [SalespersonPersonID]
FROM [Sales].[Invoices]
WHERE [InvoiceDate] = '2015-07-04')t2 ON t1.PersonID = t2.SalespersonPersonID
WHERE [IsSalesperson] = 1 AND t2.SalespersonPersonID IS NULL

/*
2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.
*/

WITH StockItems_CTE ([UnitPrice],[StockItemID],[StockItemName])
AS
(SELECT MIN([UnitPrice]),
         [StockItemID],
         [StockItemName]
FROM [Warehouse].[StockItems]
GROUP BY [StockItemID],[StockItemName])
SELECT TOP (1) [StockItemID],
             [StockItemName],
             [UnitPrice]
FROM StockItems_CTE 
ORDER BY [UnitPrice]


SELECT [StockItemID],
       [StockItemName],
       [UnitPrice]
FROM [Warehouse].[StockItems] 
WHERE [UnitPrice] = (SELECT MIN([UnitPrice]) 
FROM [Warehouse].[StockItems])

/*
3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). 
*/

WITH MaxPay_CTE ([CustomerID],[TransactionAmount])
AS (SELECT TOP (5) [CustomerID],[TransactionAmount]
	FROM [Sales].[CustomerTransactions]
	ORDER BY [TransactionAmount] DESC)
SELECT t1.[CustomerID],
       [CustomerName],
       t2.TransactionAmount
FROM [Sales].[Customers] t1
JOIN MaxPay_CTE t2 ON t1.CustomerID = t2.CustomerID


SELECT t1.[CustomerID],
       [CustomerName],
       t2.TransactionAmount
FROM [Sales].[Customers] t1
JOIN (SELECT TOP (5) [CustomerID],[TransactionAmount]
FROM [Sales].[CustomerTransactions]
ORDER BY [TransactionAmount] DESC) t2 ON t1.CustomerID = t2.CustomerID


SELECT TOP (5)
       t1.[CustomerID],
       [CustomerName],
       t2.TransactionAmount
FROM [Sales].[Customers] t1
JOIN [Sales].[CustomerTransactions] t2 ON t1.CustomerID = t2.CustomerID
ORDER BY t2.TransactionAmount DESC

/*
4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, � ����� ��� ����������, 
������� ����������� �������� ������� (PackedByPersonID).
*/

WITH Expen_CTE ([StockItemID],[StockItemName])
AS 
(SELECT TOP (3) [StockItemID],[StockItemName]
FROM [Warehouse].[StockItems]
ORDER BY [UnitPrice] DESC)
SELECT DISTINCT t1.[CityID],[CityName],t6.FullName
FROM [Application].[Cities] t1
JOIN [Sales].[Customers] t2 ON t1.CityID = t2.DeliveryCityID
JOIN [Sales].[Invoices] t3 ON t2.CustomerID = t3.CustomerID
JOIN [Sales].[InvoiceLines] t4 ON t4.InvoiceID = t3.InvoiceID
JOIN Expen_CTE t5 ON t4.StockItemID = t5.StockItemID
JOIN [Application].[People] t6 ON t3.PackedByPersonID = t6.PersonID


SELECT DISTINCT t1.[CityID],[CityName],t6.FullName
FROM [Application].[Cities] t1
JOIN [Sales].[Customers] t2 ON t1.CityID = t2.DeliveryCityID
JOIN [Sales].[Invoices] t3 ON t2.CustomerID = t3.CustomerID
JOIN [Sales].[InvoiceLines] t4 ON t4.InvoiceID = t3.InvoiceID
JOIN (SELECT TOP (3) [StockItemID],[StockItemName]
      FROM [Warehouse].[StockItems]
      ORDER BY [UnitPrice] DESC) t5 ON t4.StockItemID = t5.StockItemID
JOIN [Application].[People] t6 ON t3.PackedByPersonID = t6.PersonID

-- ---------------------------------------------------------------------------
-- ������������ �������
-- ---------------------------------------------------------------------------
-- ����� ��������� ��� � ������� ��������� ������������� �������, 
-- ��� � � ������� ��������� �����\���������. 
-- �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. 
-- ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
-- �������� ���� ����������� �� ������ �����������. 

-- 5. ���������, ��� ������ � ������������� ������

SELECT Invoices.InvoiceID, Invoices.InvoiceDate,
(SELECT People.FullName
	FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
JOIN (SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
�������� ����� ���� �������