import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_production_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';
import 'packer_production_input.dart';
import 'packer_daily_screen.dart';
import 'packer_weekly_screen.dart';
import 'packer_monthly_screen.dart';
import 'packer_profile.dart';

class PackerDashboard extends StatefulWidget {
  const PackerDashboard({super.key});

  @override
  State<PackerDashboard> createState() => _PackerDashboardState();
}

class _PackerDashboardState extends State<PackerDashboard> {
  int _currentIndex = 0;

  static const _navItems = [
    BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home'),
    BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Daily'),
    BottomNavigationBarItem(
        icon: Icon(Icons.calendar_view_week_outlined),
        activeIcon: Icon(Icons.calendar_view_week),
        label: 'Weekly'),
    BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: 'Monthly'),
    BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().currentUser!.id;
      context.read<PackerProductionViewModel>().init(uid);
      context.read<PackerSalaryViewModel>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;

    final pages = [
      _PackerHomePage(user: user),
      const PackerDailyScreen(),
      const PackerWeeklyScreen(),
      const PackerMonthlyScreen(),
      const PackerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.packer, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Packer',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text)),
              Text(user.name,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.packer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.packer.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📦', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text('Packer',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.packer)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.packer,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        backgroundColor: Colors.white,
        elevation: 12,
        items: _navItems,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HOME PAGE
// ══════════════════════════════════════════════════════════════
class _PackerHomePage extends StatelessWidget {
  final dynamic user;
  const _PackerHomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PackerProductionViewModel>();

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: () => vm.init(user.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────────
            _GreetingBanner(name: user.name),
            const SizedBox(height: 20),

            // ── Today summary ─────────────────────────────────
            _TodaySummaryCard(vm: vm),
            const SizedBox(height: 16),

            // ── Quick action ──────────────────────────────────
            _AddProductionButton(userId: user.id),
            const SizedBox(height: 20),

            // ── Today productions ─────────────────────────────
            if (vm.todayProductions.isNotEmpty) ...[
              const _SectionLabel('TODAY\'S PRODUCTIONS'),
              const SizedBox(height: 10),
              ...vm.todayProductions.asMap().entries.map(
                    (e) => _ProductionEntryCard(
                      prod:  e.value,
                      index: e.key,
                      packerId: user.id,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Greeting banner ───────────────────────────────────────────
class _GreetingBanner extends StatelessWidget {
  final String name;
  const _GreetingBanner({required this.name});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.packer,
              AppColors.packer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.packer.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting,',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('📦 Packer',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Text('📦', style: TextStyle(fontSize: 48)),
        ]),
      );
}

// ── Today summary card ────────────────────────────────────────
class _TodaySummaryCard extends StatelessWidget {
  final PackerProductionViewModel vm;
  const _TodaySummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryCell(
              icon: Icons.inventory_2_outlined,
              value: '${vm.todayTotalBundles}',
              label: 'Bundles Today',
              color: AppColors.packer,
            ),
            Container(width: 1, height: 44, color: AppColors.border),
            _SummaryCell(
              icon: Icons.payments_outlined,
              value: formatCurrency(vm.todaySalary),
              label: 'Today\'s Salary',
              color: AppColors.success,
            ),
          ],
        ),
      );
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;
  const _SummaryCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
      );
}

// ── Add production button ─────────────────────────────────────
class _AddProductionButton extends StatelessWidget {
  final String userId;
  const _AddProductionButton({required this.userId});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Production',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.packer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PackerProductionInputScreen()),
          ),
        ),
      );
}

// ── Production entry card ─────────────────────────────────────
class _ProductionEntryCard extends StatelessWidget {
  final dynamic prod;
  final int     index;
  final String  packerId;
  const _ProductionEntryCard({
    required this.prod,
    required this.index,
    required this.packerId,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 55),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.packer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prod.productName.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Text(prod.timestamp.substring(11, 16),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${prod.bundleCount} bundles',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.packer)),
              const SizedBox(height: 4),
              Text(formatCurrency(prod.salaryEarned),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final vm = context.read<PackerProductionViewModel>();
              await vm.deleteProduction(prod.id, packerId);
            },
            child: Icon(Icons.delete_outline,
                size: 18,
                color: AppColors.danger.withValues(alpha: 0.7)),
          ),
        ]),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: AppColors.packer,
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