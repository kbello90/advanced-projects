USE vehdb;

-- 1 -- 
SELECT 
	c.state,
	COUNT(DISTINCT o.customer_id) AS customers_with_orders
FROM order_t o 
	JOIN customer_t c 
    ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY customers_with_orders DESC; 

-- 2 

SELECT
	p.vehicle_maker,
	COUNT(o.order_id) as Total_orders
FROM order_t o 
	JOIN product_t p 
		ON o.product_id = p.product_id
GROUP BY p.vehicle_maker
ORDER BY Total_orders DESC
LIMIT 5;

-- 3

SELECT state,
       vehicle_maker,
       total_orders
FROM (
    SELECT c.state,
           p.vehicle_maker,
           COUNT(o.order_id) AS total_orders,
           RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) AS rnk
    FROM order_t o
    JOIN customer_t c 
         ON o.customer_id = c.customer_id
    JOIN product_t p 
         ON o.product_id = p.product_id
    GROUP BY c.state, p.vehicle_maker
) sub
WHERE rnk = 1
ORDER BY state;

-- 4 

SELECT 
    CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
    AVG(
        CASE customer_feedback
            WHEN 'Very Bad' THEN 1
            WHEN 'Bad' THEN 2
            WHEN 'Okay' THEN 3
            WHEN 'Good' THEN 4
            WHEN 'Very Good' THEN 5
        END
    ) AS Overall_Rating
FROM order_t
GROUP BY year_quarter
ORDER BY year_quarter;


-- 5 
SELECT
    CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback IN ('Good','Very Good') THEN 1 ELSE 0 END) / COUNT(*), 2) AS satisfied_pct,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback IN ('Okay') THEN 1 ELSE 0 END) / COUNT(*), 2) AS neutral_pct,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback IN ('Bad','Very Bad') THEN 1 ELSE 0 END) / COUNT(*), 2) AS dissatisfied_pct
FROM order_t
GROUP BY year_quarter
ORDER BY year_quarter;

-- 6
WITH orders_per_quarter AS (
    SELECT 
        CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
        COUNT(order_id) AS total_orders
    FROM order_t
    GROUP BY CONCAT(YEAR(order_date), '-Q', QUARTER(order_date))
)
SELECT 
    year_quarter,
    total_orders,
    ROUND(
        ((total_orders - LAG(total_orders) OVER (ORDER BY year_quarter)) 
         / LAG(total_orders) OVER (ORDER BY year_quarter)) * 100, 2
    ) AS qoq_change_pct
FROM orders_per_quarter
ORDER BY year_quarter;

-- 7  

-- Total net revenue --
SELECT ROUND(SUM(quantity * vehicle_price * (1 - discount/100)), 2) AS net_revenue
FROM order_t;

-- Quarterly revenue and QoQ % --

WITH revenue_by_quarter AS (
  SELECT
    CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
    ROUND(SUM(quantity * vehicle_price * (1 - discount/100)), 2) AS net_revenue
  FROM order_t
  GROUP BY year_quarter
)
SELECT
  year_quarter,
  net_revenue,
  LAG(net_revenue) OVER (ORDER BY year_quarter) AS prev_revenue,
  ROUND(100.0 * (net_revenue - LAG(net_revenue) OVER (ORDER BY year_quarter))
        / NULLIF(LAG(net_revenue) OVER (ORDER BY year_quarter), 0), 2) AS qoq_change_pct
FROM revenue_by_quarter
ORDER BY year_quarter;



-- 8

WITH orders_revenue_by_quarter AS (
    SELECT 
        CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
        COUNT(*) AS total_orders,
        ROUND(SUM(quantity * vehicle_price * (1 - discount / 100)), 2) AS net_revenue
    FROM order_t
    GROUP BY year_quarter
)
SELECT 
    year_quarter,
    total_orders,
    ROUND(
        ((total_orders - LAG(total_orders) OVER (ORDER BY year_quarter)) 
         / LAG(total_orders) OVER (ORDER BY year_quarter)) * 100, 2
    ) AS orders_qoq_pct,
    net_revenue,
    ROUND(
        ((net_revenue - LAG(net_revenue) OVER (ORDER BY year_quarter)) 
         / LAG(net_revenue) OVER (ORDER BY year_quarter)) * 100, 2
    ) AS revenue_qoq_pct
FROM orders_revenue_by_quarter
ORDER BY year_quarter; 



-- 9 

SELECT
	c.credit_card_type,
    ROUND(AVG(o.discount),2) AS avg_credit_card_disc
FROM order_t o 
	JOIN customer_t c
    ON o.customer_id = c.customer_id
GROUP BY c.credit_card_type
ORDER BY avg_credit_card_disc DESC;


-- 10 

SELECT 
	CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS year_quarter,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 0) AS average_shipping_time
FROM order_t
GROUP BY year_quarter
ORDER BY year_quarter; 




