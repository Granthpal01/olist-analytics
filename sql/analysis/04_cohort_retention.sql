-- Q4: Monthly cohort retention
-- Uses customer_unique_id (actual person, not per-order ID)
-- Cohort = month of customer's FIRST delivered order
-- month_index = (year * 12 + month) as a single integer — avoids SQLite cast issues

WITH first_orders AS (
    SELECT
        c.customer_unique_id,
        MIN(strftime('%Y-%m', o.order_purchase_timestamp))          AS cohort_month,
        MIN(
            CAST(strftime('%Y', o.order_purchase_timestamp) AS INTEGER) * 12 +
            CAST(strftime('%m', o.order_purchase_timestamp) AS INTEGER)
        )                                                            AS cohort_index
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        CAST(strftime('%Y', o.order_purchase_timestamp) AS INTEGER) * 12 +
        CAST(strftime('%m', o.order_purchase_timestamp) AS INTEGER) AS order_index
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_data AS (
    SELECT
        f.cohort_month,
        f.cohort_index,
        co.customer_unique_id,
        co.order_index - f.cohort_index                             AS months_since_first
    FROM first_orders f
    JOIN customer_orders co ON f.customer_unique_id = co.customer_unique_id
)
SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN months_since_first = 0 THEN customer_unique_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN customer_unique_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN months_since_first = 2 THEN customer_unique_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN months_since_first = 3 THEN customer_unique_id END) AS month_3,
    ROUND(
        100.0 *
        COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN customer_unique_id END) /
        NULLIF(COUNT(DISTINCT CASE WHEN months_since_first = 0 THEN customer_unique_id END), 0),
    2)                                                               AS m1_retention_pct
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;