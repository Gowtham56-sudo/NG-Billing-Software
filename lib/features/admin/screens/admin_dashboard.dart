import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../purchases/providers/purchases_provider.dart';
import '../../products/screens/products_screen.dart';

import '../../customers/screens/customers_screen.dart';
import '../../suppliers/screens/suppliers_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../models/product.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NextGen Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Customers')),
              NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Suppliers')),
              NavigationRailDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: Text('Inventory')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Reports')),
              NavigationRailDestination(icon: Icon(Icons.manage_accounts_outlined), selectedIcon: Icon(Icons.manage_accounts), label: Text('Users')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildBody(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const ProductsScreen();
      case 2:
        return const CustomersScreen();
      case 3:
        return const SuppliersScreen();
      case 4:
        return const InventoryScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const Center(child: Text('Users Management - Coming Soon'));
      case 7:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider).value ?? [];
    final customers = ref.watch(customersProvider).value ?? [];
    final sales = ref.watch(salesProvider).value ?? [];
    final purchases = ref.watch(purchasesProvider).value ?? [];

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final monthStr = DateTime.now().toIso8601String().substring(0, 7);

    final todaysSalesList = sales.where((s) => s.date.startsWith(todayStr)).toList();
    final monthlySalesList = sales.where((s) => s.date.startsWith(monthStr)).toList();
    final lowStockItems = products.where((p) => p.currentStock <= p.minStock || p.currentStock < 25).toList();
    lowStockItems.sort((a, b) => a.currentStock.compareTo(b.currentStock));
    final lowStockPoints = lowStockItems.take(3).map((e) => e.currentStock).toList();
    if (lowStockPoints.isEmpty) lowStockPoints.addAll([0.0, 0.0, 0.0]);
    while (lowStockPoints.length < 3) {
      lowStockPoints.add(0.0);
    }

    final totalProducts = products.length;
    final totalCustomers = customers.length;

    // Generate Chart Points
    final todaysSalesPoints = todaysSalesList.map((s) => s.grandTotal).toList();
    if (todaysSalesPoints.isEmpty) todaysSalesPoints.add(0.0);
    
    // Group monthly by day for a simplified bar chart
    final Map<String, double> monthlyGrouped = {};
    for (var s in monthlySalesList) {
      final day = s.date.substring(8, 10);
      monthlyGrouped[day] = (monthlyGrouped[day] ?? 0.0) + s.grandTotal;
    }
    final monthlySalesPoints = monthlyGrouped.values.toList();
    if (monthlySalesPoints.isEmpty) monthlySalesPoints.add(0.0);

    final purchasesPoints = purchases.map((p) => p.totalAmount).toList();
    if (purchasesPoints.isEmpty) purchasesPoints.add(0.0);

    // Dummy categories distribution for Pie Chart
    final double cat1 = products.where((p) => p.categoryId == 1).length.toDouble();
    final double cat2 = products.where((p) => p.categoryId == 2).length.toDouble();
    final double cat3 = products.where((p) => p.categoryId != 1 && p.categoryId != 2).length.toDouble();



    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _AnimatedTodaysSalesChart(amount: 14500.50, points: const [10, 25, 15, 30, 20, 40, 35]),
              _AnimatedMonthlySalesChart(amount: 320400.00, points: const [120, 150, 180, 130, 210, 250, 230]),
              _AnimatedPurchasesChart(amount: 85200.75, points: const [50, 40, 70, 60, 90, 80]),
              _AnimatedTotalProductsChart(count: totalProducts, cat1: cat1, cat2: cat2, cat3: cat3),
              _AnimatedTotalCustomersChart(count: totalCustomers),
              _AnimatedProductDemoChart(
                productName: "Coca Cola 1L", 
                sold: 450, remaining: 120, color: Colors.blueAccent
              ),
              _AnimatedProductDemoChart(
                productName: "Lays Classic", 
                sold: 890, remaining: 230, color: Colors.indigo
              ),
              _AnimatedProductDemoChart(
                productName: "Dairy Milk Silk", 
                sold: 340, remaining: 85, color: Colors.brown
              ),
            ],
          ),
          const SizedBox(height: 32),
          _AnimatedLowStockBanner(items: lowStockItems),
          const SizedBox(height: 32),
          Text(
            'Recent Bills',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: sales.isEmpty 
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No recent sales.")))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length > 5 ? 5 : sales.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = sales[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.receipt)),
                      title: Text(s.invoiceNumber),
                      subtitle: Text(s.date.substring(0, 10)),
                      trailing: Text('₹${s.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
              ),
          )
        ],
      ),
    );
  }
}

