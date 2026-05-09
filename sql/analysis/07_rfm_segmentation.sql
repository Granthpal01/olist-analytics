-- Q7: RFM Customer Segmentation
-- Recency: days since last order (as of dataset end date: 2018-09-03)
-- Frequency: total number of orders placed
-- Monetary: total spend (price + freight)
-- Scores: 1-4 scale (4 = best) using NTILE window function
-- Segments: derived from score combinations

WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)                          AS frequency,
        ROUND(SUM(oi.price + oi.freight_value), 2)          AS monetary,
        MAX(o.order_purchase_timestamp)                     AS last_order_date,
        ROUND(
            JULIANDAY('2018-09-03') -
            JULIANDAY(MAX(o.order_purchase_timestamp))
        , 0)                                                AS recency_days
    FROM orders o
    JOIN customers c    ON o.customer_id  = c.customer_id
    JOIN order_items oi ON o.order_id     = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        -- Recency: LOWER days = better = higher score
        NTILE(4) OVER (ORDER BY recency_days DESC)  AS r_score,
        -- Frequency: HIGHER frequency = better = higher score
        NTILE(4) OVER (ORDER BY frequency ASC)      AS f_score,
        -- Monetary: HIGHER spend = better = higher score
        NTILE(4) OVER (ORDER BY monetary ASC)       AS m_score
    FROM customer_metrics
),
rfm_segments AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score)               AS rfm_total,
        CASE
            WHEN r_score = 4 AND f_score = 4        THEN 'Champions'
            WHEN r_score = 4 AND f_score >= 3       THEN 'Loyal Customers'
            WHEN r_score = 4 AND f_score < 3        THEN 'Recent Customers'
            WHEN r_score = 3 AND f_score >= 3       THEN 'Potential Loyalists'
            WHEN r_score >= 3 AND f_score <= 2      THEN 'Promising'
            WHEN r_score = 2 AND f_score >= 3       THEN 'At Risk'
            WHEN r_score = 2 AND f_score <= 2       THEN 'Needs Attention'
            WHEN r_score = 1 AND f_score >= 3       THEN 'Cant Lose Them'
            WHEN r_score = 1 AND f_score <= 2       THEN 'Lost'
            ELSE 'Other'
        END                                         AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(*)                                        AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
    ROUND(AVG(recency_days), 0)                     AS avg_recency_days,
    ROUND(AVG(frequency), 2)                        AS avg_frequency,
    ROUND(AVG(monetary), 2)                         AS avg_monetary_brl,
    ROUND(SUM(monetary), 2)                         AS total_revenue_brl
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue_brl DESC;