import '../../../models/product.dart';

class CartItem {
  final Product product;
  final double quantity;
  final double discount; // Discount amount applied per item
  final double? customPrice; // Manually overridden price
  
  CartItem({
    required this.product,
    this.quantity = 1.0,
    this.discount = 0.0,
    this.customPrice,
  });

  double getPrice(String saleType) {
    if (customPrice != null) return customPrice!;
    if (saleType == 'Wholesale' && product.wholesalePrice > 0) {
      return product.wholesalePrice;
    } else if (saleType == 'Hotel' && product.hotelPrice > 0) {
      return product.hotelPrice;
    }
    return product.sellingPrice;
  }
  double getGrossAmount(String saleType) {
    double baseVal = product.unitValue > 0 ? product.unitValue : 1.0;
    return getPrice(saleType) * (quantity / baseVal);
  }
  double getDiscountedAmount(String saleType) => getGrossAmount(saleType) - discount;
  double getGstAmount(String saleType) => getDiscountedAmount(saleType) * (product.gstPercentage / 100);
  double getNetAmount(String saleType) => getDiscountedAmount(saleType) + getGstAmount(saleType);

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? discount,
    double? customPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      customPrice: customPrice ?? this.customPrice,
    );
  }
}
