import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_session_viewmodel.dart';
import 'seller_daily_screen.dart';
import 'seller_weekly_screen.dart';
import 'seller_monthly_screen.dart';
import 'seller_profile.dart';
import 'seller_session_input.dart';
import 'seller_remit_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
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
      context.read<SellerSessionViewModel>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;

    final pages = [
      _SellerHomePage(user: user),
      const SellerDailyScreen(),
      const SellerWeeklyScreen(),
      const SellerMonthlyScreen(),
      const SellerProfileScreen(),
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
              color: AppColors.seller.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.seller, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seller',
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.seller.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.seller.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🥖', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text('Pandesal',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.seller)),
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
        selectedItemColor: AppColors.seller,
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
class _SellerHomePage extends StatelessWidget {
  final dynamic user;
  const _SellerHomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();

    return RefreshIndicator(
      color: AppColors.seller,
      onRefresh: () => vm.loadTodayRecord(user.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingBanner(name: user.name),
            const SizedBox(height: 20),
            _DayFlowCard(vm: vm),
            const SizedBox(height: 16),
            _ActionButtons(vm: vm),
            const SizedBox(height: 20),
            if (vm.hasSessionToday) ...[
              const _SectionLabel('TODAY\'S SUMMARY'),
              const SizedBox(height: 10),
              _TodaySummaryCard(vm: vm),
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
              AppColors.seller,
              AppColors.seller.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.seller.withValues(alpha: 0.30),
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
                  child: const Text('🥖 Pandesal Seller',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Text('🏪', style: TextStyle(fontSize: 48)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  DAY FLOW STATUS  (4 steps)
// ══════════════════════════════════════════════════════════════
class _DayFlowCard extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _DayFlowCard({required this.vm});

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
          children: [
            const _SectionLabel('TODAY\'S FLOW'),
            const SizedBox(height: 16),
            Row(children: [
              _FlowStep(
                icon:   Icons.wb_sunny_outlined,
                label:  'Morning\nSession',
                isDone: vm.hasMorningSession,
                color:  AppColors.seller,
              ),
              _FlowLine(isDone: vm.hasMorningRemittance),
              _FlowStep(
                icon:   Icons.payments_outlined,
                label:  'Morning\nRemit',
                isDone: vm.hasMorningRemittance,
                color:  const Color(0xFF1976D2),
              ),
              _FlowLine(isDone: vm.hasAfternoonSession),
              _FlowStep(
                icon:   Icons.wb_twilight_outlined,
                label:  'Afternoon\nSession',
                isDone: vm.hasAfternoonSession,
                color:  AppColors.warning,
              ),
              _FlowLine(isDone: vm.hasAfternoonRemittance),
              _FlowStep(
                icon:   Icons.task_alt_outlined,
                label:  'Afternoon\nRemit',
                isDone: vm.hasAfternoonRemittance,
                color:  AppColors.success,
              ),
            ]),
          ],
        ),
      );
}

class _FlowStep extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isDone;
  final Color    color;
  const _FlowStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone
                  ? color
                  : color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? color
                    : color.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 18,
              color: isDone ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDone ? color : AppColors.textHint,
                  height: 1.3)),
        ]),
      );
}

class _FlowLine extends StatelessWidget {
  final bool isDone;
  const _FlowLine({required this.isDone});

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isDone ? AppColors.success : AppColors.border,
      );
}

// ══════════════════════════════════════════════════════════════
//  ACTION BUTTONS  (2×2 grid)
// ══════════════════════════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _ActionButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    final canMorningSession   = !vm.hasMorningSession;
    final canMorningRemit     = vm.hasMorningSession && !vm.hasMorningRemittance;
    final canAfternoonSession = vm.hasMorningRemittance && !vm.hasAfternoonSession;
    final canAfternoonRemit   = vm.hasAfternoonSession && !vm.hasAfternoonRemittance;

    return Column(children: [
      Row(children: [
        Expanded(
          child: _ActionBtn(
            icon:       Icons.wb_sunny_outlined,
            label:      vm.hasMorningSession
                ? 'Morning Done ✓'
                : 'Morning Session',
            color:      AppColors.seller,
            isDisabled: !canMorningSession,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerSessionInputScreen(
                  sessionType: SessionType.morning,
                )),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon:       Icons.payments_outlined,
            label:      vm.hasMorningRemittance
                ? 'Morning Remit ✓'
                : 'Morning Remit',
            color:      const Color(0xFF1976D2),
            isDisabled: !canMorningRemit,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerRemitScreen(
                  remitType: RemitType.morning,
                )),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: _ActionBtn(
            icon:       Icons.wb_twilight_outlined,
            label:      vm.hasAfternoonSession
                ? 'Afternoon Done ✓'
                : 'Afternoon Session',
            color:      AppColors.warning,
            isDisabled: !canAfternoonSession,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerSessionInputScreen(
                  sessionType: SessionType.afternoon,
                )),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon:       Icons.task_alt_outlined,
            label:      vm.hasAfternoonRemittance
                ? 'Afternoon Remit ✓'
                : 'Afternoon Remit',
            color:      AppColors.success,
            isDisabled: !canAfternoonRemit,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerRemitScreen(
                  remitType: RemitType.afternoon,
                )),
            ),
          ),
        ),
      ]),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final bool         isDisabled;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.border.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled
                  ? AppColors.border
                  : color.withValues(alpha: 0.30),
            ),
          ),
          child: Row(children: [
            Icon(icon,
                size: 20,
                color: isDisabled ? AppColors.textHint : color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? AppColors.textHint
                          : color)),
            ),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  TODAY'S SUMMARY CARD
