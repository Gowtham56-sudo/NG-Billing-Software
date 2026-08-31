import sqlite3

def seed():
    conn = sqlite3.connect(r'e:\NG-Billing Software\.dart_tool\sqflite_common_ffi\databases\nextgen_billing.db')
    c = conn.cursor()

    categories = [
        (1, 'Dairy & Beverages'),
        (2, 'Oils & Ghee'),
        (3, 'Snacks & Bakery'),
        (4, 'Personal Care & Hygiene'),
        (5, 'Grains, Flours & Dals'),
        (6, 'Spices & Masalas')
    ]

    for cat_id, name in categories:
        c.execute('INSERT OR IGNORE INTO categories (id, name) VALUES (?, ?)', (cat_id, name))

    c.execute("UPDATE products SET category_id = 1 WHERE name LIKE '%milk%' OR name LIKE '%aavin%' OR name LIKE '%tea%' OR name LIKE '%coffee%'")
    c.execute("UPDATE products SET category_id = 2 WHERE name LIKE '%oil%' OR name LIKE '%ghee%'")
    c.execute("UPDATE products SET category_id = 3 WHERE name LIKE '%biscuit%' OR name LIKE '%cake%' OR name LIKE '%cookie%'")
    c.execute("UPDATE products SET category_id = 4 WHERE name LIKE '%shampoo%' OR name LIKE '%soap%' OR name LIKE '%blade%' OR name LIKE '%paste%'")
    c.execute("UPDATE products SET category_id = 5 WHERE name LIKE '%rice%' OR name LIKE '%atta%' OR name LIKE '%dal%' OR name LIKE '%flour%'")
    c.execute("UPDATE products SET category_id = 6 WHERE name LIKE '%masala%' OR name LIKE '%chilli%' OR name LIKE '%salt%' OR name LIKE '%turmeric%'")

    conn.commit()

    c.execute('SELECT p.id, p.name, c.name FROM products p LEFT JOIN categories c ON p.category_id = c.id')
    for r in c.fetchall():
        print(f"  [{r[0]}] {r[1]} -> Category: {r[2]}")
    conn.close()

if __name__ == '__main__':
    seed()
