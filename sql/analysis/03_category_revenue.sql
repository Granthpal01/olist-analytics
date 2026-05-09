-- Q3: Top product categories by revenue
-- Joins to category_translation to get English category names (originals are in Portuguese)
-- Returns top 15 with their share of total revenue

WITH category_revenue AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS category,
        COUNT(DISTINCT o.order_id)        AS orders,
        SUM(oi.price + oi.freight_value)  AS revenue_brl,
        SUM(oi.freight_value)             AS freight_brl,
        AVG(oi.price)                     AS avg_item_price_brl
    FROM orders o
    JOIN order_items oi          ON o.order_id    = oi.order_id
    JOIN products p              ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
)
SELECT
    category,
    orders,
    ROUND(revenue_brl, 2)                                   AS revenue_brl,
    ROUND(100.0 * revenue_brl / SUM(revenue_brl) OVER (), 2) AS pct_of_total_revenue,
    ROUND(100.0 * freight_brl / revenue_brl, 2)             AS freight_pct_of_revenue,
    ROUND(avg_item_price_brl, 2)                            AS avg_item_price_brl
FROM category_revenue
ORDER BY revenue_brl DESC
LIMIT 15;