// Base Chart Container to keep design consistent
class _ChartContainer extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Widget chart;
  final Widget? legend;

  const _ChartContainer({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.chart,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: chart,
          ),
          if (legend != null) ...[
            const SizedBox(height: 8),
            legend!,
          ],
        ],
      ),
    );
  }
}

class _DashboardLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _DashboardLegend(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ],
    );
  }
}

class _AnimatedTodaysSalesChart extends StatefulWidget {
  final double amount;
  final List<double> points;
  const _AnimatedTodaysSalesChart({required this.amount, required this.points});
  @override
  State<_AnimatedTodaysSalesChart> createState() => _AnimatedTodaysSalesChartState();
}
class _AnimatedTodaysSalesChartState extends State<_AnimatedTodaysSalesChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedTodaysSalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.points.reduce((a, b) => a > b ? a : b);
    final normY = maxVal == 0 ? 10.0 : maxVal * 1.2;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: "Today's Sales",
          value: "₹${(widget.amount * _anim.value).toStringAsFixed(2)}",
          icon: Icons.point_of_sale,
          color: Colors.blue,
          chart: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: (widget.points.length - 1).toDouble() == 0 ? 1 : (widget.points.length - 1).toDouble(), minY: 0, maxY: normY,
              lineBarsData: [
                LineChartBarData(
                  spots: widget.points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value * _anim.value)).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.blue.withValues(alpha: 0.3), Colors.transparent],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedMonthlySalesChart extends StatefulWidget {
  final double amount;
  final List<double> points;
  const _AnimatedMonthlySalesChart({required this.amount, required this.points});
  @override
  State<_AnimatedMonthlySalesChart> createState() => _AnimatedMonthlySalesChartState();
}
class _AnimatedMonthlySalesChartState extends State<_AnimatedMonthlySalesChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedMonthlySalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.points.reduce((a, b) => a > b ? a : b);
    final normY = maxVal == 0 ? 10.0 : maxVal * 1.2;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: "Monthly Sales",
          value: "₹${(widget.amount * _anim.value).toStringAsFixed(2)}",
          icon: Icons.calendar_month,
          color: Colors.green,
          chart: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              maxY: normY,
              barGroups: widget.points.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(toY: e.value * _anim.value, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4))]
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedPurchasesChart extends StatefulWidget {
  final double amount;
  final List<double> points;
  const _AnimatedPurchasesChart({required this.amount, required this.points});
  @override
  State<_AnimatedPurchasesChart> createState() => _AnimatedPurchasesChartState();
}
class _AnimatedPurchasesChartState extends State<_AnimatedPurchasesChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.fastOutSlowIn);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedPurchasesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.points.reduce((a, b) => a > b ? a : b);
    final normY = maxVal == 0 ? 10.0 : maxVal * 1.2;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: "Total Purchases (Stock)",
          value: "₹${(widget.amount * _anim.value).toStringAsFixed(2)}",
          icon: Icons.shopping_cart,
          color: Colors.orange,
          chart: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: (widget.points.length - 1).toDouble() == 0 ? 1 : (widget.points.length - 1).toDouble(), minY: 0, maxY: normY,
              lineBarsData: [
                LineChartBarData(
                  spots: widget.points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value * _anim.value)).toList(),
                  isCurved: false,
                  color: Colors.orange,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true, getDotPainter: (a,b,c,d) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: Colors.orange)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedTotalProductsChart extends StatefulWidget {
  final int count;
  final double cat1, cat2, cat3;
  const _AnimatedTotalProductsChart({required this.count, required this.cat1, required this.cat2, required this.cat3});
  @override
  State<_AnimatedTotalProductsChart> createState() => _AnimatedTotalProductsChartState();
}
class _AnimatedTotalProductsChartState extends State<_AnimatedTotalProductsChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedTotalProductsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    double sum = widget.cat1 + widget.cat2 + widget.cat3;
    if (sum == 0) sum = 1;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: "Total Products",
          value: (widget.count * _anim.value).toInt().toString(),
          icon: Icons.inventory,
          color: Colors.purple,
          chart: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 25,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(value: (widget.cat1 / sum) * 100 * _anim.value, color: Colors.purple, radius: 25, showTitle: false),
                PieChartSectionData(value: (widget.cat2 / sum) * 100 * _anim.value, color: Colors.purpleAccent, radius: 25, showTitle: false),
                PieChartSectionData(value: (widget.cat3 / sum) * 100 * _anim.value, color: Colors.deepPurple, radius: 25, showTitle: false),
                if (sum == 1) PieChartSectionData(value: 100 * _anim.value, color: Colors.grey.withValues(alpha: 0.3), radius: 25, showTitle: false),
              ],
            ),
          ),
          legend: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              _DashboardLegend(Colors.purple, 'Category 1'),
              _DashboardLegend(Colors.purpleAccent, 'Category 2'),
              _DashboardLegend(Colors.deepPurple, 'Other'),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedTotalCustomersChart extends StatefulWidget {
  final int count;
  const _AnimatedTotalCustomersChart({required this.count});
  @override
  State<_AnimatedTotalCustomersChart> createState() => _AnimatedTotalCustomersChartState();
}
class _AnimatedTotalCustomersChartState extends State<_AnimatedTotalCustomersChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedTotalCustomersChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: "Total Customers",
          value: (widget.count * _anim.value).toInt().toString(),
          icon: Icons.people,
          color: Colors.teal,
          chart: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: 4, minY: 0, maxY: 10,
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, 2 * _anim.value),
                    FlSpot(1, 3 * _anim.value),
                    FlSpot(2, 4.5 * _anim.value),
                    FlSpot(3, 5 * _anim.value),
                    FlSpot(4, 8 * _anim.value),
                  ],
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 0,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.teal.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedLowStockChart extends StatefulWidget {
  final int count;
  final List<double> points;
  const _AnimatedLowStockChart({required this.count, required this.points});
  @override
  State<_AnimatedLowStockChart> createState() => _AnimatedLowStockChartState();
}
class _AnimatedLowStockChartState extends State<_AnimatedLowStockChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedLowStockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.points.reduce((a, b) => a > b ? a : b);
    final normY = maxVal == 0 ? 10.0 : maxVal * 1.2;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: "Low Stock Items",
          value: (widget.count * _anim.value).toInt().toString(),
          icon: Icons.warning,
          color: Colors.red,
          chart: RotatedBox(
            quarterTurns: 1, // FlChart doesn't have native horizontal bar chart, so we rotate a vertical one
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                maxY: normY,
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: widget.points[0] * _anim.value, color: Colors.redAccent, width: 8)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: widget.points[1] * _anim.value, color: Colors.red, width: 8)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: widget.points[2] * _anim.value, color: Colors.red[900], width: 8)]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedProductDemoChart extends StatefulWidget {
  final String productName;
  final double sold;
  final double remaining;
  final Color color;
  const _AnimatedProductDemoChart({required this.productName, required this.sold, required this.remaining, required this.color});
  @override
  State<_AnimatedProductDemoChart> createState() => _AnimatedProductDemoChartState();
}
class _AnimatedProductDemoChartState extends State<_AnimatedProductDemoChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _AnimatedProductDemoChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productName != widget.productName) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    double sum = widget.sold + widget.remaining;
    if (sum == 0) sum = 1;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return _ChartContainer(
          title: widget.productName,
          value: "Sold vs Remaining",
          icon: Icons.pie_chart,
          color: widget.color,
          chart: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 25,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(value: (widget.sold / sum) * 100, color: Colors.green, radius: 25 * _anim.value, showTitle: false),
                PieChartSectionData(value: (widget.remaining / sum) * 100, color: Colors.orange, radius: 25 * _anim.value, showTitle: false),
                if (sum == 1) PieChartSectionData(value: 100, color: Colors.grey.withValues(alpha: 0.3), radius: 25 * _anim.value, showTitle: false),
              ],
            ),
          ),
          legend: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              _DashboardLegend(Colors.green, 'Sold'),
              _DashboardLegend(Colors.orange, 'Remaining'),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedLowStockBanner extends StatelessWidget {
  final List<Product> items;
  const _AnimatedLowStockBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "All products are adequately stocked.",
                      style: TextStyle(color: Colors.green.shade800, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              'Low Stock Alerts (${items.length})',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = items[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(30 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100, width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Remaining:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text(
                                  '${p.currentStock}',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
