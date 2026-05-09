-- Q8: Freight burden by category
-- Identifies categories where freight costs are disproportionate to product value
-- High freight-to-price ratio = customer pays more to ship than product is worth
-- These categories are candidates for logistics optimization or margin review

WITH category_freight AS (
    SELECT
        COALESCE(ct.product_category_name_english,
                 p.product_category_name, 'unknown')     AS category,
        COUNT(DISTINCT o.order_id)                       AS total_orders,
        ROUND(AVG(oi.price), 2)                          AS avg_price_brl,
        ROUND(AVG(oi.freight_value), 2)                  AS avg_freight_brl,
        ROUND(AVG(p.product_weight_g), 0)                AS avg_weight_g,
        ROUND(
            100.0 * AVG(oi.freight_value) /
            NULLIF(AVG(oi.price), 0)
        , 2)                                             AS freight_to_price_pct,
        ROUND(AVG(r.review_score), 2)                    AS avg_review_score
    FROM orders o
    JOIN order_items oi          ON o.order_id    = oi.order_id
    JOIN products p              ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
                                 ON p.product_category_name
                                  = ct.product_category_name
    LEFT JOIN order_reviews r    ON o.order_id    = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY category
    HAVING total_orders > 200
)
SELECT
    category,
    total_orders,
    avg_price_brl,
    avg_freight_brl,
    avg_weight_g,
    freight_to_price_pct,
    avg_review_score
FROM category_freight
ORDER BY freight_to_price_pct DESC
LIMIT 15;