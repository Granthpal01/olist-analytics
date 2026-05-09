"""
Export SQL query results to CSV for Tableau dashboard.
Run from project root: python scripts/export_for_tableau.py
"""

import sqlite3
import pandas as pd
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "olist.db"
EXPORT_DIR = PROJECT_ROOT / "data" / "exports"
EXPORT_DIR.mkdir(exist_ok=True)

conn = sqlite3.connect(DB_PATH)

exports = {

    "monthly_revenue": """
        SELECT
            strftime('%Y-%m', o.order_purchase_timestamp) AS year_month,
            COUNT(DISTINCT o.order_id)                    AS orders,
            ROUND(SUM(oi.price + oi.freight_value), 2)    AS revenue_brl
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY year_month
        ORDER BY year_month
    """,

    "delivery_by_state": """
        SELECT
            c.customer_state                                      AS state,
            COUNT(*)                                              AS total_orders,
            SUM(CASE WHEN o.order_delivered_customer_date >
                          o.order_estimated_delivery_date
                THEN 1 ELSE 0 END)                               AS late_orders,
            ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date >
                          o.order_estimated_delivery_date
                THEN 1 ELSE 0 END) / COUNT(*), 2)                AS late_pct,
            ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) -
                      JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_fulfillment_days,
            ROUND(AVG(r.review_score), 2)                        AS avg_review_score
        FROM orders o
        JOIN customers c       ON o.customer_id  = c.customer_id
        LEFT JOIN order_reviews r ON o.order_id  = r.order_id
        WHERE o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
        GROUP BY state
        HAVING COUNT(*) > 50
        ORDER BY late_pct DESC
    """,

    "review_by_score": """
        WITH order_metrics AS (
            SELECT
                r.review_score,
                CASE WHEN o.order_delivered_customer_date >
                          o.order_estimated_delivery_date
                     THEN 1 ELSE 0 END                          AS is_late,
                ROUND(JULIANDAY(o.order_delivered_customer_date) -
                      JULIANDAY(o.order_purchase_timestamp), 1) AS fulfillment_days
            FROM orders o
            JOIN order_reviews r ON o.order_id = r.order_id
            WHERE o.order_status = 'delivered'
              AND o.order_delivered_customer_date IS NOT NULL
              AND r.review_score IS NOT NULL
        )
        SELECT
            review_score,
            COUNT(*)                                             AS total_orders,
            ROUND(AVG(is_late) * 100, 2)                        AS late_pct,
            ROUND(AVG(fulfillment_days), 1)                     AS avg_fulfillment_days
        FROM order_metrics
        GROUP BY review_score
        ORDER BY review_score
    """,

    "rfm_segments": """
        WITH customer_metrics AS (
            SELECT
                c.customer_unique_id,
                COUNT(DISTINCT o.order_id)                      AS frequency,
                ROUND(SUM(oi.price + oi.freight_value), 2)      AS monetary,
                ROUND(JULIANDAY('2018-09-03') -
                      JULIANDAY(MAX(o.order_purchase_timestamp)), 0) AS recency_days
            FROM orders o
            JOIN customers c    ON o.customer_id  = c.customer_id
            JOIN order_items oi ON o.order_id     = oi.order_id
            WHERE o.order_status = 'delivered'
            GROUP BY c.customer_unique_id
        ),
        rfm_scores AS (
            SELECT
                customer_unique_id, recency_days, frequency, monetary,
                NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
                NTILE(4) OVER (ORDER BY frequency ASC)     AS f_score,
                NTILE(4) OVER (ORDER BY monetary ASC)      AS m_score
            FROM customer_metrics
        )
        SELECT
            CASE
                WHEN r_score = 4 AND f_score = 4     THEN 'Champions'
                WHEN r_score = 4 AND f_score >= 3    THEN 'Loyal Customers'
                WHEN r_score = 4 AND f_score < 3     THEN 'Recent Customers'
                WHEN r_score = 3 AND f_score >= 3    THEN 'Potential Loyalists'
                WHEN r_score >= 3 AND f_score <= 2   THEN 'Promising'
                WHEN r_score = 2 AND f_score >= 3    THEN 'At Risk'
                WHEN r_score = 2 AND f_score <= 2    THEN 'Needs Attention'
                WHEN r_score = 1 AND f_score >= 3    THEN 'Cant Lose Them'
                WHEN r_score = 1 AND f_score <= 2    THEN 'Lost'
                ELSE 'Other'
            END                                              AS segment,
            COUNT(*)                                         AS customer_count,
            ROUND(AVG(monetary), 2)                          AS avg_monetary_brl,
            ROUND(AVG(recency_days), 0)                      AS avg_recency_days
        FROM rfm_scores
        GROUP BY segment
        ORDER BY customer_count DESC
    """,

    "category_revenue": """
        SELECT
            COALESCE(ct.product_category_name_english,
                     p.product_category_name, 'unknown')     AS category,
            COUNT(DISTINCT o.order_id)                       AS orders,
            ROUND(SUM(oi.price + oi.freight_value), 2)       AS revenue_brl,
            ROUND(AVG(oi.freight_value /
                  NULLIF(oi.price + oi.freight_value, 0)) * 100, 2) AS freight_pct
        FROM orders o
        JOIN order_items oi         ON o.order_id    = oi.order_id
        JOIN products p             ON oi.product_id = p.product_id
        LEFT JOIN category_translation ct
                                    ON p.product_category_name
                                     = ct.product_category_name
        WHERE o.order_status = 'delivered'
        GROUP BY category
        HAVING orders > 200
        ORDER BY revenue_brl DESC
        LIMIT 20
    """
}

for name, sql in exports.items():
    df = pd.read_sql(sql, conn)
    path = EXPORT_DIR / f"{name}.csv"
    df.to_csv(path, index=False)
    print(f"Exported {name:25s} → {len(df):>4} rows → {path.name}")

conn.close()
print(f"\nAll exports saved to: {EXPORT_DIR}")