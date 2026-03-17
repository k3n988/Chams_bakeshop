import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
import '../../viewmodel/baker_production_viewmodel.dart';
import '../../viewmodel/baker_salary_viewmodel.dart';
import '../../../helper/view/screens/profile.dart';
import 'baker_production_input_screen.dart';
import 'baker_history_screen.dart';
import 'baker_salary_screen.dart';

// ─────────────────────────────────────────────────────────
//  MASTER BAKER DASHBOARD
// ─────────────────────────────────────────────────────────
class MasterBakerDashboard extends StatefulWidget {
  const MasterBakerDashboard({super.key});
  @override
  State<MasterBakerDashboard> createState() => _MasterBakerDashboardState();
}

class _MasterBakerDashboardState extends State<MasterBakerDashboard>
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
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    context.read<BakerProductionViewModel>().loadData(user.id);
    final salaryVm = context.read<BakerSalaryViewModel>();
    salaryVm.loadDailyRecords(user.id);
    salaryVm.loadWeeklySalary(user.id);
  }

  void _logout() {
    context.read<AuthViewModel>().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToProduce() {
    setState(() => _index = 1);
    _fadeController
      ..reset()
      ..forward();
  }

  void _onTabChanged(int i) {
    setState(() => _index = i);
    _fadeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.masterBaker),
        ),
      );
    }

    final salaryVm = context.watch<BakerSalaryViewModel>();

    final pages = [
      _DashboardHome(vm: salaryVm, user: user, onGoToProduce: _goToProduce),
      const BakerProductionInputScreen(),
      const BakerHistoryScreen(),
      const BakerSalaryScreen(),
      ProfileScreen(
        userName: user.name,
        userRole: user.role,
        userId: user.id,
        accentColor: AppColors.masterBaker,
        grossSalary: salaryVm.grossSalary,
        netSalary: salaryVm.finalSalary,
        daysWorked: salaryVm.daysWorked,
        totalRecords: salaryVm.dailyRecords.length,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _index == 4
          ? null
          : _BakerAppBar(
              userName: user.name,
              onAddProduction: _goToProduce,
            ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: pages[_index],
      ),
      bottomNavigationBar: _BakerNavBar(
        selectedIndex: _index,
        onChanged: _onTabChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────
class _BakerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final VoidCallback onAddProduction;
  const _BakerAppBar(
      {required this.userName, required this.onAddProduction});

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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Text('👨‍🍳', style: TextStyle(fontSize: 18)),
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
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            const Text(
              'Master Baker',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ]),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────
class _BakerNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _BakerNavBar(
      {required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        selectedIndex: selectedIndex,
        onDestinationSelected: onChanged,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.masterBaker.withValues(alpha: 0.10),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon:
                Icon(Icons.dashboard, color: AppColors.masterBaker),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon:
                Icon(Icons.add_circle, color: AppColors.masterBaker),
            label: 'Produce',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon:
                Icon(Icons.history, color: AppColors.masterBaker),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon:
                Icon(Icons.payments, color: AppColors.masterBaker),
            label: 'Salary',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon:
                Icon(Icons.person, color: AppColors.masterBaker),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  DASHBOARD HOME TAB
// ─────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  final BakerSalaryViewModel vm;
  final dynamic user;
  final VoidCallback onGoToProduce;

  const _DashboardHome({
    required this.vm,
    required this.user,
    required this.onGoToProduce,
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
          _HeroBanner(
            userName: user.name,
            onAddProduction: onGoToProduce,
          ),
          SizedBox(height: isWide ? 24 : 20),
          const _SectionLabel('QUICK OVERVIEW'),
          const SizedBox(height: 12),
          isWide
              ? Row(
                  children: _statsCards
                      .map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: c,
                            ),
                          ))
                      .toList())
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
          const _SectionLabel("TODAY'S PRODUCTION"),
          const SizedBox(height: 10),
          _TodayProductionCard(vm: vm, onGoToProduce: onGoToProduce),
          SizedBox(height: isWide ? 24 : 20),
          const _SectionLabel('RECENT DAILY RECORDS'),
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
          color: AppColors.masterBaker,
          iconBg: AppColors.masterBaker.withValues(alpha: 0.10),
        ),
        _StatCard(
          icon: Icons.work_history_outlined,
          label: 'Days Worked',
          value: '${vm.daysWorked}',
          color: const Color(0xFF5D4037),
          iconBg: const Color(0xFF5D4037).withValues(alpha: 0.10),
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Weekly Gross',
          value: formatCurrency(vm.grossSalary),
          color: const Color(0xFF1976D2),
          iconBg: const Color(0xFF1976D2).withValues(alpha: 0.10),
        ),
        _StatCard(
          icon: Icons.price_check,
          label: 'Take-Home Pay',
          value: formatCurrency(vm.finalSalary),
          color: const Color(0xFF388E3C),
          iconBg: const Color(0xFF388E3C).withValues(alpha: 0.10),
        ),
      ];
}

