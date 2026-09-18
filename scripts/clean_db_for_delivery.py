"""
Strips developer/test transactional data out of a nextgen_billing.db before it
gets bundled for client delivery. Keeps the product catalog, categories,
settings, and user accounts untouched - only wipes rows that only ever make
sense as real store activity (sales, purchases, customers, expenses).

Usage:
    python scripts/clean_db_for_delivery.py path/to/nextgen_billing.db
"""
import sqlite3
import sys

TABLES_TO_CLEAR = [
    "sale_items",
    "sales",
    "purchase_items",
    "purchases",
    "customers",
    "expenses",
]


def clean(db_path: str) -> None:
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    for table in TABLES_TO_CLEAR:
        cur.execute(f"DELETE FROM {table}")
        print(f"Cleared table: {table}")

    # Reset autoincrement counters for the tables we just wiped, so the
    # client's first real invoice starts at a clean sequence instead of
    # continuing from our dev/test invoice numbers.
    placeholders = ",".join("?" for _ in TABLES_TO_CLEAR)
    cur.execute(
        f"DELETE FROM sqlite_sequence WHERE name IN ({placeholders})",
        TABLES_TO_CLEAR,
    )

    conn.commit()

    cur.execute("SELECT COUNT(*) FROM products")
    product_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM users")
    user_count = cur.fetchone()[0]
    print(f"Preserved: {product_count} products, {user_count} user accounts")

    conn.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python scripts/clean_db_for_delivery.py path/to/nextgen_billing.db")
        sys.exit(1)
    clean(sys.argv[1])
    print("Database sanitized for delivery.")
