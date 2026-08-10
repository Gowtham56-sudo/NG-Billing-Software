class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String? sku;
  final double purchasePrice;
  final double sellingPrice;
  final double wholesalePrice;
  final double hotelPrice;
  final double gstPercentage;
  final double currentStock;
  final double minStock;
  final String? imagePath;
  final String? description;
  final int? categoryId;
  final String unit;
  final double unitValue;

  Product({
    this.id,
    required this.name,
    this.barcode,
    this.sku,
    this.purchasePrice = 0.0,
    required this.sellingPrice,
    this.wholesalePrice = 0.0,
    this.hotelPrice = 0.0,
    this.gstPercentage = 18.0,
    this.currentStock = 0.0,
    this.minStock = 0.0,
    this.imagePath,
    this.description,
    this.categoryId,
    this.unit = 'Piece',
    this.unitValue = 1.0,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      sku: map['sku'],
      purchasePrice: map['purchase_price']?.toDouble() ?? 0.0,
      sellingPrice: map['selling_price']?.toDouble() ?? 0.0,
      wholesalePrice: map['wholesale_price']?.toDouble() ?? 0.0,
      hotelPrice: map['hotel_price']?.toDouble() ?? 0.0,
      gstPercentage: map['gst_percentage']?.toDouble() ?? 0.0,
      currentStock: map['current_stock']?.toDouble() ?? 0.0,
      minStock: map['min_stock']?.toDouble() ?? 0.0,
      imagePath: map['image_path'],
      description: map['description'],
      categoryId: map['category_id'],
      unit: map['unit'] ?? 'Piece',
      unitValue: map['unit_value']?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'sku': sku,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'wholesale_price': wholesalePrice,
      'hotel_price': hotelPrice,
      'gst_percentage': gstPercentage,
      'current_stock': currentStock,
      'min_stock': minStock,
      'image_path': imagePath,
      'description': description,
      'category_id': categoryId,
      'unit': unit,
      'unit_value': unitValue,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? sku,
    double? purchasePrice,
    double? sellingPrice,
    double? wholesalePrice,
    double? hotelPrice,
    double? gstPercentage,
    double? currentStock,
    double? minStock,
    String? imagePath,
    String? description,
    int? categoryId,
    String? unit,
    double? unitValue,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      hotelPrice: hotelPrice ?? this.hotelPrice,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      unitValue: unitValue ?? this.unitValue,
    );
  }
}
