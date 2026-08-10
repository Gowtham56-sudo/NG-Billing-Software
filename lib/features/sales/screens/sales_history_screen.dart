import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sales_provider.dart';
import '../../../models/sale.dart';


class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(salesProvider.notifier).loadSales());
  }

  void _showSaleDetails(Sale sale) async {
    final items = await ref.read(salesProvider.notifier).getSaleItems(sale.id!);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invoice: ${sale.invoiceNumber}'),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(sale.date))}'),
                Text('Payment: ${sale.paymentMethod}'),
                Text('Status: ${sale.status}'),
                const SizedBox(height: 16),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text('Product ID: ${item.productId}'), // We'd need to join with products table for name
                        subtitle: Text('Qty: ${item.qty} | Price: ₹${item.price}'),
                        trailing: Text('Total: ₹${item.total.toStringAsFixed(2)}'),
                      );
                    },
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Grand Total: ₹${sale.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesState = ref.watch(salesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Sales History', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(salesProvider.notifier).loadSales(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
          child: salesState.when(
            data: (sales) {
              if (sales.isEmpty) {
                return const Center(child: Text('No sales found.'));
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(colorScheme.primaryContainer.withValues(alpha: 0.5)),
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    ],
                    rows: sales.map((sale) {
                      return DataRow(
                        onSelectChanged: (_) => _showSaleDetails(sale),
                        cells: [
                          DataCell(Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(sale.date)))),
                          DataCell(Text(sale.paymentMethod ?? '-')),
                          DataCell(Text(sale.status ?? '-')),
                          DataCell(Text('₹${sale.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }
}
