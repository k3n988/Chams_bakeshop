import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';

import 'baker_production_input_screen.dart';
import 'baker_history_screen.dart';
import 'baker_salary_screen.dart';
import 'master_baker_dashboard.dart';

class BakerHomeScreen extends StatefulWidget {
  const BakerHomeScreen({super.key});

  @override
  State<BakerHomeScreen> createState() => _BakerHomeScreenState();
}

class _BakerHomeScreenState extends State<BakerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MasterBakerDashboard(),
    BakerProductionInputScreen(),
    BakerHistoryScreen(),
    BakerSalaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bakery_dining,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hi, ${user?.name.toUpperCase() ?? 'BAKER'}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const Text('Master Baker',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () => setState(() => _currentIndex = 1),
            tooltip: 'Add Production',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon:
                Icon(Icons.add_circle, color: AppColors.primary),
            label: 'Production',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments, color: AppColors.primary),
            label: 'Salary',
          ),
        ],
      ),
    );
  }
}