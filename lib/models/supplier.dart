class Supplier {
  final int? id;
  final String name;
  final String? mobile;
  final String? gstNumber;
  final String? address;
  final double pendingPayments;

  Supplier({
    this.id,
    required this.name,
    this.mobile,
    this.gstNumber,
    this.address,
    this.pendingPayments = 0.0,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      gstNumber: map['gst_number'],
      address: map['address'],
      pendingPayments: map['pending_payments']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'gst_number': gstNumber,
      'address': address,
      'pending_payments': pendingPayments,
    };
  }
}
