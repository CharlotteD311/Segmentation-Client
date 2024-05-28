DESCRIBE customers;

SELECT * 
FROM customers 
LIMIT 5;

SELECT COUNT(*) AS NbLignes
FROM customers;

-- Recherche de la dernière date de commande dans le jeu de données
SELECT *
FROM orders
ORDER BY order_approved_at DESC;

-- Recherche des commandes de moins de 3 mois 
SELECT *
FROM orders
WHERE order_purchase_timestamp BETWEEN '2018-10-17 17:30:18' - INTERVAL 3 MONTH AND '2018-10-17 17:30:18' ;

-- Commande avec au moins 3 jours de retard
SELECT *, DATEDIFF(trial_order_delivered_customer_date_8,trial_order_estimated_delivery_date_9) AS Days_Late
FROM orders
WHERE DATEDIFF (trial_order_delivered_customer_date_8,trial_order_estimated_delivery_date_9) >= 3
    AND trial_order_delivered_customer_date_8 IS NOT NULL
    AND trial_order_estimated_delivery_date_9 IS NOT NULL;

-- Requête 1 - Olist 

SELECT * 
FROM orders
WHERE order_status = 'delivered'
	AND order_purchase_timestamp BETWEEN DATE'2018-10-17' - INTERVAL 3 MONTH AND DATE'2018-10-17' 
	AND DATEDIFF (trial_order_delivered_customer_date_8,trial_order_estimated_delivery_date_9) >= 3;
    
-- Requête 2 - Olist

WITH Order_join AS (
SELECT DISTINCT oi.seller_id, oi.order_id, oi.price, od.order_purchase_timestamp
FROM order_items AS oi
INNER JOIN orders AS od ON (oi.order_id = od.order_id)
WHERE od.order_status = 'delivered'
ORDER BY seller_id,order_id,order_purchase_timestamp),

Agg AS (SELECT seller_id, sum(price) AS TotalRev, count(order_id) AS TotalItemSolde
FROM Order_join
GROUP BY seller_id)

SELECT *
FROM Agg 
WHERE TotalRev > 100000
ORDER BY TotalItemSolde DESC;

-- Requête 3 - Olist

WITH FirstSaleDate AS (
    SELECT seller_id, MIN(order_purchase_timestamp) AS first_sale_date
    FROM orders
    JOIN order_items USING (order_id)
    WHERE order_status = 'delivered'
    GROUP BY seller_id
),
TotalSales AS (
    SELECT seller_id, COUNT(*) AS total_sales
    FROM orders
    JOIN order_items USING (order_id)
    WHERE order_status = 'delivered'
    GROUP BY seller_id
)
SELECT seller_id, seller_city, trial_seller_state_5, first_sale_date, total_sales
FROM sellers
JOIN FirstSaleDate USING (seller_id)
JOIN TotalSales USING (seller_id)
WHERE first_sale_date > '2018-07-17' 
AND total_sales > 30;

-- Requête 4 - Olist

WITH CdeSeller AS (SELECT seller_id,seller_zip_code_prefix , COUNT(order_id) AS NbCmde
FROM order_items
JOIN sellers USING (seller_id)
GROUP BY seller_id,seller_zip_code_prefix),

Score AS (SELECT seller_id, AVG(review_score) AS AvgScore
FROM order_reviews
JOIN order_items USING (order_id)
JOIN sellers USING (seller_id)
JOIN orders USING (order_id)
WHERE order_purchase_timestamp BETWEEN DATE '2018-10-17' - INTERVAL 12 MONTH AND DATE '2018-10-17'
GROUP BY seller_id
),
Combined AS (
    SELECT seller_zip_code_prefix, NbCmde, AvgScore
    FROM CdeSeller
    JOIN Score USING (seller_id)
    WHERE NbCmde > 30
)
SELECT 
    seller_zip_code_prefix, 
    AVG(AvgScore) AS FinalAvgScore,
    SUM(NbCmde) AS TotalOrders
FROM Combined
GROUP BY seller_zip_code_prefix
HAVING SUM(NbCmde) > 30
ORDER BY FinalAvgScore ASC, TotalOrders DESC
LIMIT 5;