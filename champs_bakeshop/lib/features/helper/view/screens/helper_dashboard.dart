import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/database_service.dart';
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
    final vm     = context.read<HelperSalaryViewModel>();
    vm.loadDailyRecords(userId);
    vm.loadWeeklySalary(userId);
    vm.loadMonthlySummary(userId);
    vm.loadPaidWeeks(userId);
    vm.loadYearlySalary(userId);
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openAddProduction() {
    final db          = context.read<DatabaseService>();
    final currentUser = context.read<AuthViewModel>().currentUser!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductionSheet(
        db:            db,
        currentUserId: currentUser.id,
      ),
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
    final vm   = context.watch<HelperSalaryViewModel>();

    final pages = [
      _DashboardHome(vm: vm, user: user, onAddProduction: _openAddProduction),
      const HelperDailyScreen(),
      const HelperWeeklyScreen(),
      const HelperMonthlyScreen(),
      ProfileScreen(
        userName:     user.name,
        userRole:     user.role,
        userId:       user.id,
        accentColor:  DashColors.primary,
        grossSalary:  vm.yearlyGross,
        netSalary:    vm.yearlyNet,
        daysWorked:   vm.yearlyDays,
        totalRecords: vm.yearlyRecords,
        onLogout:     _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _index == 4
          ? null
          : _DashboardAppBar(userName: user.name),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: pages[_index],
      ),
      bottomNavigationBar: _DashNavBar(
        selectedIndex: _index,
        onChanged:     _onTabChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
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
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
            border: Border.all(color: DashColors.border),
          ),
          child: const Center(
              child: Text('👷', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hi, $userName 👋',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashColors.textPrimary,
                    letterSpacing: -0.3)),
            const Text('Welcome back!',
                style: TextStyle(
                    fontSize: 11,
                    color: DashColors.textHint,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ]),
      
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────
class _DashNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _DashNavBar(
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
        indicatorColor: DashColors.primary.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
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
        ],
      ),
    );
  }
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
          _HeroBanner(
              userName: user.name, onAddProduction: onAddProduction),
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
          const _SectionLabel('RECENT DAILY RECORDS'),
          const SizedBox(height: 10),
          // ✅ Pass paid weeks to records
          _RecentRecords(
              records: vm.dailyRecords,
              paidWeekStarts: vm.paidWeekStarts),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> get _statsCards => [
        _StatCard(
          icon:  Icons.payments_outlined,
          label: "Today's Earnings",
          value: _todayEarnings,
          color: DashColors.primary,
          iconBg: DashColors.primary.withValues(alpha: 0.1),
        ),
        _StatCard(
          icon:  Icons.work_history_outlined,
          label: 'Days Worked',
          value: '${vm.daysWorked}',
          color: const Color(0xFF5D4037),
          iconBg: const Color(0xFF5D4037).withValues(alpha: 0.1),
        ),
        _StatCard(
          icon:  Icons.account_balance_wallet_outlined,
          label: 'Weekly Gross',
          value: formatCurrency(vm.grossSalary),
          color: const Color(0xFF1976D2),
          iconBg: const Color(0xFF1976D2).withValues(alpha: 0.1),
        ),
        _StatCard(
          icon:  Icons.price_check,
          label: 'Take-Home Pay',
          value: formatCurrency(vm.finalSalary),
          color: const Color(0xFF388E3C),
          iconBg: const Color(0xFF388E3C).withValues(alpha: 0.1),
        ),
      ];
}

// ─────────────────────────────────────────────────────────
//  RECENT RECORDS LIST
// ─────────────────────────────────────────────────────────
class _RecentRecords extends StatelessWidget {
  final List<dynamic>  records;
  final Set<String>    paidWeekStarts;

  const _RecentRecords({
    required this.records,
    required this.paidWeekStarts,
  });

  // ── Determine week start for a given date ────────────
  String _weekStartOf(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return monday.toString().split(' ')[0];
  }

