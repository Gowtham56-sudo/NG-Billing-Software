class Sale {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final int? cashierId;
  final String date;
  final double subtotal;
  final double discount;
  final double gstAmount;
  final double grandTotal;
  final String? paymentMethod;
  final String? status;
  final double paidAmount;
  final double balance;

  Sale({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.cashierId,
    required this.date,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.gstAmount = 0.0,
    this.grandTotal = 0.0,
    this.paymentMethod,
    this.status,
    this.paidAmount = 0.0,
    this.balance = 0.0,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerId: map['customer_id'],
      cashierId: map['cashier_id'],
      date: map['date'],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      gstAmount: map['gst_amount']?.toDouble() ?? 0.0,
      grandTotal: map['grand_total']?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'],
      status: map['status'],
      paidAmount: map['paid_amount']?.toDouble() ?? 0.0,
      balance: map['balance']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'cashier_id': cashierId,
      'date': date,
      'subtotal': subtotal,
      'discount': discount,
      'gst_amount': gstAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'status': status,
      'paid_amount': paidAmount,
      'balance': balance,
    };
  }
}
