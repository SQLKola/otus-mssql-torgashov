/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
USE [WideWorldImporters]
SELECT [InvoiceMonth],[Peeples Valley, AZ], [Sylvanite, MT], [Jessie, ND], [Gasport, NY], [Medicine Lodge, KS]
FROM
     (Select  
	    SUBSTRING([CustomerName],(CHARINDEX('(',[CustomerName])+1),CHARINDEX(')',[CustomerName])-CHARINDEX('(',[CustomerName])-1) as Customer,
	    FORMAT(datefromparts(year(t2.InvoiceDate),month(t2.InvoiceDate),1), 'dd.MM.yyyy') as [InvoiceMonth],
	    t2.[InvoiceID] as CountInv
	 FROM [Sales].[Customers] t1
     JOIN [Sales].[Invoices] t2 on t1.CustomerID=t2.CustomerID
     JOIN [Sales].[CustomerTransactions] t4 on t2.InvoiceID=t4.InvoiceID
	 Where t1.CustomerID between 2 and 6	 
	 ) tt1
PIVOT (count(CountInv) FOR Customer in ([Peeples Valley, AZ], [Sylvanite, MT], [Jessie, ND], [Gasport, NY], [Medicine Lodge, KS])) as tt2
ORDER BY [InvoiceMonth]

----- Во-первых, все работает, как требуется. Это хорошо!
----- Во-вторых, сортировка как-то не очень хорошо выглядит. Она, конечно, и не требовалась, но если уж Вы решили отсортировать, то, наверное, логичнее было бы отсортировать по первому полю в календарном, а не в алфавитном смысле.
----- В-третьих (но это уже я придираюсь), раздача таблицам алиасов t1,t2 итп - немножко дурной стиль. Лучше давать им алиасы, которые несут какую-то смысловую нагрузку. А то я сижу тут и думаю: "что автор хотел сказать, пропустив t3?"
----- В-четветрых, смотрели ли Вы план запроса? Есть ли идеи по оптимизации?

	
/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT *
FROM ( 
      SELECT[CustomerID],
	        [CustomerName],
	        [DeliveryAddressLine1],
			[DeliveryAddressLine2],
			[PostalAddressLine1],
			[PostalAddressLine2]
	  FROM [Sales].[Customers]
	  Where [CustomerName] like 'Tailspin Toys%') as Customers
UNPIVOT( AllAddreses FOR [Annotation] in ([DeliveryAddressLine1],
			                              [DeliveryAddressLine2],
								          [PostalAddressLine1],
										  [PostalAddressLine2])) as unpvt

----- так работает, хорошо.

	

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT *
FROM
	(SELECT [CountryID]
		  ,[CountryName]
		  ,[IsoAlpha3Code]
		  ,CAST([IsoNumericCode] as nvarchar(3)) as [IsoNumericCode]
	FROM [Application].[Countries]) as Countries
UNPIVOT (Code FOR [Annotation] in ([IsoAlpha3Code],[IsoNumericCode] )) as t

----- замечательно!
----- хотите задание "со звездочкой"? : Сделайте так, чтобы этот список возвращался отсортированным по номеру страны (4, потом 8 итп)

	

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT distinct  t1.CustomerID,
t1.CustomerName,
ap.StockItemID,
ap.UnitPrice,
ap.InvoiceDate
FROM [Sales].[Customers] t1
CROSS APPLY (SELECT DISTINCT TOP 2 t4.[StockItemID],[StockItemName],t4.UnitPrice, Max(t6.InvoiceDate) as InvoiceDate
			 FROM [Warehouse].[StockItems] t4
			 JOIN [Sales].[InvoiceLines] t5 on t4.StockItemID=t5.StockItemID
			 JOIN [Sales].[Invoices] t6 on t5.InvoiceID=t6.InvoiceID
			                            and t1.CustomerID=t6.CustomerID
			 JOIN [Sales].[CustomerTransactions] t7 on t6.InvoiceID=t7.InvoiceID
			 GROUP BY t4.[StockItemID], [StockItemName],t4.UnitPrice
			 ORDER by t4.[UnitPrice] Desc) ap
Order by  t1.CustomerID


----- Это правильно. Я бы уточнил где-то на полях, что Вы выводите дату *последней* покупки этого товара. Это разумное предположение, которое Вы сделали, но все равно это предположение. 
----- Лучше расставить точки над ё, чтобы у людей не возникало вопросов: "Почему я вижу в отчете одну дату, а в таблице другую?"
----- Вот Вам еще вопросы для раздумий:
----- 1) Стоит ли (и если да, смогли бы Вы) переформатировать запрос так, чтобы он возвращал одну строчку per client:
-----        1	Tailspin Toys (Head Office)	215	1899.00	2014-12-24   75	345.00	2015-07-09  
-----   ?
----- 2) Что делать, если второй и третий товары имеют одинаковую цену (как, например, у кастомера номер 3?) 


