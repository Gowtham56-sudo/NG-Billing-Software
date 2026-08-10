import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../../../models/product.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartState {
  final List<CartItem> items;
  final String? customerName;
  final String? customerMobile;
  final String? customerId;
  final double globalDiscount;
  final String paymentMethod;
  final String saleType;

  CartState({
    this.items = const [],
    this.customerName,
    this.customerMobile,
    this.customerId,
    this.globalDiscount = 0.0,
    this.paymentMethod = 'Cash',
    this.saleType = 'Retail',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.getGrossAmount(saleType));
  double get totalItemDiscount => items.fold(0.0, (sum, item) => sum + item.discount);
  double get totalGst => items.fold(0.0, (sum, item) => sum + item.getGstAmount(saleType));
  double get grandTotal => items.fold(0.0, (sum, item) => sum + item.getNetAmount(saleType)) - globalDiscount;

  CartState copyWith({
    List<CartItem>? items,
    String? customerName,
    String? customerMobile,
    String? customerId,
    double? globalDiscount,
    String? paymentMethod,
    String? saleType,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerId: customerId ?? this.customerId,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleType: saleType ?? this.saleType,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState();

  void addProduct(Product product, [double quantity = 1.0]) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = newItems[existingIndex].copyWith(
        quantity: newItems[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity)]);
    }
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(int productId, double quantity) {
    final newItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void updateDiscount(int productId, double discount) {
    final newItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(discount: discount);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void updatePrice(int productId, double price) {
    final newItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(customPrice: price);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void setGlobalDiscount(double discount) {
    state = state.copyWith(globalDiscount: discount);
  }

  void setCustomer(String id, String name, [String? mobile]) {
    state = state.copyWith(customerId: id, customerName: name, customerMobile: mobile);
  }

  void updateCustomerDetails({String? name, String? mobile}) {
    state = state.copyWith(customerName: name, customerMobile: mobile);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setSaleType(String type) {
    state = state.copyWith(saleType: type);
  }

  void clearCart() {
    state = CartState();
  }
}
