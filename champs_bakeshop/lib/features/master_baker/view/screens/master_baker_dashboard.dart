import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    salaryVm.loadYearlySalary(user.id);
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
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
        grossSalary: salaryVm.yearlyGross,
        netSalary: salaryVm.yearlyNet,
        daysWorked: salaryVm.yearlyDays,
        totalRecords: salaryVm.yearlyRecords,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _index == 4
          ? null
          : _BakerAppBar(
              userName: user.name,
              userId: user.id,
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
class _BakerAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String userName;
  final String userId;
  final VoidCallback onAddProduction;
  const _BakerAppBar({
    required this.userName,
    required this.userId,
    required this.onAddProduction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  State<_BakerAppBar> createState() => _BakerAppBarState();
}

class _BakerAppBarState extends State<_BakerAppBar> {
  String? _photoPath;
  late String _displayName;

  static const _photoKey = 'profile_photo_path';
  static const _nameKey  = 'profile_display_name';

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final photo = prefs.getString('${_photoKey}_${widget.userId}');
    final name  = prefs.getString('${_nameKey}_${widget.userId}');
    if (!mounted) return;
    setState(() {
      _photoPath   = photo;
      if (name != null && name.isNotEmpty) _displayName = name;
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(children: [
        // Profile avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.masterBaker.withValues(alpha: 0.85),
            border: Border.all(
              color: AppColors.masterBaker.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.masterBaker.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            image: _photoPath != null
                ? DecorationImage(
                    image: FileImage(File(_photoPath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _photoPath == null
              ? Center(
                  child: Text(
                    _initials(_displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi, $_displayName 👋',
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
            selectedIcon: Icon(Icons.dashboard, color: AppColors.masterBaker),
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
            selectedIcon: Icon(Icons.history, color: AppColors.masterBaker),
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
            selectedIcon: Icon(Icons.person, color: AppColors.masterBaker),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
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
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textHint)),
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
      totalSacks += r.totalSacks ;
      totalEarnings += r.salary ;
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
            Container(width: 1, height: 40, color: AppColors.border),
            _TodayStat(
              label: 'Sacks',
              value: '$totalSacks',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF1976D2),
            ),
            Container(width: 1, height: 40, color: AppColors.border),
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
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                fontWeight: FontWeight.w800, fontSize: 14, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ]);
}

// ─────────────────────────────────────────────────────────
//  RECENT RECORDS LIST  (with tappable preview)
// ─────────────────────────────────────────────────────────
class _RecentRecords extends StatelessWidget {
  final List<BakerDashboardRecord> records;
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
          Icon(Icons.inbox_outlined, size: 40, color: AppColors.textHint),
          SizedBox(height: 10),
          Text('No records yet',
              style: TextStyle(color: AppColors.textHint, fontSize: 14)),
          SizedBox(height: 4),
          Text('Add a production batch to get started',
              style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        ]),
      );
    }

    return Column(
      children: records.take(5).toList().asMap().entries.map((entry) {
        final i   = entry.key;
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
          child: GestureDetector(
            onTap: () => _showPreviewSheet(context, rec),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatCurrency(rec.salary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showPreviewSheet(BuildContext context, BakerDashboardRecord rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.masterBaker, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.date,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.3)),
                      const Text('Production Detail',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.masterBaker.withValues(alpha: 0.2)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('👨‍🍳', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('Master Baker',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.masterBaker)),
                  ]),
                ),
              ]),
            ),

            const Divider(height: 20, color: AppColors.border),

            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [

                  // Production Summary
                  _PreviewCard(children: [
                    const _PreviewCardLabel('PRODUCTION SUMMARY'),
                    const SizedBox(height: 12),
                    _PreviewDataRow(
                      icon: Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${rec.totalWorkers}',
                    ),
                    _PreviewDataRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Total Sacks',
                      value: '${rec.totalSacks} sacks',
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Salary Breakdown
                  _PreviewCard(children: [
                    const _PreviewCardLabel('SALARY BREAKDOWN'),
                    const SizedBox(height: 12),
                    _PreviewDataRow(
                      icon: Icons.payments_outlined,
                      label: 'Total Earnings',
                      value: formatCurrency(rec.salary),
                      valueColor: AppColors.masterBaker,
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Earnings',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.text)),
                        Text(
                          formatCurrency(rec.salary),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Bonus
                  _PreviewCard(children: [
                    const _PreviewCardLabel('BONUS (PAID SEPARATELY)'),
                    const SizedBox(height: 12),
                    _PreviewDataRow(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Master Baker Bonus',
                      value: formatCurrency(rec.bonus),
                      valueColor: AppColors.masterBaker,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bonus is paid separately and is not included in the weekly payroll total.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.amber.shade800),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────
//  PREVIEW SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final List<Widget> children;
  const _PreviewCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _PreviewCardLabel extends StatelessWidget {
  final String text;
  const _PreviewCardLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
              color: AppColors.masterBaker,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

class _PreviewDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _PreviewDataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textHint)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  PROFILE HEADER CARD
// ─────────────────────────────────────────────────────────
class _ProfileHeaderCard extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userId;

  const _ProfileHeaderCard({
    required this.userName,
    required this.userRole,
    required this.userId,
  });

  @override
  State<_ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<_ProfileHeaderCard>
    with SingleTickerProviderStateMixin {
  String? _photoPath;
  late String _displayName;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  static const _photoKey = 'profile_photo_path';
  static const _nameKey  = 'profile_display_name';

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();
    _loadPrefs();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final photo = prefs.getString('${_photoKey}_${widget.userId}');
    final name  = prefs.getString('${_nameKey}_${widget.userId}');
    if (!mounted) return;
    setState(() {
      _photoPath   = photo;
      if (name != null && name.isNotEmpty) _displayName = name;
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.masterBaker.withValues(alpha: 0.85),
                border: Border.all(
                  color: AppColors.masterBaker.withValues(alpha: 0.20),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.masterBaker.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: _photoPath != null
                    ? DecorationImage(
                        image: FileImage(File(_photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _photoPath == null
                  ? Center(
                      child: Text(
                        _initials(_displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.masterBaker.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👨‍🍳', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        widget.userRole,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.masterBaker,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF388E3C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7A00),
            Color(0xFFFFA03A),
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
                foregroundColor: const Color(0xFFFF7A00),
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