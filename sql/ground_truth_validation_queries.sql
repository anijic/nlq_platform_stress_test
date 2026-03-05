-- ============================================================
-- NL2SQL Ground-Truth Validation Queries
-- Project: Enterprise NLQ Semantic Layer Stress-Test & QA
-- Client: Jedify (Feb 2026)
-- Author: Charles Aniji — github.com/anijic
--
-- Purpose: These 30 BigQuery queries served as the native SQL
-- ground truth against which all NLQ platform outputs were
-- validated. Each query maps to a corresponding row in the
-- 30-Query Friction Log in the README.
--
-- Schema: enterprise_ecommerce_sandbox (Star Schema)
--   Fact tables  : order_items, orders
--   Dim tables   : users, products
-- ============================================================


-- ── TIER 1: BASIC AGGREGATIONS ──────────────────────────────

-- Query 1 | PASS
-- What is our total all-time revenue from completed orders?
SELECT SUM(oi.sale_price) AS total_revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o ON oi.order_id = o.order_id
WHERE o.status = 'Complete';

-- Query 2 | PASS
-- How many total users do we have in our database?
SELECT COUNT(id) AS total_users
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.users`;

-- Query 3 | PASS
-- How many unique products are currently in our catalog?
SELECT COUNT(id) AS total_products
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.products`;

-- Query 4 | PASS
-- How many total orders have been placed across all time?
SELECT COUNT(order_id) AS total_orders
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.orders`;

-- Query 5 | FAIL — Entity-Locking / Date Mismatch
-- What was our total revenue for the year 2023?
-- NLQ Bug: AI filtered on user signup year instead of order creation year.
-- BQ Truth: $361K (orders placed in 2023) vs NLQ Output: $385K (users signed up in 2023)
SELECT SUM(oi.sale_price) AS total_revenue_2023
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o ON oi.order_id = o.order_id
WHERE o.status = 'Complete'
  AND EXTRACT(YEAR FROM o.created_at) = 2023;

-- Query 6 | PASS
-- Exactly how many order items have been returned across all time?
SELECT COUNT(id) AS total_returned_items
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`
WHERE status = 'Returned';

-- Query 7 | PASS
-- How many users do we have located in the United States?
SELECT COUNT(id) AS us_users
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.users`
WHERE country = 'United States';

-- Query 8 | PASS
-- How many different product categories do we sell?
SELECT COUNT(DISTINCT category) AS category_count
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.products`;

-- Query 9 | FAIL — Arithmetic Myopia
-- What is our Average Order Value (AOV) for completed orders?
-- NLQ Bug: Platform claimed no order value field existed; failed to derive AOV via division.
SELECT SUM(oi.sale_price) / COUNT(DISTINCT o.order_id) AS aov
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o ON oi.order_id = o.order_id
WHERE o.status = 'Complete';

-- Query 10 | PASS
-- How many orders are currently in 'Processing' status?
SELECT COUNT(order_id) AS processing_orders
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.orders`
WHERE status = 'Processing';


-- ── TIER 2: MULTI-DIMENSION & DATE LOGIC ────────────────────

-- Query 11 | FAIL — Temporal Blindness
-- Show me the total revenue by month for the year 2023.
-- NLQ Bug: Platform refused to filter by order date; insisted only user signup date was available.
SELECT EXTRACT(MONTH FROM o.created_at) AS month, SUM(oi.sale_price) AS monthly_revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o ON oi.order_id = o.order_id
WHERE o.status = 'Complete'
  AND EXTRACT(YEAR FROM o.created_at) = 2023
GROUP BY 1
ORDER BY 1;

-- Query 12 | FAIL — Aggregation Error
-- List the top 5 users by their total spend (CLTV).
-- NLQ Bug: Output mismatched BQ ground truth; likely dropped status filters.
SELECT user_id, SUM(sale_price) AS total_spend
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Query 13 | PASS
-- Which 3 product categories had the most items sold in 2023?
SELECT p.category, COUNT(oi.id) AS items_sold
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.products` p ON oi.product_id = p.id
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o ON oi.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.created_at) = 2023
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- Query 14 | PASS
-- How many new users signed up each quarter in 2023?
SELECT EXTRACT(QUARTER FROM created_at) AS quarter, COUNT(id) AS new_users
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.users`
WHERE EXTRACT(YEAR FROM created_at) = 2023
GROUP BY 1
ORDER BY 1;

-- Query 15 | FAIL — Join Gap
-- Show me the total revenue for users in 'United Kingdom' vs 'France'.
-- NLQ Bug: Generated revenue values mismatched native SQL join output.
SELECT u.country, SUM(oi.sale_price) AS revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.users` u ON oi.user_id = u.id
WHERE u.country IN ('United Kingdom', 'France')
GROUP BY 1;

-- Query 16 | PASS
-- What percentage of our total orders are currently in 'Returned' status?
SELECT (COUNTIF(status = 'Returned') / COUNT(*)) * 100 AS return_percentage
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.orders`;

-- Query 17 | PASS
-- What is the average retail price of products in each category?
SELECT category, AVG(retail_price) AS avg_price
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.products`
GROUP BY 1;

