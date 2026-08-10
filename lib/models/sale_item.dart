class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final double qty;
  final double price;
  final double discount;
  final double gstAmount;
  final double total;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    this.qty = 0.0,
    this.price = 0.0,
    this.discount = 0.0,
    this.gstAmount = 0.0,
    this.total = 0.0,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      qty: map['qty']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      gstAmount: map['gst_amount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'qty': qty,
      'price': price,
      'discount': discount,
      'gst_amount': gstAmount,
      'total': total,
    };
  }
}