  bool _isPaid(String date) =>
      paidWeekStarts.contains(_weekStartOf(date));

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
          Icon(Icons.inbox_outlined,
              size: 40, color: DashColors.textHint),
          SizedBox(height: 10),
          Text('No records yet',
              style: TextStyle(
                  color: DashColors.textHint, fontSize: 14)),
          SizedBox(height: 4),
          Text('Add a production batch to get started',
              style: TextStyle(
                  color: DashColors.textHint, fontSize: 12)),
        ]),
      );
    }

    return Column(
      children: records.take(5).toList().asMap().entries.map((entry) {
        final i   = entry.key;
        final rec = entry.value;
        final paid = _isPaid(rec.date);

        return TweenAnimationBuilder<double>(
          tween:    Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 60),
          curve:    Curves.easeOut,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - v)),
              child: child,
            ),
          ),
          child: GestureDetector(
            // ✅ Tap to show production preview
            onTap: () => _showPreviewSheet(context, rec, paid),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: paid
                      ? const Color(0xFF388E3C).withValues(alpha: 0.15)
                      : DashColors.border,
                  width: 1,
                ),
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
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: DashColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: DashColors.primary, size: 20),
                ),
                title: Text(rec.date,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: DashColors.textPrimary)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${rec.totalWorkers} workers · ${rec.totalSacks} sacks',
                    style: const TextStyle(
                        fontSize: 12, color: DashColors.textHint),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCurrency(rec.salary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: DashColors.primaryDark)),
                    const SizedBox(height: 3),
                    // ✅ Paid / Unpaid badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: paid
                            ? const Color(0xFF388E3C)
                                .withValues(alpha: 0.08)
                            : Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: paid
                              ? const Color(0xFF388E3C)
                                  .withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(
                          paid
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 10,
                          color: paid
                              ? const Color(0xFF388E3C)
                              : Colors.orange,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          paid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                              fontSize: 10,
                              color: paid
                                  ? const Color(0xFF388E3C)
                                  : Colors.orange,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Production Preview Bottom Sheet ─────────────────────
  void _showPreviewSheet(
      BuildContext context, dynamic rec, bool paid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize:     0.4,
        maxChildSize:     0.85,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, // Changed to pure white
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
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
                    color:
                        DashColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: DashColors.primary, size: 22),
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
                            color: DashColors.textPrimary,
                            letterSpacing: -0.3)),
                    const Text('Production Detail',
                        style: TextStyle(
                            fontSize: 12,
                            color: DashColors.textHint)),
                  ]),
                ),
                // ✅ Paid/Unpaid badge in header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: paid
                        ? const Color(0xFF388E3C)
                            .withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: paid
                          ? const Color(0xFF388E3C)
                              .withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      paid ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color: paid
                          ? const Color(0xFF388E3C)
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: paid
                              ? const Color(0xFF388E3C)
                              : Colors.orange),
                    ),
                  ]),
                ),
              ]),
            ),

            const Divider(height: 20, color: DashColors.border),

            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Summary card ───────────────────────
                  _PreviewCard(children: [
                    const _PreviewLabel('PRODUCTION SUMMARY'),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.groups_outlined,
                      label: 'Total Workers',
                      value: '${rec.totalWorkers}',
                    ),
                    _PreviewRow(
                      icon:  Icons.inventory_2_outlined,
                      label: 'Total Sacks',
                      value: '${rec.totalSacks} sacks',
                    ),
                    _PreviewRow(
                      icon:  Icons.attach_money,
                      label: 'Batch Value',
                      value: formatCurrency(rec.totalValue),
                      valueColor: DashColors.primary,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Salary card ────────────────────────
                  _PreviewCard(children: [
                    const _PreviewLabel('YOUR SALARY'),
                    const SizedBox(height: 12),
                    _PreviewRow(
                      icon:  Icons.calculate_outlined,
                      label: 'Per Worker (base)',
                      value: formatCurrency(rec.salary),
                      valueColor: DashColors.primary,
                    ),
                    const Divider(height: 20, color: DashColors.border),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                      const Text('Your Earnings',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: DashColors.textPrimary)),
                      Text(
                        formatCurrency(rec.salary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: DashColors.primaryDark),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 12),

                  // ── Payment status card ────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: paid
                          ? const Color(0xFF388E3C)
                              .withValues(alpha: 0.04)
                          : Colors.orange.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: paid
                            ? const Color(0xFF388E3C)
                                .withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: paid
                              ? const Color(0xFF388E3C)
                                  .withValues(alpha: 0.1)
                              : Colors.orange
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          paid
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          color: paid
                              ? const Color(0xFF388E3C)
                              : Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(
                            paid
                                ? 'Salary Paid'
                                : 'Pending Payment',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: paid
                                    ? const Color(0xFF388E3C)
                                    : Colors.orange),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            paid
                                ? 'Your salary for this week has been released by admin.'
                                : 'Your salary for this week is pending admin approval.',
                            style: TextStyle(
                                fontSize: 11,
                                color: paid
                                    ? const Color(0xFF388E3C)
                                        .withValues(alpha: 0.8)
                                    : Colors.orange
                                        .withValues(alpha: 0.8)),
                          ),
                        ]),
                      ),
                    ]),
                  ),
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
          border: Border.all(color: DashColors.border),
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

class _PreviewLabel extends StatelessWidget {
  final String text;
  const _PreviewLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: DashColors.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: DashColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: DashColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: DashColors.textHint)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? DashColors.textPrimary)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  HERO BANNER (COLORFUL PALETTE)
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
        // 🔥 Colorful Gradient Palette 
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
            color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back,',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), // White text for contrast
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(userName,
              style: const TextStyle(
                  color: Colors.white, // White text for contrast
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text("Here's your earnings overview",
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), 
                  fontSize: 13)),
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
                backgroundColor: Colors.white, // White button to pop against the gradient
                foregroundColor: const Color(0xFFFF7A00), // Orange text to match banner
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
  final String   label;
  final String   value;
  final Color    color;
  final Color    iconBg;

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
        border: Border.all(color: DashColors.border), // Standard faint border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), // Faint shadow instead of colored
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
            child: Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: DashColors.textHint,
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
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: DashColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: DashColors.textHint,
                letterSpacing: 0.9)),
      ]);
}

// ─────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────
class DashColors {
  static const primary       = Color(0xFFFF7A00);
  static const primaryLight  = Color(0xFFFFA03A);
  static const primaryDark   = Color(0xFFE06500);
  static const background = Color(0xFFFFFFFF); // Changed to Pure White
  static const border        = Color(0xFFEEEEEE);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint      = Color(0xFF9E9E9E);
}