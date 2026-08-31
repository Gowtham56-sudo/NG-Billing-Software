import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'database/sqlite_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_dashboard.dart';
import 'features/cashier/screens/cashier_panel.dart';
import 'features/products/screens/products_screen.dart';
import 'features/customers/screens/customers_screen.dart';
import 'features/sales/screens/sales_history_screen.dart';
import 'core/widgets/app_shell.dart';
import 'core/services/voice_backend_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database
  await SqliteService.initDB();

  // Automatically start Voice AI Backend in background (no manual python startup required!)
  await VoiceBackendService.ensureVoiceBackendRunning();

  runApp(
    const ProviderScope(
      child: NextGenBillingApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/cashier',
          builder: (context, state) => const CashierPanel(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/sales-history',
          builder: (context, state) => const SalesHistoryScreen(),
        ),
      ],
    ),
  ],
);

class NextGenBillingApp extends ConsumerWidget {
  const NextGenBillingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'NextGen Billing Software',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Enforce light theme for white and blue
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
