import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchases_provider.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesState = ref.watch(purchasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(purchasesProvider.notifier).loadPurchases(),
          ),
        ],
      ),
      body: purchasesState.when(
        data: (purchases) {
          if (purchases.isEmpty) {
            return const Center(child: Text('No purchases found. Create a new purchase invoice!'));
          }
          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt)),
                  title: Text('Invoice: ${purchase.invoiceNumber}'),
                  subtitle: Text('Date: ${purchase.date}  |  Supplier ID: ${purchase.supplierId}'),
                  trailing: Text(
                    '₹${purchase.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Placeholder for complex Purchase Entry Form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase Entry Form coming soon in Phase 4 completion')),
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Purchase Entry'),
      ),
    );
  }
}
