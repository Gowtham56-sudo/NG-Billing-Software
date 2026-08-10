class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int productId;
  final double qty;
  final double purchasePrice;
  final double gstAmount;
  final String? expiry;
  final String? batch;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.productId,
    this.qty = 1.0,
    this.purchasePrice = 0.0,
    this.gstAmount = 0.0,
    this.expiry,
    this.batch,
  });

  Map<String, dynamic> toMap(int pId) {
    return {
      'purchase_id': pId,
      'product_id': productId,
      'qty': qty,
      'purchase_price': purchasePrice,
      'gst_amount': gstAmount,
      'expiry': expiry,
      'batch': batch,
    };
  }
}

class Purchase {
  final int? id;
  final int supplierId;
  final String invoiceNumber;
  final String date;
  final double totalAmount;
  final double gstAmount;
  final List<PurchaseItem> items;

  Purchase({
    this.id,
    required this.supplierId,
    required this.invoiceNumber,
    required this.date,
    this.totalAmount = 0.0,
    this.gstAmount = 0.0,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'date': date,
      'total_amount': totalAmount,
      'gst_amount': gstAmount,
    };
  }
}
