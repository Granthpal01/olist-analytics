-- Q6: Review score distribution and key drivers
-- Connects review scores to delivery performance and order value
-- Identifies what separates 1-star from 5-star experiences

WITH order_metrics AS (
    SELECT
        o.order_id,
        r.review_score,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END                                                     AS is_late,
        ROUND(
            JULIANDAY(o.order_delivered_customer_date) -
            JULIANDAY(o.order_estimated_delivery_date)
        , 1)                                                    AS delivery_delta_days,
        ROUND(
            JULIANDAY(o.order_delivered_customer_date) -
            JULIANDAY(o.order_purchase_timestamp)
        , 1)                                                    AS total_fulfillment_days,
        ROUND(SUM(oi.price + oi.freight_value), 2)             AS order_value
    FROM orders o
    JOIN order_items oi    ON o.order_id = oi.order_id
    JOIN order_reviews r   ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND r.review_score IS NOT NULL
    GROUP BY o.order_id, r.review_score,
             o.order_delivered_customer_date,
             o.order_estimated_delivery_date,
             o.order_purchase_timestamp
)
SELECT
    review_score,
    COUNT(*)                                    AS total_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_reviews,
    ROUND(AVG(is_late), 4) * 100                AS late_pct,
    ROUND(AVG(delivery_delta_days), 1)          AS avg_delivery_delta_days,
    ROUND(AVG(total_fulfillment_days), 1)       AS avg_fulfillment_days,
    ROUND(AVG(order_value), 2)                  AS avg_order_value_brl
FROM order_metrics
GROUP BY review_score
ORDER BY review_score DESC;