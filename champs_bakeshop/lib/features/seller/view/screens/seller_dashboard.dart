
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_session_viewmodel.dart';


// ── ADD THESE ──────────────────────────────────
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.seller.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.seller.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏪', style: TextStyle(fontSize: 12)),
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
            // ── Greeting ──────────────────────────────────────
            _GreetingBanner(name: user.name),
            const SizedBox(height: 20),

            // ── Today status ──────────────────────────────────
            const _TodayStatusCard(),
            const SizedBox(height: 16),

            // ── Quick actions ─────────────────────────────────
            const _QuickActions(),
            const SizedBox(height: 20),

            // ── Today summary ─────────────────────────────────
            if (vm.hasSessionToday) ...[
              _SectionLabel('TODAY\'S SUMMARY'),
              const SizedBox(height: 10),
              const _TodaySummaryCard(),
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
                  child: const Text('🏪 Pandesal Seller',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Text('🥖', style: TextStyle(fontSize: 48)),
        ]),
      );
}

// ── Today status card ─────────────────────────────────────────
class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();

    final bool sessionDone    = vm.hasSessionToday;
    final bool remittanceDone = vm.hasRemittanceToday;

    return Container(
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
          const _SectionLabel('TODAY\'S STATUS'),
          const SizedBox(height: 12),
          Row(children: [
            _StatusStep(
              icon: Icons.storefront_outlined,
              label: 'Session',
              sublabel: 'Morning input',
              isDone: sessionDone,
              color: AppColors.seller,
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: remittanceDone
                    ? AppColors.success
                    : AppColors.border,
              ),
            ),
            _StatusStep(
              icon: Icons.payments_outlined,
              label: 'Remittance',
              sublabel: 'Evening submit',
              isDone: remittanceDone,
              color: AppColors.success,
            ),
          ]),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sublabel;
  final bool     isDone;
  final Color    color;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isDone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDone
                  ? color.withValues(alpha: 0.12)
                  : AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 20,
              color: isDone ? color : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDone ? color : AppColors.textHint)),
          Text(sublabel,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
        ],
      );
}

// ── Quick actions ─────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();

    return Row(children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.storefront_outlined,
          label: 'Start Session',
          sublabel: 'Morning',
          color: AppColors.seller,
          isDisabled: vm.hasSessionToday,
          disabledLabel: 'Session Done',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SellerSessionInputScreen()),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ActionButton(
          icon: Icons.payments_outlined,
          label: vm.hasRemittanceToday ? 'Edit Remittance' : 'Remit Now',
          sublabel: 'Evening',
          color: AppColors.success,
          isDisabled: !vm.hasSessionToday,
          disabledLabel: 'No session yet',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SellerRemitScreen()),
          ),
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sublabel;
  final Color    color;
  final bool     isDisabled;
  final String   disabledLabel;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDisabled,
    required this.disabledLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.border.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled
                  ? AppColors.border
                  : color.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 24,
                  color: isDisabled ? AppColors.textHint : color),
              const SizedBox(height: 10),
              Text(isDisabled ? disabledLabel : label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDisabled ? AppColors.textHint : color)),
              Text(sublabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ),
      );
}

// ── Today summary card ────────────────────────────────────────
class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${vm.todaySession?.plantsaCount ?? 0} plantsa'
                  ' + ${vm.todaySession?.subraPieces ?? 0} subra',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                Text('${vm.totalPiecesTaken} total pieces taken out',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.seller.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatCurrency(vm.expectedRemittance),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.seller),
                ),
              ),
            ],
          ),
          if (vm.hasRemittanceToday) ...[
            const Divider(height: 20, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                    label: 'Returned',
                    value: '${vm.returnPieces} pcs',
                    color: AppColors.warning),
                _SummaryItem(
                    label: 'Sold',
                    value: '${vm.piecesSold} pcs',
                    color: AppColors.success),
                _SummaryItem(
                    label: 'Remitted',
                    value: formatCurrency(vm.actualRemittance),
                    color: AppColors.primaryDark),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textHint)),
      ]);
}

// ── Shared small widgets ──────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
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