"""
Load Olist CSVs into a single SQLite database.
Run from project root: python scripts/load_to_sqlite.py
"""

import sqlite3
import pandas as pd
from pathlib import Path

# Paths
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DB_PATH = PROJECT_ROOT / "data" / "olist.db"

# CSV file -> table name mapping
TABLES = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.csv": "orders",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_translation",
}


def load_csvs_to_sqlite():
    if DB_PATH.exists():
        DB_PATH.unlink()  # fresh build every run
        print(f"Removed existing DB at {DB_PATH}")

    conn = sqlite3.connect(DB_PATH)

    for csv_file, table_name in TABLES.items():
        csv_path = RAW_DIR / csv_file
        if not csv_path.exists():
            print(f"MISSING: {csv_file}")
            continue

        df = pd.read_csv(csv_path)
        df.to_sql(table_name, conn, if_exists="replace", index=False)
        print(f"Loaded {table_name:25s} | rows: {len(df):>7,} | cols: {len(df.columns)}")

    conn.close()
    print(f"\nDB written to: {DB_PATH}")


if __name__ == "__main__":
    load_csvs_to_sqlite()