-- Query 18 | FAIL — Join Failure
-- Is our revenue higher from Male or Female users?
-- NLQ Bug: Could not cleanly map demographic dimension to revenue measure.
SELECT u.gender, SUM(oi.sale_price) AS revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.users` u ON oi.user_id = u.id
GROUP BY 1;

-- Query 19 | FAIL — Pruned Entity Interference
-- Which traffic source brought in the most revenue?
-- NLQ Bug: traffic_source was previously hallucinated as a standalone table; residual
-- entity confusion caused failure on this query.
SELECT u.traffic_source, SUM(oi.sale_price) AS revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.users` u ON oi.user_id = u.id
GROUP BY 1
ORDER BY 2 DESC;

-- Query 20 | PASS
-- At what hour of the day do most orders get placed?
SELECT EXTRACT(HOUR FROM created_at) AS hour_of_day, COUNT(order_id) AS order_count
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.orders`
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


-- ── TIER 3: COMPLEX JOINS, RATIO MATH, NULL HANDLING ────────

-- Query 21 | FAIL — Logical Void
-- Which products in our catalog have never been ordered?
-- NLQ Bug: Failed to execute LEFT JOIN / IS NULL anti-join pattern.
SELECT p.name, p.id
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.products` p
LEFT JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi ON p.id = oi.product_id
WHERE oi.product_id IS NULL;

-- Query 22 | FAIL — Aggregation Limit
-- Who are the top 3 users that have returned more than 2 items?
-- NLQ Bug: Failed to apply HAVING COUNT > 2 post-aggregation filter correctly.
SELECT user_id, COUNT(id) AS return_count
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`
WHERE status = 'Returned'
GROUP BY 1
HAVING COUNT(id) > 2
ORDER BY 2 DESC
LIMIT 3;

-- Query 23 | FAIL — Complex Value Mismatch
-- Compare the total revenue from 'Search' traffic in Q1 2023 vs Q4 2023.
-- NLQ Bug: Compounded entity/date locking produced wildly inaccurate sums.
SELECT
  EXTRACT(QUARTER FROM o.created_at) AS quarter,
  SUM(oi.sale_price) AS revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.users` u ON oi.user_id = u.id
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o ON oi.order_id = o.order_id
WHERE u.traffic_source = 'Search'
  AND EXTRACT(YEAR FROM o.created_at) = 2023
  AND EXTRACT(QUARTER FROM o.created_at) IN (1, 4)
GROUP BY 1;

-- Query 24 | FAIL — Ratio Math Failure
-- What is the average lifetime revenue per user for our entire customer base?
-- NLQ Bug: Output $98.05 vs BQ Truth $108.16. Cannot reliably execute subquery-denominator math.
SELECT
  SUM(sale_price) / (
    SELECT COUNT(id)
    FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.users`
  ) AS arpu
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`;

-- Query 25 | FAIL — Relationship Amnesia
-- Show me the names of users who bought 'Accessories' in the 'UK' last year.
-- NLQ Bug: Platform claimed it could not connect product data to user data
-- despite existing foreign keys in the schema.
SELECT DISTINCT u.first_name, u.last_name
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.users` u
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi ON u.id = oi.user_id
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.products` p ON oi.product_id = p.id
WHERE p.category = 'Accessories'
  AND u.country = 'United Kingdom'
  AND EXTRACT(YEAR FROM oi.created_at) = 2025;

-- Query 26 | FAIL — Logical Void
-- Are there any orders that were created but have no items attached?
-- NLQ Bug: Failed to recognize NULL states or missing foreign key attachments.
SELECT o.order_id
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.orders` o
LEFT JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- Query 27 | FAIL — Record Mismatch
-- Which user has the most orders, and what is their total spend?
-- NLQ Bug: Identified the wrong top user compared to native SQL result.
SELECT user_id, COUNT(DISTINCT order_id) AS order_count, SUM(sale_price) AS total_spend
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Query 28 | FAIL — Multi-Filter Collapse
-- What is the total dollar value lost to 'Returned' items in the 'Jeans' category?
-- NLQ Bug: Failed to apply status filter, category filter, and SUM simultaneously.
SELECT SUM(oi.sale_price) AS lost_revenue
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.products` p ON oi.product_id = p.id
WHERE oi.status = 'Returned'
  AND p.category = 'Jeans';

-- Query 29 | FAIL — Relationship Amnesia
-- What is the most popular product category for users aged 18 to 25?
-- NLQ Bug: Failed complex demographic-to-product join traversal.
SELECT p.category, COUNT(oi.id) AS purchase_count
FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items` oi
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.users` u ON oi.user_id = u.id
JOIN `your-gcp-project-id.enterprise_ecommerce_sandbox.products` p ON oi.product_id = p.id
WHERE u.age BETWEEN 18 AND 25
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Query 30 | PASS
-- Summarize our 2023 performance: Total Revenue, Total Users, Total Returns.
SELECT
  (SELECT SUM(sale_price)
   FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`
   WHERE EXTRACT(YEAR FROM created_at) = 2023) AS total_revenue,
  (SELECT COUNT(id)
   FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.users`
   WHERE EXTRACT(YEAR FROM created_at) = 2023) AS total_users,
  (SELECT COUNT(id)
   FROM `your-gcp-project-id.enterprise_ecommerce_sandbox.order_items`
   WHERE status = 'Returned'
     AND EXTRACT(YEAR FROM created_at) = 2023) AS total_returns;
