import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';
import 'helper_daily_screen.dart';
import 'helper_weekly_screen.dart';
import 'helper_monthly_screen.dart';
import 'helper_production_batch.dart';
import 'profile.dart';

// ─────────────────────────────────────────────────────────
//  HELPER DASHBOARD
// ─────────────────────────────────────────────────────────
class HelperDashboard extends StatefulWidget {
  const HelperDashboard({super.key});

  @override
  State<HelperDashboard> createState() => _HelperDashboardState();
}

class _HelperDashboardState extends State<HelperDashboard>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (!mounted) return;
    final userId = context.read<AuthViewModel>().currentUser!.id;
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadDailyRecords(userId);
    vm.loadWeeklySalary(userId);
    vm.loadMonthlySummary(userId);
  }

  void _logout() {
    context.read<AuthViewModel>().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openAddProduction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProductionSheet(),
    ).then((_) => _refreshData());
  }

  void _onTabChanged(int i) {
    setState(() => _index = i);
    _fadeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;
    final vm = context.watch<HelperSalaryViewModel>();

    final pages = [
      _DashboardHome(vm: vm, user: user, onAddProduction: _openAddProduction),
      const HelperDailyScreen(),
      const HelperWeeklyScreen(),
      const HelperMonthlyScreen(),
      ProfileScreen(
        userName: user.name,
        userRole: user.role,
        userId: user.id,
        accentColor: DashColors.primary,
        grossSalary: vm.grossSalary,
        netSalary: vm.finalSalary,
        daysWorked: vm.daysWorked,
        totalRecords: vm.dailyRecords.length,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: DashColors.background,
      appBar: _index == 4
          ? null
          : _DashboardAppBar(userName: user.name),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: pages[_index],
      ),
      bottomNavigationBar: _DashNavBar(
        selectedIndex: _index,
        onChanged: _onTabChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  const _DashboardAppBar({required this.userName});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [DashColors.primary, DashColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: DashColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: const Center(
            child: Text('👷', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi, $userName 👋',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DashColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 11,
                color: DashColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: DashColors.border),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────
class _DashNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DashNavBar({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onChanged,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: DashColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _navDestinations,
      ),
    );
  }

  static const _navDestinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard, color: DashColors.primary),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today, color: DashColors.primary),
      label: 'Daily',
    ),
    NavigationDestination(
      icon: Icon(Icons.date_range_outlined),
      selectedIcon: Icon(Icons.date_range, color: DashColors.primary),
      label: 'Weekly',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month, color: DashColors.primary),
      label: 'Monthly',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person, color: DashColors.primary),
      label: 'Profile',
    ),
  ];
}

// ─────────────────────────────────────────────────────────
//  DASHBOARD HOME TAB
// ─────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  final HelperSalaryViewModel vm;
  final dynamic user;
  final VoidCallback onAddProduction;

  const _DashboardHome({
    required this.vm,
    required this.user,
    required this.onAddProduction,
  });

  String get _todayEarnings {
    if (vm.dailyRecords.isNotEmpty) {
      final todayDate = DateTime.now().toString().split(' ')[0];
      if (vm.dailyRecords.first.date == todayDate) {
        return formatCurrency(vm.dailyRecords.first.salary);
      }
    }
    return '₱0.00';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner ──
          _HeroBanner(userName: user.name, onAddProduction: onAddProduction),
          SizedBox(height: isWide ? 24 : 20),

          // ── Section Label ──
          _SectionLabel('QUICK OVERVIEW'),
          const SizedBox(height: 12),

          // ── Stats Grid ──
          isWide
              ? Row(children: _statsCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList())
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: _statsCards,
                ),

          SizedBox(height: isWide ? 24 : 20),

          // ── Recent Records ──
          _SectionLabel('RECENT DAILY RECORDS'),
          const SizedBox(height: 10),
          _RecentRecords(records: vm.dailyRecords),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> get _statsCards => [
        _StatCard(
          icon: Icons.payments_outlined,
          label: "Today's Earnings",
          value: _todayEarnings,
          color: DashColors.primary,
          iconBg: DashColors.primary.withValues(alpha: 0.1),
        ),
        _StatCard(
          icon: Icons.work_history_outlined,
          label: 'Days Worked',
          value: '${vm.daysWorked}',
          color: const Color(0xFF5D4037),
          iconBg: const Color(0xFF5D4037).withValues(alpha: 0.1),
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Weekly Gross',
          value: formatCurrency(vm.grossSalary),
          color: const Color(0xFF1976D2),
          iconBg: const Color(0xFF1976D2).withValues(alpha: 0.1),
        ),
        _StatCard(
          icon: Icons.price_check,
          label: 'Take-Home Pay',
          value: formatCurrency(vm.finalSalary),
          color: const Color(0xFF388E3C),
          iconBg: const Color(0xFF388E3C).withValues(alpha: 0.1),
        ),
      ];
}

// ─────────────────────────────────────────────────────────
//  HERO BANNER
// ─────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onAddProduction;

  const _HeroBanner({required this.userName, required this.onAddProduction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFB86A1E), DashColors.primary, DashColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: DashColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative dots
          Row(children: [
            _Dot(opacity: 0.3, size: 8),
            const SizedBox(width: 6),
            _Dot(opacity: 0.2, size: 6),
            const SizedBox(width: 6),
            _Dot(opacity: 0.15, size: 4),
          ]),
          const SizedBox(height: 10),
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's your earnings overview",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddProduction,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Add Production Batch',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: DashColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double opacity;
  final double size;
  const _Dot({required this.opacity, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: DashColors.textHint,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  RECENT RECORDS LIST
// ─────────────────────────────────────────────────────────
class _RecentRecords extends StatelessWidget {
  final List<dynamic> records;

  const _RecentRecords({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashColors.border),
        ),
        child: const Column(children: [
          Icon(Icons.inbox_outlined, size: 40, color: DashColors.textHint),
          SizedBox(height: 10),
          Text(
            'No records yet',
            style: TextStyle(color: DashColors.textHint, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Add a production batch to get started',
            style: TextStyle(color: DashColors.textHint, fontSize: 12),
          ),
        ]),
      );
    }

    return Column(
      children: records.take(5).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final rec = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 60),
          curve: Curves.easeOut,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - v)),
              child: child,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DashColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: DashColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                rec.date,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: DashColors.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${rec.totalWorkers} workers · ${rec.totalSacks} sacks',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashColors.textHint,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(rec.salary),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: DashColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Paid',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF388E3C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SECTION LABEL WIDGET
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: DashColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: DashColors.textHint,
          letterSpacing: 0.9,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────
class DashColors {
  static const primary = Color(0xFFD48135);
  static const primaryLight = Color(0xFFE5A663);
  static const primaryDark = Color(0xFFB86A1E);
  static const background = Color(0xFFF7F7F8);
  static const border = Color(0xFFEEEEEE);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF9E9E9E);
}