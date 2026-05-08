"""
Smoke test: verify olist.db loaded correctly.
Run from project root: python scripts/smoke_test.py
"""

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "olist.db"
conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. List all tables
cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
tables = [r[0] for r in cur.fetchall()]
print("Tables:", tables)

# 2. Total orders
cur.execute("SELECT COUNT(*) FROM orders;")
print("Total orders:", cur.fetchone()[0])

# 3. Orders by status
print("\nOrders by status:")
cur.execute("""
    SELECT order_status, COUNT(*) as cnt
    FROM orders
    GROUP BY order_status
    ORDER BY cnt DESC;
""")
for row in cur.fetchall():
    print(f"  {row[0]:20s} {row[1]:>7,}")

conn.close()