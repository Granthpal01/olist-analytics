-- Q1: Top-line metrics for the marketplace
-- Filtered to delivered orders only (realized revenue)
-- Revenue defined as item price + freight (what the customer paid)

SELECT
    COUNT(DISTINCT o.order_id)              AS total_orders,
    COUNT(DISTINCT c.customer_unique_id)    AS total_unique_customers,
    COUNT(DISTINCT oi.seller_id)            AS total_sellers,
    COUNT(DISTINCT oi.product_id)           AS total_products_sold,
    ROUND(SUM(oi.price), 2)                 AS gross_merchandise_value_brl,
    ROUND(SUM(oi.freight_value), 2)         AS total_freight_brl,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue_brl,
    ROUND(AVG(oi.price), 2)                 AS avg_item_price_brl,
    MIN(o.order_purchase_timestamp)         AS earliest_order,
    MAX(o.order_purchase_timestamp)         AS latest_order
FROM orders o
JOIN order_items oi    ON o.order_id     = oi.order_id
JOIN customers c       ON o.customer_id  = c.customer_id
WHERE o.order_status = 'delivered';