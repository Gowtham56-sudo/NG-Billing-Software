import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {'title': 'Daily Sales Report', 'icon': Icons.today},
      {'title': 'Monthly Sales Report', 'icon': Icons.calendar_month},
      {'title': 'Yearly Sales Report', 'icon': Icons.calendar_today},
      {'title': 'GST Report', 'icon': Icons.account_balance},
      {'title': 'Purchase Report', 'icon': Icons.shopping_cart},
      {'title': 'Stock/Inventory Report', 'icon': Icons.inventory},
      {'title': 'Profit Report', 'icon': Icons.trending_up},
      {'title': 'Expense Report', 'icon': Icons.money_off},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Exports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Icon(report['icon'] as IconData),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            report['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.picture_as_pdf, size: 16),
                                label: const Text('PDF'),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.table_chart, size: 16),
                                label: const Text('Excel'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