// ══════════════════════════════════════════════════════════════
class _TodaySummaryCard extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _TodaySummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
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
        child: Column(children: [
          // ── Morning ────────────────────────────────────────
          if (vm.hasMorningSession)
            _SessionBlock(
              icon:         Icons.wb_sunny_outlined,
              label:        'Morning',
              color:        AppColors.seller,
              plantsaCount: vm.morningSession?.plantsaCount ?? 0,
              subraPieces:  vm.morningSession?.subraPieces  ?? 0,
              pieces:       vm.morningPiecesTaken,
              expected:     vm.morningExpectedRemittance,
              remitted:     vm.hasMorningRemittance
                  ? vm.morningActualRemittance
                  : null,
              returned:     vm.morningReturnPieces,
              sold:         vm.morningPiecesSold,
            ),

          if (vm.hasMorningSession && vm.hasAfternoonSession)
            const Divider(height: 1, color: AppColors.border),

          // ── Afternoon ──────────────────────────────────────
          if (vm.hasAfternoonSession)
            _SessionBlock(
              icon:         Icons.wb_twilight_outlined,
              label:        'Afternoon',
              color:        AppColors.warning,
              plantsaCount: vm.afternoonSession?.plantsaCount ?? 0,
              subraPieces:  vm.afternoonSession?.subraPieces  ?? 0,
              pieces:       vm.afternoonPiecesTaken,
              expected:     vm.afternoonExpectedRemittance,
              remitted:     vm.hasAfternoonRemittance
                  ? vm.afternoonActualRemittance
                  : null,
              returned:     vm.afternoonReturnPieces,
              sold:         vm.afternoonPiecesSold,
            ),

          // ── Total (only if at least 1 remittance done) ─────
          if (vm.hasMorningRemittance || vm.hasAfternoonRemittance) ...[
            Container(height: 1, color: AppColors.seller.withValues(alpha: 0.15)),
            _TotalBlock(vm: vm),
          ],
        ]),
      );
}

class _SessionBlock extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final int      plantsaCount;
  final int      subraPieces;
  final int      pieces;
  final double   expected;
  final double?  remitted;
  final int      returned;
  final int      sold;

  const _SessionBlock({
    required this.icon,
    required this.label,
    required this.color,
    required this.plantsaCount,
    required this.subraPieces,
    required this.pieces,
    required this.expected,
    required this.returned,
    required this.sold,
    this.remitted,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: remitted != null
                    ? AppColors.success.withValues(alpha: 0.10)
                    : AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                remitted != null ? '✓ Remitted' : 'Pending',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: remitted != null
                        ? AppColors.success
                        : AppColors.warning),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Taken out ────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Text(
                '$plantsaCount plantsa + $subraPieces subra = $pieces pcs',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),
            ),
            Text(formatCurrency(expected),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ]),

          // ── Remit details ────────────────────────────────────
          if (remitted != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        AppColors.success.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                _MiniStat(
                    label: 'Returned',
                    value: '$returned pcs',
                    color: AppColors.warning),
                const SizedBox(width: 14),
                _MiniStat(
                    label: 'Sold',
                    value: '$sold pcs',
                    color: AppColors.success),
                const Spacer(),
                _MiniStat(
                    label: 'Cash',
                    value: formatCurrency(remitted!),
                    color: AppColors.primaryDark,
                    bold: true),
              ]),
            ),
          ],
        ]),
      );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   bold;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: color)),
        ],
      );
}

// ── Total block ───────────────────────────────────────────────
class _TotalBlock extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _TotalBlock({required this.vm});

  @override
  Widget build(BuildContext context) {
    final totalRemitted = vm.morningActualRemittance +
        vm.afternoonActualRemittance;
    final totalExpected = vm.morningExpectedRemittance +
        vm.afternoonExpectedRemittance;
    final totalSold     = vm.morningPiecesSold +
        vm.afternoonPiecesSold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.seller,
            AppColors.seller.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL TODAY',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(formatCurrency(totalRemitted),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text('$totalSold pcs sold',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _TotPill(
                label: 'Expected',
                value: formatCurrency(totalExpected)),
            const SizedBox(height: 4),
            _TotPill(
                label: 'Remitted',
                value: formatCurrency(totalRemitted)),
          ],
        ),
      ]),
    );
  }
}

class _TotPill extends StatelessWidget {
  final String label;
  final String value;
  const _TotPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$label: $value',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );
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
              color: AppColors.seller,
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