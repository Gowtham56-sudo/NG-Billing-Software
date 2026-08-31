import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../sales/providers/sales_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../purchases/providers/purchases_provider.dart';
import '../../customers/providers/customers_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = [
      {'title': 'Daily Sales Report', 'type': 'daily_sales', 'icon': Icons.today, 'color': Colors.blue},
      {'title': 'Monthly Sales Report', 'type': 'monthly_sales', 'icon': Icons.calendar_month, 'color': Colors.green},
      {'title': 'Stock / Inventory Report', 'type': 'stock', 'icon': Icons.inventory, 'color': Colors.orange},
      {'title': 'GST & Tax Report', 'type': 'gst', 'icon': Icons.account_balance, 'color': Colors.purple},
      {'title': 'Purchase & Supplier Report', 'type': 'purchase', 'icon': Icons.shopping_cart, 'color': Colors.teal},
      {'title': 'Customer Balance Report', 'type': 'customer', 'icon': Icons.people, 'color': Colors.indigo},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset Reports'),
            onPressed: () => _showResetReportsDialog(context, ref),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Reports',
            onPressed: () {
              ref.read(salesProvider.notifier).loadSales();
              ref.read(productsProvider.notifier).loadProducts();
              ref.read(purchasesProvider.notifier).loadPurchases();
              ref.read(customersProvider.notifier).loadCustomers();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.delete_sweep),
        label: const Text('Reset Reports'),
        onPressed: () => _showResetReportsDialog(context, ref),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Prominent Top Header Card with Action Buttons
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Analytics & Financial Reports',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Live breakdown of sales, GST, inventory, and supplier purchases.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        onPressed: () {
                          ref.read(salesProvider.notifier).loadSales();
                          ref.read(productsProvider.notifier).loadProducts();
                          ref.read(purchasesProvider.notifier).loadPurchases();
                          ref.read(customersProvider.notifier).loadCustomers();
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Reports Data', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showResetReportsDialog(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Reports Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final color = report['color'] as Color;
                  final title = report['title'] as String;
                  final type = report['type'] as String;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openReportDialog(context, ref, title, type),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(report['icon'] as IconData, color: color, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _openReportDialog(context, ref, title, type),
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('View'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _exportReportCSV(context, ref, title, type),
                                        icon: const Icon(Icons.download, size: 16),
                                        label: const Text('CSV'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetReportsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Reset Reports & Analytics Data'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select which report data you want to reset. This will permanently delete the corresponding transaction records from the local database.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ListTile(
                tileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text('Reset Today\'s Sales Data', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Clears all invoices generated today only.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAction(
                    context,
                    title: 'Reset Today\'s Sales?',
                    message: 'Are you sure you want to delete all sales invoices generated today?',
                    onConfirm: () async {
                      await ref.read(salesProvider.notifier).clearTodaysSales();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.green, content: Text('Today\'s sales data reset successfully!')),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.orange.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                title: const Text('Reset All Sales & GST History', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Clears all past sales, invoices, and GST records.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAction(
                    context,
                    title: 'Reset All Sales History?',
                    message: 'This will permanently remove ALL historical sales invoices and GST records from the system.',
                    onConfirm: () async {
                      await ref.read(salesProvider.notifier).clearAllSales();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.green, content: Text('All sales & GST history cleared!')),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.shopping_cart, color: Colors.teal),
                title: const Text('Reset Inward Purchase History', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Clears all supplier purchase records.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAction(
                    context,
                    title: 'Reset Purchase History?',
                    message: 'This will remove all recorded inward supplier purchase bills.',
                    onConfirm: () async {
                      await ref.read(purchasesProvider.notifier).clearAllPurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.green, content: Text('Purchase records cleared!')),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.restore_from_trash, color: Colors.red),
                title: const Text('Full Reset (All Sales & Purchases)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: const Text('Complete reset of all sales, GST, and purchase reports.'),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAction(
                    context,
                    title: 'Full Reports Reset?',
                    message: 'CAUTION: This will delete ALL sales invoices, GST records, and purchase history. Product catalog will remain intact.',
                    onConfirm: () async {
                      await ref.read(salesProvider.notifier).clearAllSales();
                      await ref.read(purchasesProvider.notifier).clearAllPurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.red, content: Text('All sales & purchase reports completely reset!')),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Confirm & Reset'),
          ),
        ],
      ),
    );
  }

  void _openReportDialog(BuildContext context, WidgetRef ref, String title, String type) {
    final sales = ref.read(salesProvider).value ?? [];
    final products = ref.read(productsProvider).value ?? [];
    final purchases = ref.read(purchasesProvider).value ?? [];
    final customers = ref.read(customersProvider).value ?? [];

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final monthStr = DateTime.now().toIso8601String().substring(0, 7);

    Widget content = const SizedBox();

    if (type == 'daily_sales') {
      final todaySales = sales.where((s) => s.date.startsWith(todayStr)).toList();
      final total = todaySales.fold<double>(0, (sum, s) => sum + s.grandTotal);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Invoices: ${todaySales.length} | Total Revenue: ₹${total.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: 600,
            child: ListView.separated(
              itemCount: todaySales.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final s = todaySales[i];
                return ListTile(
                  title: Text(s.invoiceNumber),
                  subtitle: Text('Mode: ${s.paymentMethod ?? "Cash"} | Discount: ₹${s.discount.toStringAsFixed(2)}'),
                  trailing: Text('₹${s.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      );
    } else if (type == 'monthly_sales') {
      final monthSales = sales.where((s) => s.date.startsWith(monthStr)).toList();
      final total = monthSales.fold<double>(0, (sum, s) => sum + s.grandTotal);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("This Month Invoices: ${monthSales.length} | Total Revenue: ₹${total.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: 600,
            child: ListView.separated(
              itemCount: monthSales.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final s = monthSales[i];
                return ListTile(
                  title: Text(s.invoiceNumber),
                  subtitle: Text('Date: ${s.date.substring(0, 10)} | Mode: ${s.paymentMethod ?? "Cash"}'),
                  trailing: Text('₹${s.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      );
    } else if (type == 'stock') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Products: ${products.length}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: 600,
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final p = products[i];
                final isLow = p.currentStock <= p.minStock;
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('Price: ₹${p.sellingPrice.toStringAsFixed(2)} | Unit: ${p.unit}'),
                  trailing: Text(
                    'Stock: ${p.currentStock.toInt()}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isLow ? Colors.red : Colors.green),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (type == 'gst') {
      final totalGst = sales.fold<double>(0, (sum, s) => sum + s.gstAmount);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total GST Collected: ₹${totalGst.toStringAsFixed(2)} across ${sales.length} bills",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: 600,
            child: ListView.separated(
              itemCount: sales.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final s = sales[i];
                return ListTile(
                  title: Text(s.invoiceNumber),
                  subtitle: Text('Date: ${s.date.substring(0, 10)} | Grand Total: ₹${s.grandTotal.toStringAsFixed(2)}'),
                  trailing: Text('GST: ₹${s.gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                );
              },
            ),
          ),
        ],
      );
    } else if (type == 'purchase') {
      final totalPurchase = purchases.fold<double>(0, (sum, p) => sum + p.totalAmount);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Inward Purchases: ₹${totalPurchase.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: 600,
            child: ListView.separated(
              itemCount: purchases.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final pu = purchases[i];
                return ListTile(
                  title: Text(pu.invoiceNumber),
                  subtitle: Text('Date: ${pu.date} | GST: ₹${pu.gstAmount.toStringAsFixed(2)}'),
                  trailing: Text('₹${pu.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      );
    } else {
      content = SizedBox(
        height: 300,
        width: 600,
        child: ListView.separated(
          itemCount: customers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final c = customers[i];
            return ListTile(
              title: Text(c.name),
              subtitle: Text('Mobile: ${c.mobile ?? "N/A"}'),
              trailing: Text('Pending: ₹${c.pendingAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: content,
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _exportReportCSV(context, ref, title, type);
            },
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReportCSV(BuildContext context, WidgetRef ref, String title, String type) async {
    final sales = ref.read(salesProvider).value ?? [];
    final products = ref.read(productsProvider).value ?? [];
    final purchases = ref.read(purchasesProvider).value ?? [];
    final customers = ref.read(customersProvider).value ?? [];

    final buffer = StringBuffer();

    if (type == 'daily_sales' || type == 'monthly_sales' || type == 'gst') {
      buffer.writeln('Invoice Number,Date,Payment Mode,Subtotal,Discount,Tax,Grand Total');
      for (final s in sales) {
        buffer.writeln('${s.invoiceNumber},${s.date},${s.paymentMethod ?? "Cash"},${s.subtotal},${s.discount},${s.gstAmount},${s.grandTotal}');
      }
    } else if (type == 'stock') {
      buffer.writeln('ID,Product Name,Unit,Unit Value,Purchase Price,Selling Price,Wholesale Price,Current Stock,Min Stock');
      for (final p in products) {
        buffer.writeln('${p.id},"${p.name}",${p.unit},${p.unitValue},${p.purchasePrice},${p.sellingPrice},${p.wholesalePrice},${p.currentStock},${p.minStock}');
      }
    } else if (type == 'purchase') {
      buffer.writeln('ID,Invoice Number,Date,Total Amount,GST Amount');
      for (final pu in purchases) {
        buffer.writeln('${pu.id},${pu.invoiceNumber},${pu.date},${pu.totalAmount},${pu.gstAmount}');
      }
    } else {
      buffer.writeln('ID,Name,Mobile,Address,GST Number,Pending Amount,Paid Amount');
      for (final c in customers) {
        buffer.writeln('${c.id},"${c.name}",${c.mobile ?? ""},"${c.address ?? ""}",${c.gstNumber ?? ""},${c.pendingAmount},${c.paidAmount}');
      }
    }

    try {
      final desktopDir = Directory(p.join(Platform.environment['USERPROFILE'] ?? '', 'Desktop'));
      final targetDir = await desktopDir.exists() ? desktopDir : Directory.current;
      final fileName = '${type}_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Report exported to Desktop: $fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
