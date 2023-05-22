/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".
������� ����������� � �������������� ���� ������ WideWorldImporters.
����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak
�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT [StockItemName]
FROM [Warehouse].[StockItems]
WHERE [StockItemName] LIKE '%urgent%' OR [StockItemName] LIKE 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

SELECT t1.SupplierID, [SupplierName]
FROM [Purchasing].[Suppliers] t1
LEFT JOIN [Purchasing].[PurchaseOrders] t2 ON t1.SupplierID=t2.SupplierID
WHERE t2.SupplierID IS NULL

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.
���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).
�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT distinct t2.[OrderID],
FORMAT(OrderDate,'dd.MM.yyyy') AS [FormatOrderDate],
DATENAME(month,OrderDate) AS [MonthName],
DATEPART(quarter,OrderDate) AS [Quarter],
CASE WHEN month(OrderDate)<=4 THEN 1
	WHEN month(OrderDate) BETWEEN 5 AND 8 THEN 2
	WHEN month(OrderDate)>=9 THEN 3
END AS [Part],
t5.CustomerName
FROM [Sales].[OrderLines] t2
JOIN [Warehouse].[StockItems] t3 ON t2.StockItemID=t3.StockItemID
JOIN [Sales].[Orders] t4 ON t2.OrderID=t4.OrderID
JOIN [Sales].[Customers] t5 ON t4.CustomerID=t5.CustomerID
WHERE t2.[PickingCompletedWhen] IS NOT NULL AND (t3.UnitPrice>100 OR [Quantity]>20)
ORDER BY [Quarter],[Part],[FormatOrderDate]
OFFSET 1000 ROW
FETCH FIRST 100 ROWS ONLY

/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT [DeliveryMethodName], t1.ExpectedDeliveryDate, t3.SupplierName, t4.FullName
FROM [Purchasing].[PurchaseOrders] t1
JOIN [Application].[DeliveryMethods] t2 ON t1.DeliveryMethodID=t2.DeliveryMethodID
JOIN [Purchasing].[Suppliers] t3 ON t1.SupplierID=t3.SupplierID
JOIN [Application].[People] t4 ON t1.ContactPersonID=t4.PersonID
WHERE [DeliveryMethodName] IN ('Air Freight','Refrigerated Air Freight') AND [IsOrderFinalized]=1 AND t1.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'

/*
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/
SELECT TOP (10) t1.[InvoiceID], t1.InvoiceDate, t2.CustomerName AS ClientName, t3.FullName AS SalespersonName
FROM [WideWorldImporters].[Sales].[Invoices] t1
JOIN [WideWorldImporters].[Sales].[Customers] t2 ON t1.CustomerID=t2.CustomerID
JOIN [WideWorldImporters].[Application].[People] t3 ON t1.SalespersonPersonID=t3.PersonID
ORDER BY t1.InvoiceDate DESC

/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

SELECT t1.[CustomerID], t1.[CustomerName], t1.[PhoneNumber]
FROM [WideWorldImporters].[Sales].[Customers] t1
JOIN [WideWorldImporters].[Sales].[Invoices] t2 ON t1.CustomerID=t2.CustomerID
JOIN [WideWorldImporters].[Sales].[InvoiceLines] t3 ON t2.InvoiceID=t3.InvoiceID
JOIN [WideWorldImporters].[Warehouse].[StockItems] t4 ON t3.StockItemID=t4.StockItemID
WHERE t4.StockItemName = 'Chocolate frogs 250g'