import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';
import 'admin_home_screen.dart';
import 'admin_drawer.dart';
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

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserViewModel>().loadUsers();
      context.read<AdminProductViewModel>().loadProducts();
      context.read<AdminProductionViewModel>().loadAllProductions();
    });
  }

  void _navigateFromHome(int i) {
    // Called from AdminHomeScreen quick actions
    // 1 → Users (push), 2 → Products (push),
    // 3 → Reports (bottom nav index 1),
    // 4 → Payroll (bottom nav index 2),
    // 5 → Bonus  (bottom nav index 3)
    if (i == 1) {
      _pushPage(const ManageUsersScreen(), 'User Management');
    } else if (i == 2) {
      _pushPage(const ManageProductsScreen(), 'Products');
    } else if (i == 3) {
      setState(() => _index = 1);
    } else if (i == 4) {
      setState(() => _index = 2);
    } else if (i == 5) {
      setState(() => _index = 3);
    }
  }

  void _pushPage(Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF8F4F0),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppColors.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  height: 1,
                  color: Colors.black.withValues(alpha: 0.04)),
            ),
          ),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
                color: AppColors.primary)),
      );
    }

    context.watch<AdminPayrollViewModel>();

    final pages = [
      AdminHomeScreen(onNavigate: _navigateFromHome),
      const ProductionReportsScreen(),
      const AdminPayrollScreen(),
      const ChristmasBonusScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,

      // ── Drawer ─────────────────────────────────────────────
      drawer: const AdminDrawer(),

      // ── AppBar ─────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu,
                color: AppColors.primary, size: 20),
          ),
          onPressed: () =>
              _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
            // ✅ REPLACED THE EMOJI WITH YOUR LOGO ASSET HERE ✅
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover, // Adjust to BoxFit.contain if your logo is transparent and shouldn't fill the box completely
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CHAMPS BAKESHOP',
                  style: TextStyle(
                      fontSize: 13,
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
        // ── No admin pill in AppBar anymore ────────────────
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),

      // ── Body ───────────────────────────────────────────────
      body: pages[_index],

      // ── Bottom nav (4 items) ───────────────────────────────
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