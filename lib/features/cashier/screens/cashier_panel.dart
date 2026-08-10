import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../models/product.dart';
import '../../products/providers/products_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../../models/customer.dart';
import '../../../database/sqlite_service.dart';
import '../providers/voice_billing_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../../core/utils/print_helper.dart';

class CashierPanel extends ConsumerStatefulWidget {
  const CashierPanel({super.key});

  @override
  ConsumerState<CashierPanel> createState() => _CashierPanelState();
}

class _CashierPanelState extends ConsumerState<CashierPanel> {
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerMobileController =
      TextEditingController();
  final TextEditingController _amountTenderedController =
      TextEditingController();
  final FocusNode _customerMobileFocusNode = FocusNode();
  final FocusNode _customerNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    _searchFocusNode.dispose();
    _productSearchController.dispose();
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _amountTenderedController.dispose();
    _customerMobileFocusNode.dispose();
    _customerNameFocusNode.dispose();
    super.dispose();
  }

  void _handleBarcodeSubmit(String barcode) {
    if (barcode.isEmpty) return;

    final productsState = ref.read(productsProvider);
    final products = productsState.value ?? [];

    try {
      final product = products.firstWhere((p) => p.barcode == barcode);
      ref.read(cartProvider.notifier).addProduct(product);
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product not found: $barcode')));
      _barcodeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _barcodeController.text.length,
      );
      _barcodeFocusNode.requestFocus();
    }
  }

  Future<void> _processBill(bool print) async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    try {
      final db = await SqliteService.database;
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      int? customerId;
      bool isNewCustomer = false;
      if (_customerMobileController.text.isNotEmpty ||
          _customerNameController.text.isNotEmpty) {
        final customersState = ref.read(customersProvider);
        if (customersState.hasValue &&
            _customerMobileController.text.isNotEmpty) {
          final c = customersState.value!
              .where((c) => c.mobile == _customerMobileController.text)
              .firstOrNull;
          customerId = c?.id;
        }
        if (customerId == null) {
          isNewCustomer = true;
        }
      }

      List<String> alerts = [];

      await db.transaction((txn) async {
        if (isNewCustomer &&
            (_customerNameController.text.isNotEmpty ||
                _customerMobileController.text.isNotEmpty)) {
          customerId = await txn.insert('customers', {
            'name': _customerNameController.text.isEmpty
                ? 'Unknown'
                : _customerNameController.text,
            'mobile': _customerMobileController.text.isEmpty
                ? null
                : _customerMobileController.text,
            'reward_points': 0,
            'credit_limit': 0.0,
            'pending_amount': 0.0,
          });
        }

        double paidAmount = 0.0;
        if (cartState.paymentMethod == 'Cash') {
          paidAmount =
              double.tryParse(_amountTenderedController.text) ??
              cartState.grandTotal;
        } else if (cartState.paymentMethod == 'UPI') {
          paidAmount = cartState.grandTotal;
        } else if (cartState.paymentMethod == 'Credit') {
          paidAmount = 0.0; // Credit means not paid yet
        }

        final saleId = await txn.insert('sales', {
          'invoice_number': invoiceNumber,
          'customer_id': customerId,
          'cashier_id': 2, // Default cashier ID for now
          'date': DateTime.now().toIso8601String(),
          'subtotal': cartState.subtotal,
          'discount': cartState.totalItemDiscount + cartState.globalDiscount,
          'gst_amount': cartState.totalGst,
          'grand_total': cartState.grandTotal,
          'payment_method': cartState.paymentMethod,
          'status': cartState.paymentMethod == 'Credit'
              ? 'Pending'
              : 'Completed',
          'paid_amount': paidAmount,
        });

        // Update customer's pending amount if credit sale
        if (customerId != null && cartState.paymentMethod == 'Credit') {
          final pendingToAdd = cartState.grandTotal - paidAmount;
          await txn.rawUpdate(
            'UPDATE customers SET pending_amount = pending_amount + ? WHERE id = ?',
            [pendingToAdd, customerId],
          );
        }

        for (final item in cartState.items) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': item.product.id,
            'qty': item.quantity,
            'price': item.getPrice(cartState.saleType),
            'discount': item.discount,
            'gst_amount': item.getGstAmount(cartState.saleType),
            'total': item.getNetAmount(cartState.saleType),
          });

          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
            [item.quantity, item.product.id],
          );

          final result = await txn.query(
            'products',
            columns: ['name', 'current_stock', 'min_stock'],
            where: 'id = ?',
            whereArgs: [item.product.id],
          );
          if (result.isNotEmpty) {
            final double currentStock =
                (result.first['current_stock'] as num?)?.toDouble() ?? 0.0;
            final double minStock =
                (result.first['min_stock'] as num?)?.toDouble() ?? 0.0;
            if (currentStock <= minStock || currentStock < 25) {
              alerts.add('${result.first['name']} (Stock: $currentStock)');
            }
          }
        }
      });

      // Refresh products to show updated stock
      ref.read(productsProvider.notifier).loadProducts();

      // Refresh customers list if a new customer was created or pending amount was updated
      if (isNewCustomer || cartState.paymentMethod == 'Credit') {
        ref.read(customersProvider.notifier).loadCustomers();
      }

      // Refresh sales list globally
      ref.read(salesProvider.notifier).loadSales();

      if (print) {
        try {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preparing to print...')),
            );
          }
          await PrintHelper.printReceipt(
            invoiceNumber: invoiceNumber,
            cashierName: 'Admin', // Default cashier for now
            customerName: _customerNameController.text.isEmpty
                ? 'Walk-in Customer'
                : _customerNameController.text,
            items: cartState.items,
            saleType: cartState.saleType,
            subtotal: cartState.subtotal,
            gstAmount: cartState.totalGst,
            discount: cartState.totalItemDiscount + cartState.globalDiscount,
            grandTotal: cartState.grandTotal,
            paymentMethod: cartState.paymentMethod,
          );
        } catch (e) {
          debugPrint('Print Error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Print Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      ref.read(cartProvider.notifier).clearCart();
      _customerNameController.clear();
      _customerMobileController.clear();
      _amountTenderedController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            print
                ? 'Bill Saved & Printed Successfully!'
                : 'Bill Saved Successfully!',
          ),
        ),
      );

      if (alerts.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('LOW STOCK ALERT'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The following items are running low on stock:'),
                const SizedBox(height: 8),
                ...alerts.map(
                  (e) => Text(
                    '• $e',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving bill: $e')));
    }

    _barcodeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final _ = ref.watch(voiceBillingProvider); // keep alive for ref.listen
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<VoiceBillingState>(voiceBillingProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // CLEAR the search bar so the user knows it was handled and added to the cart
        _productSearchController.clear();
      } else if (next.lastTranscript != null &&
          (next.lastTranscript != previous?.lastTranscript ||
              next.updateId != previous?.updateId)) {
        // Only show transcript in search bar if it wasn't successfully added
        final t = next.lastTranscript!;
        _productSearchController.value = TextEditingValue(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
        _searchFocusNode.requestFocus();
      } else if (next.lastTranscript == null &&
          previous?.lastTranscript != null) {
        // Clear the search bar when the transcript state is cleared
        _productSearchController.clear();
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () =>
            _searchFocusNode.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.f2): () => _processBill(false),
        const SingleActivator(LogicalKeyboardKey.f3): () => _processBill(true),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            ref.read(cartProvider.notifier).clearCart(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: const Text(
              'Point of Sale',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),

          body: Row(
            children: [
              // Left/Center Panel - Main POS Area (70%)
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Top Action Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _barcodeController,
                                focusNode: _barcodeFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'Scan Barcode',
                                  prefixIcon: const Icon(Icons.qr_code_scanner),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  isDense: true,
                                ),
                                onSubmitted: _handleBarcodeSubmit,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _ProductSearchCell(
                                onSelected: (Product product) {
                                  _productSearchController.clear();
                                  ref
                                      .read(cartProvider.notifier)
                                      .addProduct(product);
                                  _searchFocusNode.requestFocus();
                                },
                                focusNode: _searchFocusNode,
                                textEditingController: _productSearchController,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Data Table Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    colorScheme.primaryContainer.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  headingRowHeight: 40,
                                  dataRowMinHeight: 40,
                                  dataRowMaxHeight: 40,
                                  columnSpacing: 12,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Discount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'GST',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: [
                                    ...cartState.items.map((item) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              '${item.product.name} (${item.product.unit})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            _EditableCell(
                                              initialValue: item.quantity
                                                  .toStringAsFixed(1),
                                              showButtons: true,
                                              suffixText:
                                                  item.product.unit
                                                          .toLowerCase() ==
                                                      'gram'
                                                  ? 'g'
                                                  : item.product.unit
                                                            .toLowerCase() ==
                                                        'kg'
                                                  ? 'kg'
                                                  : item.product.unit
                                                            .toLowerCase() ==
                                                        'liter'
                                                  ? 'L'
                                                  : item.product.unit
                                                            .toLowerCase() ==
                                                        'milli liter'
                                                  ? 'ml'
                                                  : item.product.unit
                                                            .toLowerCase() ==
                                                        'bag'
                                                  ? 'Bag'
                                                  : null,
                                              onChanged: (val) {
                                                final qty = double.tryParse(
                                                  val,
                                                );
                                                if (qty != null && qty > 0) {
                                                  ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .updateQuantity(
                                                        item.product.id!,
                                                        qty,
                                                      );
                                                }
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            _EditableCell(
                                              initialValue: item
                                                  .getPrice(cartState.saleType)
                                                  .toStringAsFixed(2),
                                              onChanged: (val) {
                                                final price =
                                                    double.tryParse(val) ??
                                                    item.getPrice(
                                                      cartState.saleType,
                                                    );
                                                ref
                                                    .read(cartProvider.notifier)
                                                    .updatePrice(
                                                      item.product.id!,
                                                      price,
                                                    );
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            _EditableCell(
                                              initialValue: item.discount
                                                  .toStringAsFixed(2),
                                              onChanged: (val) {
                                                final disc = double.tryParse(
                                                  val,
                                                );
                                                if (disc != null && disc >= 0) {
                                                  ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .updateDiscount(
                                                        item.product.id!,
                                                        disc,
                                                      );
                                                }
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              item
                                                  .getGstAmount(
                                                    cartState.saleType,
                                                  )
                                                  .toStringAsFixed(2),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              item
                                                  .getNetAmount(
                                                    cartState.saleType,
                                                  )
                                                  .toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () => ref
                                                  .read(cartProvider.notifier)
                                                  .removeProduct(
                                                    item.product.id!,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    if (cartState.items.isEmpty)
                                      const DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              'No items in cart.',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Sidebar - Checkout & Customer (30%)
              Container(
                width: 400, // Fixed width for sidebar
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    left: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Customer Section
                            Text(
                              'Customer Details',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            RawAutocomplete<Customer>(
                              textEditingController: _customerMobileController,
                              focusNode: _customerMobileFocusNode,
                              displayStringForOption: (c) => c.mobile ?? '',
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty)
                                  return const Iterable<Customer>.empty();
                                final customersState = ref.read(
                                  customersProvider,
                                );
                                if (!customersState.hasValue)
                                  return const Iterable<Customer>.empty();
                                return customersState.value!.where(
                                  (c) =>
                                      c.mobile != null &&
                                      c.mobile!.contains(textEditingValue.text),
                                );
                              },
                              onSelected: (Customer c) {
                                _customerMobileController.text = c.mobile ?? '';
                                _customerNameController.text = c.name;
                                ref
                                    .read(cartProvider.notifier)
                                    .updateCustomerDetails(
                                      name: c.name,
                                      mobile: c.mobile,
                                    );
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    return CallbackShortcuts(
                                      bindings:
                                          <ShortcutActivator, VoidCallback>{
                                            const SingleActivator(
                                              LogicalKeyboardKey.arrowUp,
                                            ): () {},
                                            const SingleActivator(
                                              LogicalKeyboardKey.arrowDown,
                                            ): () {},
                                          },
                                      child: TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Mobile Number (Search/Add)',
                                          prefixIcon: const Icon(Icons.phone),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (val) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateCustomerDetails(
                                                name: _customerNameController
                                                    .text,
                                                mobile: val,
                                              );
                                        },
                                      ),
                                    );
                                  },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: 350,
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(
                                            index,
                                          );
                                          return ListTile(
                                            title: Text(
                                              '${option.mobile} - ${option.name}',
                                            ),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            RawAutocomplete<Customer>(
                              textEditingController: _customerNameController,
                              focusNode: _customerNameFocusNode,
                              displayStringForOption: (c) => c.name,
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty)
                                  return const Iterable<Customer>.empty();
                                final customersState = ref.read(
                                  customersProvider,
                                );
                                if (!customersState.hasValue)
                                  return const Iterable<Customer>.empty();
                                return customersState.value!.where(
                                  (c) => c.name.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              onSelected: (Customer c) {
                                _customerNameController.text = c.name;
                                if (c.mobile != null && c.mobile!.isNotEmpty) {
                                  _customerMobileController.text = c.mobile!;
                                }
                                ref
                                    .read(cartProvider.notifier)
                                    .updateCustomerDetails(
                                      name: c.name,
                                      mobile: _customerMobileController.text,
                                    );
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    return CallbackShortcuts(
                                      bindings:
                                          <ShortcutActivator, VoidCallback>{
                                            const SingleActivator(
                                              LogicalKeyboardKey.arrowUp,
                                            ): () {},
                                            const SingleActivator(
                                              LogicalKeyboardKey.arrowDown,
                                            ): () {},
                                          },
                                      child: TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Customer Name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (val) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateCustomerDetails(
                                                name: val,
                                                mobile:
                                                    _customerMobileController
                                                        .text,
                                              );
                                        },
                                      ),
                                    );
                                  },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: 350,
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(
                                            index,
                                          );
                                          return ListTile(
                                            title: Text(
                                              '${option.name} (${option.mobile ?? "No Mobile"})',
                                            ),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // Sale Type Toggle
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment<String>(
                                    value: 'Retail',
                                    label: Text('Retail'),
                                    icon: Icon(Icons.storefront),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'Hotel',
                                    label: Text('Hotel'),
                                    icon: Icon(Icons.hotel),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'Wholesale',
                                    label: Text('Wholesale'),
                                    icon: Icon(Icons.inventory_2),
                                  ),
                                ],
                                selected: {
                                  (cartState.saleType as dynamic) ?? 'Retail',
                                },
                                onSelectionChanged: (Set<String> newSelection) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .setSaleType(newSelection.first);
                                },
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Summary Section
                            Text(
                              'Bill Summary',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildSummaryRow(
                                    'Subtotal',
                                    cartState.subtotal,
                                  ),
                                  _buildSummaryRow(
                                    'Discount',
                                    -(cartState.totalItemDiscount +
                                        cartState.globalDiscount),
                                    isDiscount: true,
                                  ),
                                  _buildSummaryRow(
                                    'Tax (GST)',
                                    cartState.totalGst,
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'GRAND TOTAL',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '₹${cartState.grandTotal.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Payment Mode
                            Text(
                              'Payment Method',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'Cash',
                                  label: Text('Cash'),
                                  icon: Icon(Icons.money),
                                ),
                                ButtonSegment(
                                  value: 'UPI',
                                  label: Text('UPI'),
                                  icon: Icon(Icons.qr_code),
                                ),
                                ButtonSegment(
                                  value: 'Credit',
                                  label: Text('Credit'),
                                  icon: Icon(Icons.credit_card),
                                ),
                              ],
                              selected: {
                                (cartState.paymentMethod as dynamic) ?? 'Cash',
                              },
                              onSelectionChanged: (Set<String> newSelection) {
                                ref
                                    .read(cartProvider.notifier)
                                    .setPaymentMethod(newSelection.first);
                              },
                              style: ButtonStyle(
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                            if (cartState.paymentMethod == 'Cash') ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _amountTenderedController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Cash Received (₹)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  double tendered =
                                      double.tryParse(
                                        _amountTenderedController.text,
                                      ) ??
                                      0.0;
                                  double change =
                                      tendered - cartState.grandTotal;
                                  return Text(
                                    'Change: ₹${(change > 0 ? change : 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Print and Save Buttons at Bottom
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(64),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colorScheme.primary,
                              ),
                              icon: const Icon(Icons.save, size: 28),
                              label: const Text(
                                'SAVE (F2)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              onPressed: () => _processBill(false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(64),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.green.shade600,
                              ),
                              icon: const Icon(Icons.print, size: 28),
                              label: const Text(
                                'SAVE & PRINT (F3)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              onPressed: () => _processBill(true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableCell extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool showButtons;
  final String? suffixText;

  const _EditableCell({
    required this.initialValue,
    required this.onChanged,
    this.showButtons = false,
    this.suffixText,
  });

  @override
  _EditableCellState createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    final qty = double.tryParse(_controller.text) ?? 1.0;
    final newQty = qty + 1;
    _controller.text = newQty.toStringAsFixed(1);
    widget.onChanged(_controller.text);
  }

  void _decrement() {
    final qty = double.tryParse(_controller.text) ?? 1.0;
    if (qty > 1) {
      final newQty = qty - 1;
      _controller.text = newQty.toStringAsFixed(1);
      widget.onChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showButtons)
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: Colors.red,
            ),
            onPressed: _decrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        if (widget.showButtons) const SizedBox(width: 8),
        SizedBox(
          width: widget.showButtons
              ? (widget.suffixText != null ? 80 : 50)
              : (widget.suffixText != null ? 100 : 90),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              suffixText: widget.suffixText,
            ),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.showButtons) const SizedBox(width: 8),
        if (widget.showButtons)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: Colors.green,
            ),
            onPressed: _increment,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
      ],
    );
  }
}

class _ProductSearchCell extends ConsumerStatefulWidget {
  final ValueChanged<Product> onSelected;
  final FocusNode? focusNode;
  final TextEditingController? textEditingController;

  const _ProductSearchCell({
    required this.onSelected,
    this.focusNode,
    this.textEditingController,
  });

  @override
  ConsumerState<_ProductSearchCell> createState() => _ProductSearchCellState();
}

class _ProductSearchCellState extends ConsumerState<_ProductSearchCell> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<Product> _filteredProducts = [];

  TextEditingController get _controller =>
      widget.textEditingController ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim().toLowerCase();
    final productsState = ref.read(productsProvider);
    final products = productsState.value ?? [];

    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    final filtered = products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.contains(query));
    }).toList();

    setState(() => _filteredProducts = filtered);

    if (filtered.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Retail: ₹${product.sellingPrice.toStringAsFixed(2)} | Stock: ${product.currentStock.toInt()}',
                    ),
                    onTap: () {
                      _removeOverlay();
                      _controller.clear();
                      widget.onSelected(product);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          labelText: 'Search Item (F1)',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        onSubmitted: (_) {
          if (_filteredProducts.isNotEmpty) {
            _removeOverlay();
            _controller.clear();
            widget.onSelected(_filteredProducts.first);
          }
        },
      ),
    );
  }
}
