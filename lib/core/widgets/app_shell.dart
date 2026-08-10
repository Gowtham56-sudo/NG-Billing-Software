import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/cashier/providers/voice_billing_provider.dart';
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the current index based on the route
    final String location = GoRouterState.of(context).uri.path;
    int selectedIndex = 0;
    if (location.startsWith('/dashboard')) {
      selectedIndex = 0;
    } else if (location.startsWith('/cashier')) {
      selectedIndex = 1;
    } else if (location.startsWith('/products')) {
      selectedIndex = 2;
    } else if (location.startsWith('/customers')) {
      selectedIndex = 3;
    } else if (location.startsWith('/sales-history')) {
      selectedIndex = 4;
    }

    ref.listen<VoiceBillingState>(voiceBillingProvider, (previous, next) {
      // If a transcript is received or a success message is shown, navigate to cashier panel
      if ((next.lastTranscript != null && next.lastTranscript != previous?.lastTranscript) ||
          (next.successMessage != null && next.successMessage != previous?.successMessage)) {
        if (!location.startsWith('/cashier')) {
          context.go('/cashier');
        }
      }
    });

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width >= 800,
            minExtendedWidth: 200,
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/cashier');
                  break;
                case 2:
                  context.go('/products');
                  break;
                case 3:
                  context.go('/customers');
                  break;
                case 4:
                  context.go('/sales-history');
                  break;
              }
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Icon(
                Icons.storefront,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final voiceState = ref.watch(voiceBillingProvider);
                          return IconButton(
                            icon: voiceState.isProcessing 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(
                                    voiceState.isRecording ? Icons.mic : Icons.mic_none,
                                    color: voiceState.isRecording ? Colors.redAccent : null,
                                  ),
                            tooltip: voiceState.isRecording ? 'Stop Listening' : 'Start Voice Assistant',
                            onPressed: () {
                              ref.read(voiceBillingProvider.notifier).toggleRecording();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('Sales (POS)'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory),
                label: Text('Items'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Parties'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Sales History'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
