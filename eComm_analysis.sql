/*  
                               ECOMMERCE SALES DATA CLEANING AND ANALYSIS

DISCLAIMER

1. This data is taken from https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data
2. Columns Index, Date, Promotion-ids have been removed before importing as they were causing problems
3. About 42k out of 1.28 Lakh data have been imported due to hardware limitation

*/
---------------------------------------------------------------------------------------------------------------
-- VISUALIZING THE DATA
SELECT *
FROM amazonsales
limit 10;

-- DATA COUNT
SELECT COUNT(*)
FROM amazonsales; 
----------------------------------------------------------------------------------------------------------------
-- DATA CLEANING
---------------------------------------------------------------------------------------------------------------

-- 1. REMOVING COLUMNS UNNAMED: 22 AND SKU AS I FIND THEY ARE IRRELEVENT TO THIS ANALYSIS
ALTER TABLE amazonsales
DROP COLUMN Unnamed22;

ALTER TABLE amazonsales
DROP COLUMN SKU;

SELECT *
FROM amazonsales
limit 10;

---------------------------------------------------------------------------------------------------------------

-- 2. FIXING THE BLANKS IN COLUMNS COURIER STATUS, AMOUNT AND FULFILLED-BY 

-- 2.1 COURIER STATUS COLUMN 
SELECT CourierStatus, Qty, COUNT(CourierStatus) AS total
FROM amazonsales
GROUP BY CourierStatus;

-- IF QTY IS 0 UPDATING COURIER STATUS AS CANCELLED
UPDATE amazonsales
SET CourierStatus = 'Cancelled'
WHERE Qty = 0 AND CourierStatus = '';

SELECT CourierStatus, Qty, COUNT(CourierStatus) AS total
FROM amazonsales
GROUP BY CourierStatus;

-- 2.2  AMOUNT COLUMN

SELECT Amount, COUNT(Amount) AS total
FROM amazonsales
WHERE Amount = '';

-- THERE ARE 810 BLANKS. I WILL BE USING ASIN AS A REFERENCE COLUMN TO UPDATE THESE BLANKS AND VALUE WILL BE THE LATEST ONE
-- CREATING A COLUMN CALLED ROW_NUM

ALTER TABLE amazonsales
ADD COLUMN row_num INT; 

-- CREATING A TEMP TABLE
CREATE TEMPORARY TABLE temp_table AS
SELECT *, ROW_NUMBER() OVER (ORDER BY (OrderID)) AS row_num1
FROM amazonsales;

-- UPDATING AMAZONSALES WITH THE VALUES
UPDATE amazonsales t
JOIN temp_table temp ON t.OrderID = temp.OrderID
SET t.row_num = temp.row_num1;

-- DROPpING THE TEMP TABLE
DROP TEMPORARY TABLE temp_table;

SELECT *
FROM amazonsales
limit 10;

-- FILLING THE BLANKS
CREATE TEMPORARY TABLE temp_latest_amount AS
SELECT OrderID, ASIN1, Amount
FROM amazonsales
WHERE ASIN1 <> '' AND Amount <> ''
ORDER BY OrderID, ASIN1, row_num DESC;

UPDATE amazonsales AS t
LEFT JOIN (
    SELECT OrderID, ASIN1, Amount
    FROM temp_latest_amount
) AS temp
ON t.OrderID = temp.OrderID AND t.ASIN1 = temp.ASIN1
SET t.Amount = temp.Amount
WHERE t.Amount = '' OR t.Amount IS NULL;

-- Dropping the temporary table
DROP TEMPORARY TABLE temp_latest_amount;

SELECT Amount, COUNT(Amount) AS total
FROM amazonsales
WHERE Amount = '';

-- 2.3 FULFILLED-BY COLUMN
SELECT FulfilledBy, COUNT(FulfilledBy) AS total
FROM amazonsales
GROUP BY FulfilledBy;

-- THERE ARE 28339 ROWS WHICH ARE BLANK. UPDATING THEM AS "STANDARD SHIP"

UPDATE amazonsales
SET FulfilledBy = 'Standard Ship'
WHERE FulfilledBy = '';

SELECT FulfilledBy, COUNT(FulfilledBy) AS total
FROM amazonsales
GROUP BY FulfilledBy;

---------------------------------------------------------------------------------------------------------------
-- 3. STANDRADIZING THE COLUMNS SHIPCITY AND SHIPSTATE
-- 3.1 FIRST CAPITALIZING THE COLUMNS USING UPPER()
UPDATE amazonsales
SET ShipCity = UPPER(ShipCity),
	ShipState = UPPER(ShipState);

-- 3.2 UPDATING THE SHIPSTATE COLUMN WITH VALUE 'RJ' AS 'RAJASTHAN'
UPDATE amazonsales
SET ShipState = 'RAJASTHAN'
WHERE ShipState = 'RJ';

-- 3.3 UPDATING THE SHIPSTATE COLUMN WITH VALUE 'DELHI' AS 'NEW DELHI'
UPDATE amazonsales
SET ShipState = 'NEW DELHI'
WHERE ShipState = 'DELHI';

-- 3.4 UPDATING MULTIPLE VALUES IN SHIPCITY COLUMN
-- THERE WERE 963 CORRECTION TO BE DONE. HERE ARE FEW EXAMPLES
UPDATE amazonsales
SET ShipCity = 'FAGU'
WHERE ShipCity = 'SBI FAGU';

UPDATE amazonsales
SET ShipCity = 'THANE'
WHERE ShipCity IN ('THANE - MUMBAI','THANE - WEST','THANE ( MIRA BHAYANDER)','THANE 400602','THANE BHAYANDERWEST',
				   'THANE DIST','THANE MUMBAI','THANE WEST','THANE WEST ,MAJIWADE','THANE WEST, MUMBAI',
				   'THANE, MIRAROAD EAST','THANE, MUMBAI','THANE.  MUMBRA');

