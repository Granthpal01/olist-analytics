-- Q5: Delivery Performance Analysis
-- Measures actual vs estimated delivery across all delivered orders
-- Decomposes fulfillment timeline into 4 stages
-- Links late delivery to review scores

WITH delivery_metrics AS (
    SELECT
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        -- Stage 1: Payment approval lag (hours)
        ROUND(
            (JULIANDAY(o.order_approved_at) -
             JULIANDAY(o.order_purchase_timestamp)) * 24
        , 1) AS payment_lag_hrs,

        -- Stage 2: Seller processing time (hours)
        ROUND(
            (JULIANDAY(o.order_delivered_carrier_date) -
             JULIANDAY(o.order_approved_at)) * 24
        , 1) AS seller_processing_hrs,

        -- Stage 3: Carrier shipping time (hours)
        ROUND(
            (JULIANDAY(o.order_delivered_customer_date) -
             JULIANDAY(o.order_delivered_carrier_date)) * 24
        , 1) AS carrier_shipping_hrs,

        -- Stage 4: Total fulfillment time (days)
        ROUND(
            JULIANDAY(o.order_delivered_customer_date) -
            JULIANDAY(o.order_purchase_timestamp)
        , 1) AS total_fulfillment_days,

        -- Delivery delta: negative = early, positive = late (days)
        ROUND(
            JULIANDAY(o.order_delivered_customer_date) -
            JULIANDAY(o.order_estimated_delivery_date)
        , 1) AS delivery_delta_days,

        -- Late flag
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END AS is_late,

        -- Review score (NULL if no review)
        r.review_score

    FROM orders o
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    -- Volume
    COUNT(*)                                         AS total_delivered_orders,
    SUM(is_late)                                     AS late_orders,
    ROUND(100.0 * SUM(is_late) / COUNT(*), 2)        AS late_pct,

    -- Fulfillment time breakdown (averages)
    ROUND(AVG(payment_lag_hrs), 1)                   AS avg_payment_lag_hrs,
    ROUND(AVG(seller_processing_hrs), 1)             AS avg_seller_processing_hrs,
    ROUND(AVG(carrier_shipping_hrs), 1)              AS avg_carrier_shipping_hrs,
    ROUND(AVG(total_fulfillment_days), 1)            AS avg_fulfillment_days,

    -- Delivery accuracy
    ROUND(AVG(delivery_delta_days), 1)               AS avg_delivery_delta_days,
    ROUND(AVG(CASE WHEN is_late = 1
              THEN delivery_delta_days END), 1)       AS avg_days_late_when_late,

    -- Review scores split by late vs on-time
    ROUND(AVG(CASE WHEN is_late = 0
              THEN review_score END), 2)              AS avg_review_ontime,
    ROUND(AVG(CASE WHEN is_late = 1
              THEN review_score END), 2)              AS avg_review_late

FROM delivery_metrics;