import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/providers/products_provider.dart';
import '../../../models/product.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
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
        title: const Text('Inventory & Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productsProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: productsState.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products in inventory.'));
          }

          // Filter low stock globally
          final lowStockProducts = products.where((p) => p.currentStock <= p.minStock || p.currentStock < 25).toList();

          // Filter by search query
          final filteredProducts = _searchQuery.isEmpty 
              ? products 
              : products.where((p) => 
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lowStockProducts.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 16),
                          Text(
                            '${lowStockProducts.length} items are running low on stock!',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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

                  SizedBox(
                    width: double.infinity,
                    child: PaginatedDataTable(
                      header: const Text('Current Stock Levels'),
                      columns: const [
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Barcode')),
                        DataColumn(label: Text('Current Stock')),
                        DataColumn(label: Text('Min Stock')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      source: InventoryDataSource(filteredProducts, context, (product, newStock) {
                        final updatedProduct = product.copyWith(currentStock: newStock);
                        ref.read(productsProvider.notifier).updateProduct(updatedProduct);
                      }),
                      rowsPerPage: 10,
                      showCheckboxColumn: false,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class InventoryDataSource extends DataTableSource {
  final List<Product> products;
  final BuildContext context;
  final void Function(Product, double) onAdjust;

  InventoryDataSource(this.products, this.context, this.onAdjust);

  @override
  DataRow? getRow(int index) {
    if (index >= products.length) return null;
    final product = products[index];
    final isLowStock = product.currentStock <= product.minStock;

    return DataRow(cells: [
      DataCell(Text(product.name)),
      DataCell(Text(product.barcode ?? '-')),
      DataCell(Text(
        product.currentStock.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isLowStock ? Colors.red : Colors.green,
        ),
      )),
      DataCell(Text(product.minStock.toString())),
      DataCell(
        Chip(
          label: Text(isLowStock ? 'Low Stock' : 'In Stock'),
          backgroundColor: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
          labelStyle: TextStyle(color: isLowStock ? Colors.red.shade900 : Colors.green.shade900),
        ),
      ),
      DataCell(
        ElevatedButton.icon(
          icon: const Icon(Icons.edit_note, size: 16),
          label: const Text('Adjust'),
          onPressed: () {
            _showAdjustmentDialog(product);
          },
        ),
      ),
    ]);
  }

  void _showAdjustmentDialog(Product product) {
    final controller = TextEditingController(text: product.currentStock.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adjust Stock: ${product.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'New Stock Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) {
                  onAdjust(product, val);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock updated successfully'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => products.length;

  @override
  int get selectedRowCount => 0;
}
