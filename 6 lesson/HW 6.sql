/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "06 - ������� �������".

������� ����������� � �������������� ���� ������ WideWorldImporters.

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. ������� ������ ����� ������ ����������� ������ �� ������� � 2015 ���� 
(� ������ ������ ������ �� ����� ����������, ��������� ����� � ������� ������� �������).
��������: id �������, �������� �������, ���� �������, ����� �������, ����� ����������� ������

������:
-------------+----------------------------
���� ������� | ����������� ���� �� ������
-------------+----------------------------
 2015-01-29  | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
������� ����� ����� �� ������� Invoices.
����������� ���� ������ ���� ��� ������� �������.
*/*/
USE [WideWorldImporters]

set statistics time, io on

WITH SumMonth_CTE ([Year],[MonthNum],[SumMonth])
AS 
(SELECT YEAR(t3.InvoiceDate) AS [Year],
	    MONTH(t3.InvoiceDate) AS [MonthNum],
	    SUM(t1.[ExtendedPrice]) AS [SumMonth]
FROM [Sales].[InvoiceLines] t1
JOIN [Sales].[Invoices] t3 ON t1.InvoiceID = t3.InvoiceID
JOIN [Sales].[CustomerTransactions] t4 ON t3.InvoiceID = t4.InvoiceID
WHERE YEAR(t3.InvoiceDate) >= 2015
GROUP BY YEAR(t3.InvoiceDate),
	     MONTH(t3.InvoiceDate))

SELECT t2.InvoiceID, t2.InvoiceDate,t4.CustomerName, SUM(t3.ExtendedPrice) AS SumInvoice,
(SELECT SUM([SumMonth])
	  FROM SumMonth_CTE 
	  WHERE [Year]*100+[MonthNum] <= t1.[Year]*100 + t1.MonthNum) AS [Total]
FROM SumMonth_CTE AS t1
JOIN [Sales].[Invoices] AS t2 ON t1.MonthNum = MONTH(t2.InvoiceDate) AND t1.YEAR = YEAR(t2.InvoiceDate)
JOIN [Sales].[InvoiceLines] t3 ON t2.InvoiceID = t3.InvoiceID
JOIN [Sales].[Customers] t4 ON t2.CustomerID = t4.CustomerID
GROUP BY [Year],[MonthNum],[SumMonth],t2.InvoiceID, t2.InvoiceDate, t4.CustomerName 
ORDER BY t2.InvoiceID
/*
2. �������� ������ ����� ����������� ������ � ���������� ������� � ������� ������� �������.
   �������� ������������������ �������� 1 � 2 � ������� set statistics time, io on
*/

With SumMonth_CTE ([Year],[MonthNum],[SumMonth])
AS 
(SELECT Year(t3.InvoiceDate) as [Year],
	    month(t3.InvoiceDate) as [MonthNum],
	    SUM(t1.[ExtendedPrice]) as [SumMonth]
FROM [Sales].[InvoiceLines] t1
JOIN [Sales].[Invoices] t3 on t1.InvoiceID=t3.InvoiceID
JOIN [Sales].[CustomerTransactions] t4 on t3.InvoiceID=t4.InvoiceID
Where Year(t3.InvoiceDate)>=2015
Group by Year(t3.InvoiceDate),
	     month(t3.InvoiceDate))
SELECT t1.InvoiceID, t1.InvoiceDate,t3.CustomerName,SUM(t2.ExtendedPrice) as Sum_invoice,  t4.Total
FROM [Sales].[Invoices] t1
JOIN [Sales].[InvoiceLines] t2 on t1.InvoiceID=t2.InvoiceID
JOIN [Sales].[Customers] t3 on t1.CustomerID=t3.CustomerID
JOIN (SELECT [Year],
      [MonthNum],
      [SumMonth],
      SUM([SumMonth]) OVER (ORDER BY [Year],[MonthNum]) AS Total
      FROM SumMonth_CTE) t4 on MONTH(t1.InvoiceDate)=t4.[MonthNum] and YEAR(t1.InvoiceDate)=t4.[Year]
GROUP BY t1.InvoiceID, t1.InvoiceDate,t3.CustomerName, t4.Total
ORDER BY t1.InvoiceID

