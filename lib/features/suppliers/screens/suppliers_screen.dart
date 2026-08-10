import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/suppliers_provider.dart';
import '../../../models/supplier.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersState = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(suppliersProvider.notifier).loadSuppliers(),
          ),
        ],
      ),
      body: suppliersState.when(
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(child: Text('No suppliers found. Add some!'));
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: PaginatedDataTable(
                  header: const Text('All Suppliers'),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Mobile')),
                    DataColumn(label: Text('GST Number')),
                    DataColumn(label: Text('Pending Payments')),
                    DataColumn(label: Text('Actions')),
                  ],
                  source: SupplierDataSource(suppliers, ref),
                  rowsPerPage: 10,
                  showCheckboxColumn: false,
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddSupplierDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final gstController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gstController,
                decoration: const InputDecoration(labelText: 'GST Number', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final supplier = Supplier(
                    name: nameController.text,
                    mobile: mobileController.text,
                    gstNumber: gstController.text,
                  );
                  ref.read(suppliersProvider.notifier).addSupplier(supplier);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class SupplierDataSource extends DataTableSource {
  final List<Supplier> suppliers;
  final WidgetRef ref;

  SupplierDataSource(this.suppliers, this.ref);

  @override
  DataRow? getRow(int index) {
    if (index >= suppliers.length) return null;
    final supplier = suppliers[index];
    return DataRow(cells: [
      DataCell(Text(supplier.id?.toString() ?? '-')),
      DataCell(Text(supplier.name)),
      DataCell(Text(supplier.mobile ?? '-')),
      DataCell(Text(supplier.gstNumber ?? '-')),
      DataCell(Text('₹${supplier.pendingPayments.toStringAsFixed(2)}')),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => ref.read(suppliersProvider.notifier).deleteSupplier(supplier.id!),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => suppliers.length;

  @override
  int get selectedRowCount => 0;
}
