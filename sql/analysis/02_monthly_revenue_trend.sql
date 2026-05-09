-- Q2: Monthly revenue and order volume trend
-- Truncate timestamp to month (SQLite uses strftime)
-- Excludes canceled/unavailable orders

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
    COUNT(DISTINCT o.order_id)                    AS orders,
    COUNT(DISTINCT c.customer_unique_id)          AS unique_customers,
    ROUND(SUM(oi.price), 2)                       AS gmv_brl,
    ROUND(SUM(oi.price + oi.freight_value), 2)    AS revenue_brl,
    ROUND(AVG(oi.price + oi.freight_value), 2)    AS avg_order_value_brl
FROM orders o
JOIN order_items oi    ON o.order_id    = oi.order_id
JOIN customers c       ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY year_month
ORDER BY year_month;