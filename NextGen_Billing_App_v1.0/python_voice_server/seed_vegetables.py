import sqlite3
import os

db_paths = [
    r"e:\NG-Billing Software\.dart_tool\sqflite_common_ffi\databases\nextgen_billing.db",
    r"e:\NG-Billing Software\NextGen_Billing_App_v1.0\nextgen_billing.db"
]

vegetables_category_id = 7

vegetable_items = [
    ("Tomato (Thakkali)", "kg", 1.0, 25.0, 35.0, 30.0, 50.0),
    ("Onion (Vengayam)", "kg", 1.0, 35.0, 45.0, 40.0, 60.0),
    ("Small Onion (Chinna Vengayam)", "kg", 1.0, 65.0, 80.0, 75.0, 30.0),
    ("Potato (Urulaikizhangu)", "kg", 1.0, 22.0, 30.0, 26.0, 50.0),
    ("Carrot", "kg", 1.0, 45.0, 60.0, 55.0, 25.0),
    ("Beans", "kg", 1.0, 55.0, 70.0, 65.0, 20.0),
    ("Brinjal (Kathirikai)", "kg", 1.0, 30.0, 40.0, 35.0, 30.0),
    ("Ladies Finger (Vendaikai)", "kg", 1.0, 32.0, 45.0, 40.0, 25.0),
    ("Cabbage (Muttaikose)", "kg", 1.0, 20.0, 30.0, 25.0, 30.0),
    ("Cauliflower", "piece", 1.0, 25.0, 35.0, 30.0, 20.0),
    ("Beetroot", "kg", 1.0, 30.0, 40.0, 35.0, 25.0),
    ("Green Chilli (Pachai Milagai)", "kg", 1.0, 45.0, 60.0, 55.0, 15.0),
    ("Ginger (Inji)", "kg", 1.0, 90.0, 120.0, 110.0, 15.0),
    ("Garlic (Poondu)", "kg", 1.0, 140.0, 180.0, 160.0, 20.0),
    ("Lemon (Elumichai)", "piece", 1.0, 3.0, 5.0, 4.0, 100.0),
    ("Coriander Leaves (Kothamalli)", "bunch", 1.0, 8.0, 15.0, 12.0, 40.0),
    ("Curry Leaves (Karuveppilai)", "bunch", 1.0, 5.0, 10.0, 8.0, 30.0),
    ("Mint Leaves (Pudina)", "bunch", 1.0, 8.0, 15.0, 12.0, 30.0),
    ("Spinach / Greens (Keerai)", "bunch", 1.0, 12.0, 20.0, 16.0, 35.0),
    ("Bitter Gourd (Pavakkai)", "kg", 1.0, 38.0, 50.0, 45.0, 20.0),
    ("Bottle Gourd (Suraikai)", "kg", 1.0, 20.0, 30.0, 25.0, 20.0),
    ("Capsicum (Kuda Milagai)", "kg", 1.0, 48.0, 65.0, 58.0, 15.0),
    ("Mushroom (Kaalan)", "packet", 1.0, 32.0, 45.0, 40.0, 25.0),
    ("Radish (Mullangi)", "kg", 1.0, 25.0, 35.0, 30.0, 20.0),
    ("Pumpkin (Poosanikai)", "kg", 1.0, 18.0, 28.0, 24.0, 25.0),
    ("Ridge Gourd (Peerkangai)", "kg", 1.0, 32.0, 45.0, 40.0, 20.0),
    ("Snake Gourd (Pudalangai)", "kg", 1.0, 25.0, 35.0, 30.0, 20.0),
]

for p in db_paths:
    if os.path.exists(p):
        conn = sqlite3.connect(p)
        cur = conn.cursor()
        
        # 1. Insert Category
        cur.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (?, ?)", (vegetables_category_id, "Fresh Vegetables & Greens"))
        cur.execute("UPDATE categories SET name = 'Fresh Vegetables & Greens' WHERE id = ?", (vegetables_category_id,))
        
        # 2. Insert Products
        for name, unit, u_val, buy_price, sell_price, whole_price, stock in vegetable_items:
            cur.execute("SELECT id FROM products WHERE name = ?", (name,))
            existing = cur.fetchone()
            if not existing:
                cur.execute("""
                    INSERT INTO products (name, category_id, unit, unit_value, purchase_price, selling_price, wholesale_price, hotel_price, gst_percentage, current_stock, min_stock)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (name, vegetables_category_id, unit, u_val, buy_price, sell_price, whole_price, sell_price, 0.0, stock, 5.0))
            else:
                cur.execute("UPDATE products SET category_id = ? WHERE id = ?", (vegetables_category_id, existing[0]))
                
        conn.commit()
        conn.close()
        print(f"Successfully seeded vegetables into: {p}")