/*���������� �� ���������� �� ������� �������:  ����� ������ SQL Server:
                                                ����� �� = 6094 ��, ����������� ����� = 7300 ��.

   ���������� �� �������:  ����� ������ SQL Server:
						   ����� �� = 859 ��, ����������� ����� = 1780 ��.

������ ������ � �������������� ������� ������� �������� ����� ������� � �������� ������ ��������
� ������ ������� ���� ������ ������������, ��� �� ������/*


/*
3. ������� ������ 2� ����� ���������� ��������� (�� ���������� ���������) 
� ������ ������ �� 2016 ��� (�� 2 ����� ���������� �������� � ������ ������).
*/*/*/

;WITH Quant_CTE ([MonthNum],[StockItemName],[QuanMonth],[RN])
AS
(SELECT month(t2.InvoiceDate) as [MonthNum],
	    t3.StockItemName,
	    SUM(t1.Quantity) as [QuanMonth],
	    ROW_NUMBER() OVER (partition by month(t2.InvoiceDate) ORDER BY SUM(t1.Quantity) desc) as [RN]
FROM [Sales].[InvoiceLines] t1
JOIN [Sales].[Invoices] t2 on t1.InvoiceID=t2.InvoiceID
JOIN [Warehouse].[StockItems] t3 on t1.StockItemID=t3.StockItemID
JOIN [Sales].[CustomerTransactions] t4 on t2.InvoiceID=t4.InvoiceID
Where Year(t2.InvoiceDate)=2016
GROUP BY month(t2.InvoiceDate),t3.StockItemName)

SELECT [MonthNum],StockItemName,[QuanMonth]
FROM Quant_CTE
Where [RN] in (1,2)
Order by [MonthNum],[RN]

/*
4. ������� ����� ��������
���������� �� ������� ������� (� ����� ����� ������ ������� �� ������, ��������, ����� � ����):
* ������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
* ���������� ����� ���������� ������� � �������� ����� � ���� �� �������
* ���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
* ���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� ����� 
* ���������� �� ������ � ��� �� �������� ����������� (�� �����)
* �������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items"
* ����������� 30 ����� ������� �� ���� ��� ������ �� 1 ��

��� ���� ������ �� ����� ������ ������ ��� ������������� �������.
*/

SELECT [StockItemID],
       [StockItemName],
       [Brand],
       [UnitPrice],
ROW_NUMBER() OVER  (partition by Left([StockItemName],1) order by [StockItemName]),
COUNT([StockItemID]) OVER(),
COUNT([StockItemID]) OVER(partition by Left([StockItemName],1)),
LEAD([StockItemID],1) OVER(order by [StockItemName]),
LAG([StockItemID],1) OVER(order by[StockItemName]),
LAG ([StockItemName],2,'No items') OVER(order by [StockItemName]),
NTILE(30) OVER (order by[TypicalWeightPerUnit])
FROM [Warehouse].[StockItems]

/*
5. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������.
   � ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������.
*/

;WITH lastSales_CTE (SalespersonPersonID,SalespersonPersonName,
CustomerID,CustomerName,InvoiceDate,SumInv,[RN])
AS
(SELECT t1.SalespersonPersonID,
	   t2.[FullName],
	   t1.CustomerID,
	   t3.CustomerName,
	   t1.InvoiceDate,
	   SUM(t4.ExtendedPrice) as SumInv,
	   ROW_NUMBER() OVER (partition by SalespersonPersonID order by InvoiceDate desc) as [RN]
FROM [WideWorldImporters].[Sales].[Invoices] t1
JOIN [WideWorldImporters].[Application].[People] t2 on t1.SalespersonPersonID=t2.PersonID
JOIN [WideWorldImporters].[Sales].[Customers] t3 on t1.CustomerID=t3.CustomerID
JOIN [WideWorldImporters].[Sales].[InvoiceLines] t4 on t1.InvoiceID=t4.InvoiceID
JOIN [Sales].[CustomerTransactions] t5 on t1.InvoiceID=t5.InvoiceID
GROUP BY t1.SalespersonPersonID,
	     t2.[FullName],
	     t1.CustomerID,
	     t3.CustomerName,
	     t1.InvoiceDate)
SElect SalespersonPersonID,
SalespersonPersonName,
CustomerID,
CustomerName,
InvoiceDate,
SumInv
--[RN]
FROM lastSales_CTE
Where [RN]=1 

/*
6. �������� �� ������� ������� ��� ����� ������� ������, ������� �� �������.
� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������.
*/
;WITH MY_CTE (CustomerID,CustomerName,StockItemID,UnitPrice,InvoiceDate,DR)
AS
(SELECT  t1.CustomerID,
		t1.CustomerName,
		t3.StockItemID,
		t3.UnitPrice,
		t2.InvoiceDate,
		dense_Rank() OVER (PARTITION BY t1.CustomerName ORDER BY t3.UnitPrice DESC) as DR
FROM [Sales].[Customers] t1
JOIN [Sales].[Invoices] t2 on t1.CustomerID=t2.CustomerID
JOIN [Sales].[InvoiceLines] t3 on t2.InvoiceID=t3.InvoiceID
JOIN [Sales].[CustomerTransactions] t4 on t2.InvoiceID=t4.InvoiceID)
SELECT CustomerID,CustomerName,StockItemID,UnitPrice,InvoiceDate
FROM MY_CTE
WHERE DR in (1,2)


;WITH MY_CTE (CustomerID,CustomerName,StockItemID,UnitPrice,InvoiceDate,DR)
AS
(SELECT  t1.CustomerID,
		t1.CustomerName,
		t3.StockItemID,
		t3.UnitPrice,
		t2.InvoiceDate,
		dense_Rank() OVER (PARTITION BY t1.CustomerName ORDER BY t3.UnitPrice DESC) as DR
FROM [Sales].[Customers] t1
JOIN [Sales].[Invoices] t2 on t1.CustomerID=t2.CustomerID
JOIN [Sales].[InvoiceLines] t3 on t2.InvoiceID=t3.InvoiceID
JOIN [Sales].[CustomerTransactions] t4 on t2.InvoiceID=t4.InvoiceID)
SELECT CustomerID, CustomerName, StockItemID, UnitPrice, MAX(InvoiceDate) as max_InvoiceDate
FROM MY_CTE
WHERE DR in (1,2)
GROUP BY CustomerID, CustomerName, StockItemID, UnitPrice
