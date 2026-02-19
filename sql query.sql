CREATE DATABASE sql_python_project;
USE sql_python_project;

-- ---customer table----- 
drop table customers;
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

DESC customers;

-- SELLERS TABLE 

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

-- PRODUCT TABLE

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- ORDERS TABLE

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- ORDER_ITEMS

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),

    PRIMARY KEY (order_id, order_item_id),

    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);


-- PAYMENTS

CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),

    PRIMARY KEY (order_id, payment_sequential),

    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- GEOLOCATION

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);


SHOW TABLES;

-- SET FOREIGN_KEY_CHECKS = 0;


-- SET FOREIGN_KEY_CHECKS = 1;

-- TRUNCATE TABLE order_items;

-- TRUNCATE TABLE payments;
-- TRUNCATE TABLE order_items;
-- TRUNCATE TABLE customers;

-- TRUNCATE TABLE geolocation;

select * from geolocation;
SELECT COUNT(*) FROM geolocation;

SELECT COUNT(*) FROM order_items;

SELECT COUNT(*) FROM products;



#BASIC PROBLEMS
-- 1. List all unique cities where customers are located

SELECT DISTINCT customer_city, customer_state
FROM customers
ORDER BY customer_state, customer_city;


--  2. Count the number of orders placed in 2017

SELECT COUNT(*) AS total_orders_2017
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2017;

-- 3. Find the total sales per category. 

SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC;

-- 4. Calculate the percentage of orders that were paid in installments. 

SELECT 
    ROUND(
        (COUNT(DISTINCT CASE 
            WHEN payment_installments > 1 THEN order_id 
        END) 
        / COUNT(DISTINCT order_id)) * 100, 2
    ) AS installment_percentage
FROM payments;

-- 5. Count the number of customers from each state.

SELECT 
    customer_state,
    COUNT(customer_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;



-- ----------------------------------------------------------
-- INTERMEDIATE PROBLEMS: 

-- ---------------------------------------------------------
-- INTERMEDIATE PROBLEM 1:
-- Calculate number of orders per month in 2018.
-- Objective:
-- Analyze monthly sales trend for 2018.
-- ---------------------------------------------------------
SELECT 
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(order_id) AS total_orders
FROM orders
WHERE order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp < '2019-01-01'
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------
-- INTERMEDIATE PROBLEM 2:
-- Find average number of products per order, grouped by customer city.
-- Objective:
-- Understand purchasing behavior across different cities.
-- ---------------------------------------------------------

SELECT 
    c.customer_city,
    ROUND(AVG(order_product_count), 2) AS avg_products_per_order
FROM (
    SELECT 
        o.order_id,
        o.customer_id,
        COUNT(oi.product_id) AS order_product_count
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
) AS order_summary
JOIN customers c
    ON order_summary.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY avg_products_per_order DESC;



-- ---------------------------------------------------------
-- INTERMEDIATE PROBLEM 3:
-- Calculate percentage of total revenue contributed by each product category.
-- Objective:
-- Identify top revenue-generating categories.
-- ---------------------------------------------------------

SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales,
    ROUND(
        (SUM(oi.price + oi.freight_value) /
        (SELECT SUM(price + freight_value) FROM order_items)) * 100,
    2) AS revenue_percentage
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue_percentage DESC;



-- ---------------------------------------------------------
-- INTERMEDIATE PROBLEM 4:
-- Identify correlation between product price and number of times purchased.
-- Objective:
-- Analyze relationship between product pricing and purchase frequency.
-- ---------------------------------------------------------

SELECT 
    p.product_id,
    ROUND(AVG(oi.price), 2) AS avg_price,
    COUNT(oi.product_id) AS purchase_count
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_id
ORDER BY purchase_count DESC;



-- ---------------------------------------------------------
-- INTERMEDIATE PROBLEM 5:
-- Calculate total revenue generated by each seller and rank them.
-- Objective:
-- Identify top-performing sellers based on revenue.
-- ---------------------------------------------------------

SELECT 
    s.seller_id,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(oi.price + oi.freight_value) DESC) AS seller_rank
FROM order_items oi
JOIN sellers s
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_id;




-- =========================================================
-- ADVANCED LEVEL PROBLEMS


-- ---------------------------------------------------------
-- ADVANCED PROBLEM 1:
-- Calculate moving average of order value for each customer.
-- Objective:
-- Track customer spending trend over time.
-- ---------------------------------------------------------

SELECT 
    o.customer_id,
    o.order_purchase_timestamp,
    SUM(oi.price + oi.freight_value) AS order_value,
    ROUND(
        AVG(SUM(oi.price + oi.freight_value)) 
        OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_purchase_timestamp
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
    2) AS moving_avg_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp
ORDER BY o.customer_id, o.order_purchase_timestamp;





-- ---------------------------------------------------------
-- ADVANCED PROBLEM 2:
-- Calculate cumulative monthly sales per year.
-- Objective:
-- Monitor revenue growth progression within each year.
-- ---------------------------------------------------------

WITH monthly_sales AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS order_year,
        MONTH(o.order_purchase_timestamp) AS order_month,
        SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY order_year, order_month
)

SELECT 
    order_year,
    order_month,
    monthly_revenue,
    SUM(monthly_revenue) 
        OVER (PARTITION BY order_year 
              ORDER BY order_month) AS cumulative_revenue
FROM monthly_sales
ORDER BY order_year, order_month;




-- ---------------------------------------------------------
-- ADVANCED PROBLEM 3:
-- Calculate Year-over-Year growth rate of total sales.
-- Objective:
-- Evaluate annual business growth performance.
-- ---------------------------------------------------------

WITH yearly_sales AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS order_year,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY order_year
)

SELECT 
    order_year,
    total_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) 
         OVER (ORDER BY order_year))
        /
        LAG(total_revenue) 
         OVER (ORDER BY order_year) * 100,
    2) AS yoy_growth_percentage
FROM yearly_sales;


-- ---------------------------------------------------------
-- ADVANCED PROBLEM 4:
-- Calculate customer retention rate.
-- Retention Definition:
-- Customer makes another purchase within 6 months of first purchase.
-- Objective:
-- Measure customer loyalty.
-- ---------------------------------------------------------

WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(order_purchase_timestamp) AS first_order_date
    FROM orders
    GROUP BY customer_id
),

repeat_purchase AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    JOIN first_purchase f
        ON o.customer_id = f.customer_id
    WHERE o.order_purchase_timestamp > f.first_order_date
      AND o.order_purchase_timestamp <= 
          DATE_ADD(f.first_order_date, INTERVAL 6 MONTH)
)

SELECT 
    ROUND(
        (COUNT(DISTINCT r.customer_id) /
         (SELECT COUNT(DISTINCT customer_id) FROM orders)
        ) * 100,
    2) AS retention_rate_percentage
FROM repeat_purchase r;


-- ---------------------------------------------------------
-- ADVANCED PROBLEM 5:
-- Identify top 3 customers by spending for each year.
-- Objective:
-- Recognize high-value customers annually.
-- ---------------------------------------------------------

WITH customer_yearly_spending AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS order_year,
        o.customer_id,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY order_year, o.customer_id
)

SELECT *
FROM (
    SELECT 
        order_year,
        customer_id,
        total_spent,
        RANK() OVER (
            PARTITION BY order_year
            ORDER BY total_spent DESC
        ) AS rank_position
    FROM customer_yearly_spending
) ranked_customers
WHERE rank_position <= 3
ORDER BY order_year, rank_position;

