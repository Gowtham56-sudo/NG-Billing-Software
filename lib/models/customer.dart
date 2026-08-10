class Customer {
  final int? id;
  final String name;
  final String? mobile;
  final String? address;
  final String? gstNumber;
  final int rewardPoints;
  final double creditLimit;
  final String? type;
  final double pendingAmount;
  final double paidAmount;

  Customer({
    this.id,
    required this.name,
    this.mobile,
    this.address,
    this.gstNumber,
    this.rewardPoints = 0,
    this.creditLimit = 0.0,
    this.type,
    this.pendingAmount = 0.0,
    this.paidAmount = 0.0,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      address: map['address'],
      gstNumber: map['gst_number'],
      rewardPoints: map['reward_points'] ?? 0,
      creditLimit: map['credit_limit']?.toDouble() ?? 0.0,
      type: map['type'],
      pendingAmount: map['pending_amount']?.toDouble() ?? 0.0,
      paidAmount: map['paid_amount']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'gst_number': gstNumber,
      'reward_points': rewardPoints,
      'credit_limit': creditLimit,
      'type': type,
      'pending_amount': pendingAmount,
      'paid_amount': paidAmount,
    };
  }
}
