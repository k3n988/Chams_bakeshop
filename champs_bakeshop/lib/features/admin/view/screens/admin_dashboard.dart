import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';
import 'admin_home_screen.dart';
import 'manage_users_screen.dart';
import 'manage_products_screen.dart';
import 'production_reports_screen.dart';
import 'payroll_screen.dart';
import 'christmas_bonus_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserViewModel>().loadUsers();
      context.read<AdminProductViewModel>().loadProducts();
      context.read<AdminProductionViewModel>().loadAllProductions();
    });
  }

  void _logout() {
    context.read<AuthViewModel>().logout();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
            child:
                CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    context.watch<AdminPayrollViewModel>();

    final pages = [
      AdminHomeScreen(
          onNavigate: (i) => setState(() => _index = i)),
      const ManageUsersScreen(),
      const ManageProductsScreen(),
      const ProductionReportsScreen(),
      const AdminPayrollScreen(),
      const ChristmasBonusScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(children: [
          // ✅ Logo badge
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
                child: Text('🧁',
                    style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CHAMPS BAKESHOP',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3)),
              Text('Admin Panel',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ]),
        actions: [
          // ✅ Admin name pill
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ]),
          ),
          // ✅ Logout button
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout,
                    color: AppColors.danger, size: 16),
              ),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) =>
              setState(() => _index = i),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor:
              AppColors.primary.withValues(alpha: 0.1),
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard,
                    color: AppColors.primary),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon:
                    Icon(Icons.people, color: AppColors.primary),
                label: 'Users'),
            NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2,
                    color: AppColors.primary),
                label: 'Products'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart,
                    color: AppColors.primary),
                label: 'Reports'),
            NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments,
                    color: AppColors.primary),
                label: 'Payroll'),
            NavigationDestination(
                icon: Icon(Icons.card_giftcard_outlined),
                selectedIcon: Icon(Icons.card_giftcard,
                    color: Color(0xFFC62828)),
                label: 'Bonus'),
          ],
        ),
      ),
    );
  }
}