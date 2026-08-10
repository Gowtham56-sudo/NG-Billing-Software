import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customers_provider.dart';
import '../../../models/customer.dart';
import '../../../database/sqlite_service.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customersProvider.notifier).loadCustomers(),
          ),
        ],
      ),
      body: customersState.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers found. Add some!'));
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: PaginatedDataTable(
                  header: const Text('All Customers'),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Mobile')),
                    DataColumn(label: Text('Actions')),
                  ],
                  source: CustomerDataSource(customers, ref, context),
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
          _showAddCustomerDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();
    final gstNumberController = TextEditingController();
    final creditLimitController = TextEditingController();
    String? selectedType = 'Retail'; // Default type
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Customer'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: gstNumberController,
                              decoration: const InputDecoration(labelText: 'GST Number', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedType,
                              decoration: const InputDecoration(labelText: 'Customer Type', border: OutlineInputBorder()),
                              items: ['Retail', 'Wholesale', 'VIP'].map<DropdownMenuItem<String>>((String type) {
                                return DropdownMenuItem<String>(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: creditLimitController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Credit Limit (₹)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      final customer = Customer(
                        name: nameController.text.trim(),
                        mobile: mobileController.text.trim().isEmpty ? null : mobileController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        gstNumber: gstNumberController.text.trim().isEmpty ? null : gstNumberController.text.trim(),
                        type: selectedType,
                        creditLimit: double.tryParse(creditLimitController.text) ?? 0.0,
                      );
                      ref.read(customersProvider.notifier).addCustomer(customer);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final WidgetRef ref;
  final BuildContext context;

  CustomerDataSource(this.customers, this.ref, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= customers.length) return null;
    final customer = customers[index];
    return DataRow(cells: [
      DataCell(Text(customer.id?.toString() ?? '-')),
      DataCell(Text(customer.name)),
      DataCell(Text(customer.mobile ?? '-')),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.orange),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CustomerHistoryDialog(customer: customer),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => ref.read(customersProvider.notifier).deleteCustomer(customer.id!),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => customers.length;

  @override
  int get selectedRowCount => 0;
}

class CustomerHistoryDialog extends StatelessWidget {
  final Customer customer;

  const CustomerHistoryDialog({super.key, required this.customer});

  Future<List<Map<String, dynamic>>> _fetchSales() async {
    // Requires importing sqlite_service.dart which we'll add at the top
    final db = await SqliteService.database;
    return await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customer.id],
      orderBy: 'date DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Purchase History: ${customer.name}'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchSales(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final sales = snapshot.data ?? [];
            if (sales.isEmpty) {
              return const Center(child: Text('No purchase history found for this customer.'));
            }

            return ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                final invoice = sale['invoice_number'];
                final date = sale['date'];
                final total = sale['grand_total'];
                final paid = sale['paid_amount'];
                final balance = sale['balance'];
                final method = sale['payment_method'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('Invoice: $invoice | Date: $date'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Grand Total: ₹${total.toStringAsFixed(2)} | Paid: ₹${paid.toStringAsFixed(2)} | Pending: ₹${balance.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        Text(
                          'Payment Method: $method',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: method.toString().toLowerCase() == 'credit' ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
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
  }
}