// ─────────────────────────────────────────────────────────
//  TODAY PRODUCTION CARD
// ─────────────────────────────────────────────────────────
class _TodayProductionCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  final VoidCallback onGoToProduce;
  const _TodayProductionCard(
      {required this.vm, required this.onGoToProduce});

  @override
  Widget build(BuildContext context) {
    final todayDate = DateTime.now().toString().split(' ')[0];
    final todayRecords =
        vm.dailyRecords.where((r) => r.date == todayDate).toList();

    if (todayRecords.isEmpty) {
      return GestureDetector(
        onTap: onGoToProduce,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.masterBaker.withValues(alpha: 0.20),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.masterBaker.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_circle_outline,
                  color: AppColors.masterBaker, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No production yet today',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text)),
                  SizedBox(height: 2),
                  Text('Tap to start your first batch',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.masterBaker.withValues(alpha: 0.5)),
          ]),
        ),
      );
    }

  int totalSacks = 0;
    double totalEarnings = 0;
    for (final r in todayRecords) {
      totalSacks += r.totalSacks;
      totalEarnings += r.salary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TodayStat(
              label: 'Batches',
              value: '${todayRecords.length}',
              icon: Icons.bakery_dining,
              color: AppColors.masterBaker,
            ),
            Container(
                width: 1, height: 40, color: AppColors.border),
            _TodayStat(
              label: 'Sacks',
              value: '$totalSacks',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF1976D2),
            ),
            Container(
                width: 1, height: 40, color: AppColors.border),
            _TodayStat(
              label: 'Earnings',
              value: formatCurrency(totalEarnings),
              icon: Icons.payments_outlined,
              color: const Color(0xFF388E3C),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onGoToProduce,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Another Batch',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.masterBaker,
              side: BorderSide(
                  color: AppColors.masterBaker.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _TodayStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textHint)),
      ]);
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
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(children: [
          Icon(Icons.inbox_outlined,
              size: 40, color: AppColors.textHint),
          SizedBox(height: 10),
          Text('No records yet',
              style:
                  TextStyle(color: AppColors.textHint, fontSize: 14)),
          SizedBox(height: 4),
          Text('Add a production batch to get started',
              style: TextStyle(
                  color: AppColors.textHint, fontSize: 12)),
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
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.masterBaker.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.masterBaker, size: 20),
              ),
              title: Text(rec.date,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.text)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${rec.totalWorkers} workers · ${rec.totalSacks} sacks',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ),
              trailing: Text(
                formatCurrency(rec.salary),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primaryDark),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  HERO BANNER
// ─────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onAddProduction;
  const _HeroBanner(
      {required this.userName, required this.onAddProduction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // 🔥 Colorful Gradient Palette matched to Helper
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7A00), // Deep vibrant orange
            Color(0xFFFFA03A), // Lighter, bright orange
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
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
            "Here's your production overview",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddProduction,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add Production Batch',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF7A00), // Matched to orange
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.masterBaker,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 0.9)),
      ]);
}