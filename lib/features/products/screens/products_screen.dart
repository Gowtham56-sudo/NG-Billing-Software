import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/products_provider.dart';
import '../../../models/product.dart';
import '../../../database/sqlite_service.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Products',
            onPressed: () => ref.read(productsProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: productsState.when(
        data: (products) {
          final filteredProducts = _searchQuery.isEmpty
              ? products
              : products
                    .where(
                      (p) =>
                          p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          (p.barcode?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false),
                    )
                    .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Product Name or Barcode',
                    prefixIcon: const Icon(Icons.search),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              if (filteredProducts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No products found.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${product.name} (${product.unit})',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'Retail: ₹${product.sellingPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Wholesale: ₹${product.wholesalePrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Hotel: ₹${product.hotelPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'GST: ${product.gstPercentage}%',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Stock: ${product.currentStock.toInt()}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.analytics,
                                      color: Colors.purple,
                                    ),
                                    tooltip: 'Analytics',
                                    onPressed: () =>
                                        _showProductAnalytics(context, product),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Edit',
                                    onPressed: () => _showEditProductDialog(
                                      context,
                                      ref,
                                      product,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Product'),
                                          content: Text(
                                            'Are you sure you want to delete ${product.name}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      productsProvider.notifier,
                                                    )
                                                    .deleteProduct(product.id!);
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddProductDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final barcodeController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final wholesalePriceController = TextEditingController();
    final hotelPriceController = TextEditingController();
    final gstPercentageController = TextEditingController(text: '18');
    final currentStockController = TextEditingController();
    final minStockController = TextEditingController();
    final unitValueController = TextEditingController(text: '1.0');

    String selectedUnit = 'Piece';
    final List<String> units = [
      'Piece',
      'Kg',
      'Gram',
      'Liter',
      'Milli Liter',
      'Bag',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => selectedUnit = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: unitValueController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: selectedUnit == 'Gram'
                                    ? 'Base Qty (e.g. 100 for 100g)'
                                    : selectedUnit == 'Kg'
                                    ? 'Base Qty (e.g. 25 for 25Kg)'
                                    : selectedUnit == 'Liter'
                                    ? 'Base Qty (e.g. 5 for 5L)'
                                    : selectedUnit == 'Milli Liter'
                                    ? 'Base Qty (e.g. 500 for 500ml)'
                                    : selectedUnit == 'Bag'
                                    ? 'Base Qty (e.g. 1 for 1 Bag)'
                                    : 'Base Qty (e.g. 1)',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pricing Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: purchasePriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Purchase Price (₹)',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: sellingPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Retail Price (₹) *',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: wholesalePriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Wholesale Price (₹) *',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: hotelPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Hotel Price (₹)',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Inventory & Tax',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: gstPercentageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'GST Percentage (%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: currentStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Stock Alert',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      return; // Basic validation
                    }

                    final product = Product(
                      name: nameController.text.trim(),
                      barcode: barcodeController.text.trim().isEmpty
                          ? null
                          : barcodeController.text.trim(),
                      purchasePrice:
                          double.tryParse(purchasePriceController.text) ?? 0.0,
                      sellingPrice:
                          double.tryParse(sellingPriceController.text) ?? 0.0,
                      wholesalePrice:
                          double.tryParse(wholesalePriceController.text) ?? 0.0,
                      hotelPrice:
                          double.tryParse(hotelPriceController.text) ?? 0.0,
                      gstPercentage:
                          double.tryParse(gstPercentageController.text) ?? 0.0,
                      currentStock:
                          double.tryParse(currentStockController.text) ?? 0.0,
                      minStock: double.tryParse(minStockController.text) ?? 0.0,
                      unit: selectedUnit,
                      unitValue:
                          double.tryParse(unitValueController.text) ?? 1.0,
                    );
                    ref.read(productsProvider.notifier).addProduct(product);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    final nameController = TextEditingController(text: product.name);
    final barcodeController = TextEditingController(text: product.barcode);
    final purchasePriceController = TextEditingController(
      text: product.purchasePrice.toString(),
    );
    final sellingPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );
    final wholesalePriceController = TextEditingController(
      text: product.wholesalePrice.toString(),
    );
    final hotelPriceController = TextEditingController(
      text: product.hotelPrice.toString(),
    );
    final gstPercentageController = TextEditingController(
      text: product.gstPercentage.toString(),
    );
    final currentStockController = TextEditingController(
      text: product.currentStock.toString(),
    );
    final minStockController = TextEditingController(
      text: product.minStock.toString(),
    );
    final unitValueController = TextEditingController(
      text: product.unitValue.toString(),
    );

    String selectedUnit = product.unit;
    final List<String> units = [
      'Piece',
      'Kg',
      'Gram',
      'Liter',
      'Milli Liter',
      'Bag',
    ];
    if (!units.contains(selectedUnit)) units.add(selectedUnit);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => selectedUnit = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: unitValueController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: selectedUnit == 'Gram'
                                    ? 'Base Qty (e.g. 100 for 100g)'
                                    : selectedUnit == 'Kg'
                                    ? 'Base Qty (e.g. 25 for 25Kg)'
                                    : selectedUnit == 'Liter'
                                    ? 'Base Qty (e.g. 5 for 5L)'
                                    : selectedUnit == 'Milli Liter'
                                    ? 'Base Qty (e.g. 500 for 500ml)'
                                    : selectedUnit == 'Bag'
                                    ? 'Base Qty (e.g. 1 for 1 Bag)'
                                    : 'Base Qty (e.g. 1)',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pricing Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: purchasePriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Purchase Price (₹)',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: sellingPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Retail Price (₹) *',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: wholesalePriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Wholesale Price (₹) *',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: hotelPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Hotel Price (₹)',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Inventory & Tax',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: gstPercentageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'GST Percentage (%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: currentStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Stock Alert',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;

                    final updatedProduct = Product(
                      id: product.id,
                      name: nameController.text.trim(),
                      barcode: barcodeController.text.trim().isEmpty
                          ? null
                          : barcodeController.text.trim(),
                      purchasePrice:
                          double.tryParse(purchasePriceController.text) ?? 0.0,
                      sellingPrice:
                          double.tryParse(sellingPriceController.text) ?? 0.0,
                      wholesalePrice:
                          double.tryParse(wholesalePriceController.text) ?? 0.0,
                      hotelPrice:
                          double.tryParse(hotelPriceController.text) ?? 0.0,
                      gstPercentage:
                          double.tryParse(gstPercentageController.text) ?? 0.0,
                      currentStock:
                          double.tryParse(currentStockController.text) ?? 0.0,
                      minStock: double.tryParse(minStockController.text) ?? 0.0,
                      unit: selectedUnit,
                      unitValue:
                          double.tryParse(unitValueController.text) ?? 1.0,
                    );
                    ref
                        .read(productsProvider.notifier)
                        .updateProduct(updatedProduct);
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProductAnalytics(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${product.name} Analytics'),
          content: SizedBox(
            width: 800,
            height: 400,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchProductStats(product.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final stats = snapshot.data!;
                final double cash = stats['Cash'] ?? 0.0;
                final double upi = stats['UPI'] ?? 0.0;
                final double credit = stats['Credit'] ?? 0.0;
                final double completed = stats['Completed'] ?? 0.0;
                final double pending = stats['Pending'] ?? 0.0;

                final outOfStock = product.currentStock <= 0 ? 1.0 : 0.0;
                final lowStock =
                    (product.currentStock > 0 &&
                        product.currentStock <= product.minStock)
                    ? 1.0
                    : 0.0;
                final healthyStock = product.currentStock > product.minStock
                    ? 1.0
                    : 0.0;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StaticPieChart(
                        title: "Payment Methods",
                        color1: Colors.green,
                        val1: cash,
                        label1: 'Cash',
                        color2: Colors.blue,
                        val2: upi,
                        label2: 'UPI',
                        color3: Colors.orange,
                        val3: credit,
                        label3: 'Credit',
                      ),
                      const SizedBox(width: 32),
                      _StaticPieChart(
                        title: "Sales Status",
                        color1: Colors.indigo,
                        val1: completed,
                        label1: 'Completed',
                        color2: Colors.amber,
                        val2: pending,
                        label2: 'Pending',
                        color3: Colors.transparent,
                        val3: 0.0,
                        label3: '',
                      ),
                      const SizedBox(width: 32),
                      _StaticPieChart(
                        title: "Stock Status",
                        color1: Colors.green,
                        val1: healthyStock,
                        label1: 'Healthy',
                        color2: Colors.orange,
                        val2: lowStock,
                        label2: 'Low',
                        color3: Colors.red,
                        val3: outOfStock,
                        label3: 'Out',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchProductStats(int productId) async {
    final db = await SqliteService.database;
    final stats = <String, dynamic>{};

    // Payment methods
    final paymentRes = await db.rawQuery(
      '''
      SELECT s.payment_method, COUNT(*) as count 
      FROM sales s 
      JOIN sale_items si ON s.id = si.sale_id 
      WHERE si.product_id = ? 
      GROUP BY s.payment_method
    ''',
      [productId],
    );
    for (var row in paymentRes) {
      if (row['payment_method'] != null) {
        stats[row['payment_method'] as String] = (row['count'] as int)
            .toDouble();
      }
    }

    // Sales Status
    final statusRes = await db.rawQuery(
      '''
      SELECT s.status, COUNT(*) as count 
      FROM sales s 
      JOIN sale_items si ON s.id = si.sale_id 
      WHERE si.product_id = ? 
      GROUP BY s.status
    ''',
      [productId],
    );
    for (var row in statusRes) {
      if (row['status'] != null) {
        stats[row['status'] as String] = (row['count'] as int).toDouble();
      }
    }

    return stats;
  }
}

class _StaticPieChart extends StatelessWidget {
  final String title;
  final Color color1, color2, color3;
  final double originalVal1, originalVal2, originalVal3;
  final String label1, label2, label3;

  const _StaticPieChart({
    required this.title,
    required this.color1,
    required double val1,
    required this.label1,
    required this.color2,
    required double val2,
    required this.label2,
    required this.color3,
    required double val3,
    required this.label3,
  }) : originalVal1 = val1,
       originalVal2 = val2,
       originalVal3 = val3;

  @override
  Widget build(BuildContext context) {
    bool hasData = (originalVal1 + originalVal2 + originalVal3) > 0;

    // Inject demo data if no data exists
    double v1 = hasData ? originalVal1 : 65.0;
    double v2 = hasData ? originalVal2 : 25.0;
    double v3 = hasData ? originalVal3 : 10.0;

    // Add variation based on title so demo charts don't look identical
    if (!hasData && title == "Sales Status") {
      v1 = 80.0;
      v2 = 20.0;
      v3 = 0.0;
    } else if (!hasData && title == "Stock Status") {
      v1 = 40.0;
      v2 = 50.0;
      v3 = 10.0;
    }

    double sum = v1 + v2 + v3;
    if (sum == 0) sum = 1;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              builder: (context, animValue, child) {
                return Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4 * animValue,
                      centerSpaceRadius: 25 + (10 * animValue),
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: v1,
                          color: color1,
                          radius: 25 * animValue,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: v2,
                          color: color2,
                          radius: 25 * animValue,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: v3,
                          color: color3,
                          radius: 25 * animValue,
                          showTitle: false,
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 0),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              if (label1.isNotEmpty) _LegendItem(color: color1, label: label1),
              if (label2.isNotEmpty) _LegendItem(color: color2, label: label2),
              if (label3.isNotEmpty) _LegendItem(color: color3, label: label3),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            const Text(
              "Demo Data Active",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const Text(
              "Live Data Active",
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