UPDATE amazonsales
SET ShipCity = 'NAVI MUMBAI'
WHERE ShipCity IN ('SANPADA','SANPADA SECTOR 1');

---------------------------------------------------------------------------------------------------------------
-- DATA ANALYSIS
---------------------------------------------------------------------------------------------------------------

-- 1. ORDER ANALYSIS:
-- 1.1 TOTAL NUMBER OF ORDERS:
SELECT COUNT(OrderID) AS Total_Orders
FROM amazonsales;
-- THERE ARE 42043 UNIQUE ORDERS

-- 1.2 DISTRIBUTION OF ORDERS BY SHIPPING STATUS:
SELECT Status1, COUNT(Status1) AS Total
FROM amazonsales
ORDER BY Status1 DESC;
-- THIS DATA ONLY SHOWS ORDERS WHICH HAVE BEEN SHIPPED

-- 1.3 DISTRIBUTION OF ORDERS BY COURIER STATUS:
SELECT CourierStatus, COUNT(CourierStatus) AS Total
FROM amazonsales
ORDER BY CourierStatus DESC;
-- THIS DATA ONLY SHOWS ORDERS WHICH HAVE BEEN SHIPPED


-- 2. SHIPPING ANALYSIS:
-- 2.1 MOST COMMON SHIPPING CITY:
SELECT ShipCity, COUNT(*) AS Frequency
FROM amazonsales
GROUP BY ShipCity
ORDER BY Frequency DESC
LIMIT 1;
-- BENGALURU HAS THE MOST ORDERS WITH 4223

-- 2.2 MOST COMMON SHIPPING STATE:
SELECT ShipState, COUNT(*) AS Frequency
FROM amazonsales
GROUP BY ShipState
ORDER BY Frequency DESC
LIMIT 1;
-- MAHARASHTRA HAS THE MOST ORDERS WITH 7332

-- 2.3 EXPEDITED VS STANDARD SHIPPING
SELECT ShipServiceLevel, COUNT(*) AS Total_Amount
FROM amazonsales
GROUP BY ShipServiceLevel;
-- 28012 ORDERS WERE EXPEDITED VS 14031 STANDARD ORDERS SHIPPED


-- 3. Product Category Analysis:
-- 3.1 DISTRIBUTION OF ORDERS ACROSS PRODUCT CATEGORIES
SELECT Category, COUNT(*) AS Frequency
FROM amazonsales
GROUP BY Category
ORDER BY Frequency DESC;

-- 3.2 BEST SELLING PRODUCT CATEGORIES
SELECT Category, COUNT(*) AS Total_Sales
FROM amazonsales
GROUP BY Category
ORDER BY Total_Sales DESC
LIMIT 3;
-- THE CATEGORIES 'SET(17328)', 'KURTA(16688)' AND 'WESTERN DRESS(3667) ARE THE TOP THREE

-- 3.3 REVENUE GENERATED BY EACH CATEGORY
SELECT Category, SUM(Amount) AS Total_Amount
FROM amazonsales
GROUP BY Category
ORDER BY Total_Amount DESC;
-- THE CATEGORIES 'SET(1.42 CR)', 'KURTA(72 L)' AND 'WESTERN DRESS(27 L) ARE THE TOP THREE MOST PROFITABLE CATEGORIES


-- 4. PRODUCT SIZE ANALYSIS:
-- 4.1 MOST POPULAR SIZE:
SELECT Size, COUNT(*) AS Frequency
FROM amazonsales
GROUP BY Size
ORDER BY Frequency DESC;
-- MEDIUM(7448), LARGE(7403), XL(6758) ARE THE TOP 3 MOST ORDERED SIZES

-- 4.2 REVENUE GENERATED BY EACH SIZE
SELECT Size, SUM(Amount) AS Total_Amount
FROM amazonsales
GROUP BY Size
ORDER BY Total_Amount DESC;
-- MEDIUM(47 L), LARGE(45 L) AND XL(40 L) ARE THE TOP THREE

-- 4.3 CORRELATION BTW SIZE AND AMOUNT
SELECT Size, AVG(Amount) AS AverageOrderAmount
FROM amazonsales
GROUP BY Size
ORDER BY AverageOrderAmount DESC;
-- SIZE S HAS MORE SALES VOLUME COMPARED TO ANY OTHER SIZES


-- 5. GEOGRAPHIC ANALYSIS:
-- 5.1 DISTRIBUTION OF SALES ACROSS CITIES:
SELECT ShipCity, SUM(Amount) AS Total_Amount
FROM amazonsales
GROUP BY ShipCity
ORDER BY Total_Amount DESC;
-- BENGALURU HAS THE MOST SALES WITH 25.97 L

-- 5.2 DISTRIBUTION OF SALES ACROSS STATES:
SELECT ShipState, SUM(Amount) AS Total_Amount
FROM amazonsales
GROUP BY ShipState
ORDER BY Total_Amount DESC;
-- MAHARASHTRA HAS THE MOST SALES WITH 44.89 L


-- 6. CUSTOMER LOCATION ANALYSIS TO IDENTIFY POTENTIAL MARKET EXPANSION OPPORTUNITIES:
SELECT ShipCity, ShipState, COUNT(*) AS CustomerCount
FROM amazonsales
GROUP BY ShipCity, ShipState
ORDER BY CustomerCount DESC;
-- BENGALURU AND HYDERABAD HAS THE MOST CONCENTRATION WHEREAS MODASA, NAUGACHHIA HAS THE LEAST AMOUNT OF ORDERS











