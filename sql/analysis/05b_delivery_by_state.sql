-- Q5b: Delivery performance by customer state
-- Identifies which regions have worst late rates and lowest review scores
-- Useful for geographic targeting of logistics improvements

WITH delivery_metrics AS (
    SELECT
        c.customer_state,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END                                                      AS is_late,
        ROUND(
            JULIANDAY(o.order_delivered_customer_date) -
            JULIANDAY(o.order_purchase_timestamp)
        , 1)                                                     AS total_fulfillment_days,
        r.review_score
    FROM orders o
    JOIN customers c       ON o.customer_id  = c.customer_id
    LEFT JOIN order_reviews r ON o.order_id  = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    customer_state,
    COUNT(*)                                          AS total_orders,
    SUM(is_late)                                      AS late_orders,
    ROUND(100.0 * SUM(is_late) / COUNT(*), 2)         AS late_pct,
    ROUND(AVG(total_fulfillment_days), 1)             AS avg_fulfillment_days,
    ROUND(AVG(review_score), 2)                       AS avg_review_score
FROM delivery_metrics
GROUP BY customer_state
HAVING COUNT(*) > 100
ORDER BY late_pct DESC
LIMIT 15;