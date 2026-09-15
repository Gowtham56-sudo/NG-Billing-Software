import sqlite3
import re
import os

db_path = r".dart_tool\sqflite_common_ffi\databases\nextgen_billing.db"
txt_path = "raw_products_list.txt"

if not os.path.exists(db_path):
    print(f"Error: {db_path} not found.")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

with open(txt_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

success_count = 0
error_count = 0

for line in lines:
    line = line.strip()
    if not line:
        continue

    name = line
    price = 0.0
    category_id = 7 # Default to others

    # Regex to extract price if it ends with XXRS or XX RS
    match = re.search(r'([\d.]+)\s*RS', line, re.IGNORECASE)
    if match:
        price = float(match.group(1))

    # Category assignment
    lower = line.lower()
    if any(k in lower for k in ['milk', 'tea', 'coffee', 'curd', 'butter', 'cheese']):
        category_id = 1
    elif any(k in lower for k in ['oil', 'ghee']):
        category_id = 2
    elif any(k in lower for k in ['biscuit', 'cake', 'cookie', 'chocolate', 'snack', 'chips', 'rusk', 'sweet']):
        category_id = 3
    elif any(k in lower for k in ['shampoo', 'soap', 'paste', 'brush', 'powder', 'cream', 'liquid', 'perfume', 'wash']):
        category_id = 4
    elif any(k in lower for k in ['rice', 'atta', 'maida', 'dal', 'parupu', 'gothumai', 'flour', 'kurunai', 'ulundhu']):
        category_id = 5
    elif any(k in lower for k in ['masala', 'thool', 'spice', 'pepper', 'salt', 'sugar', 'podi']):
        category_id = 6

    try:
        cursor.execute('''
            INSERT INTO products (
                name, selling_price, category_id, current_stock, unit, unit_value, gst_percentage, purchase_price, wholesale_price, hotel_price, min_stock, barcode, sku
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (name, price, category_id, 100.0, 'Piece', 1.0, 18.0, 0.0, 0.0, 0.0, 0.0, '', ''))
        success_count += 1
    except sqlite3.Error as e:
        error_count += 1
        print(f"Failed to insert {name}: {e}")

conn.commit()
conn.close()

print(f"Import complete! Successfully inserted: {success_count}, Errors: {error_count}")
