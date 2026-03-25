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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.seller,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text)),
              const Text('Seller',
                  style: TextStyle(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.seller.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.seller.withValues(alpha: 0.2)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🥖', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Text('Pandesal',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.seller)),
              ]),
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
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
class _SellerHomePage extends StatefulWidget {
  final dynamic user;
  const _SellerHomePage({required this.user});

  @override
  State<_SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<_SellerHomePage> {
  DateTime _viewDate = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _viewDate.year == now.year &&
        _viewDate.month == now.month &&
        _viewDate.day == now.day;
  }

  String get _viewDateStr => _viewDate.toIso8601String().substring(0, 10);

  void _loadDate() {
    final uid = context.read<AuthViewModel>().currentUser!.id;
    context.read<SellerSessionViewModel>().loadDateRecord(uid, _viewDateStr);
  }

  void _changeDay(int dir) {
    final next = _viewDate.add(Duration(days: dir));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _viewDate = next);
    _loadDate();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: AppColors.seller, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _viewDate = picked);
      _loadDate();
    }
  }

  void _goToSession(SessionType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerSessionInputScreen(
          sessionType: type,
          date: _viewDateStr,
        ),
      ),
    ).then((_) => _loadDate());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();

    return RefreshIndicator(
      color: AppColors.seller,
      onRefresh: () async => _loadDate(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isToday) ...[
              _GreetingBanner(name: widget.user.name),
              const SizedBox(height: 16),
            ],

            _DateNav(
              viewDate: _viewDate,
              isToday: _isToday,
              onPrev: () => _changeDay(-1),
              onNext: _isToday ? null : () => _changeDay(1),
              onPick: _pickDate,
            ),
            const SizedBox(height: 16),

            _DayFlowCard(vm: vm),
            const SizedBox(height: 16),

            _SessionButtons(
              vm: vm,
              isToday: _isToday,
              viewDate: _viewDateStr,
              onMorning: () => _goToSession(SessionType.morning),
              onAfternoon: () => _goToSession(SessionType.afternoon),
            ),
            const SizedBox(height: 20),

            if (vm.hasSessionForDate) ...[
              const _SectionLabel('SESSION SUMMARY'),
              const SizedBox(height: 10),
              _TodaySummaryCard(vm: vm),
            ] else ...[
              _EmptyDayCard(dateStr: _viewDateStr),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Date navigator ────────────────────────────────────────────
class _DateNav extends StatelessWidget {
  final DateTime viewDate;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  const _DateNav({
    required this.viewDate,
    required this.isToday,
    required this.onPrev,
    required this.onPick,
    this.onNext,
  });

  String _format(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}'
        '${isToday ? ' (Today)' : ''}';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPick,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.seller.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.seller.withValues(alpha: 0.20)),
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: AppColors.seller,
              iconSize: 20,
              onPressed: onPrev,
            ),
            Expanded(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.seller),
                  const SizedBox(width: 6),
                  Text(_format(viewDate),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isToday ? AppColors.seller : AppColors.primaryDark)),
                ]),
                const Text('Tap to pick a date',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              ]),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right,
                  color: onNext != null
                      ? AppColors.seller
                      : AppColors.textHint.withValues(alpha: 0.3)),
              iconSize: 20,
              onPressed: onNext,
            ),
          ]),
        ),
      );
}

// ── Greeting ──────────────────────────────────────────────────
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
            colors: [AppColors.seller, AppColors.seller.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: AppColors.seller.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$_greeting,',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🥖 Pandesal Seller',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const Text('🏪', style: TextStyle(fontSize: 48)),
        ]),
      );
}

// ── 4-step flow ───────────────────────────────────────────────
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
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel('DAY\'S FLOW'),
          const SizedBox(height: 16),
          Row(children: [
            _FlowStep(icon: Icons.wb_sunny_outlined,   label: 'Morning\nSession',
                isDone: vm.hasMorningSession,    color: AppColors.seller),
            _FlowLine(isDone: vm.hasMorningRemittance),
            _FlowStep(icon: Icons.payments_outlined,   label: 'Morning\nRemit',
                isDone: vm.hasMorningRemittance, color: const Color(0xFF1976D2)),
            _FlowLine(isDone: vm.hasAfternoonSession),
            _FlowStep(icon: Icons.wb_twilight_outlined, label: 'Afternoon\nSession',
                isDone: vm.hasAfternoonSession,    color: AppColors.warning),
            _FlowLine(isDone: vm.hasAfternoonRemittance),
            _FlowStep(icon: Icons.task_alt_outlined,    label: 'Afternoon\nRemit',
                isDone: vm.hasAfternoonRemittance, color: AppColors.success),
          ]),
        ]),
      );
}

class _FlowStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final Color color;
  const _FlowStep({
    required this.icon, required this.label,
    required this.isDone, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDone ? color : color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDone ? color : color.withValues(alpha: 0.30), width: 1.5),
            ),
            child: Icon(isDone ? Icons.check : icon, size: 18,
                color: isDone ? Colors.white : color),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: isDone ? color : AppColors.textHint, height: 1.3)),
        ]),
      );
}

class _FlowLine extends StatelessWidget {
  final bool isDone;
  const _FlowLine({required this.isDone});

  @override
  Widget build(BuildContext context) => Container(
        width: 18, height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isDone ? AppColors.success : AppColors.border,
      );
}

// ── Session buttons ───────────────────────────────────────────
class _SessionButtons extends StatelessWidget {
  final SellerSessionViewModel vm;
  final bool isToday;
  final String viewDate;
  final VoidCallback onMorning;
  final VoidCallback onAfternoon;

  const _SessionButtons({
    required this.vm, required this.isToday,
    required this.viewDate, required this.onMorning, required this.onAfternoon,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(child: _ActionBtn(
            icon: Icons.wb_sunny_outlined,
            label: vm.hasMorningSession ? 'Morning Done ✓' : 'Morning Session',
            color: AppColors.seller, isDisabled: vm.hasMorningSession, onTap: onMorning,
          )),
          const SizedBox(width: 10),
          Expanded(child: _InfoBtn(
            icon: Icons.payments_outlined,
            label: vm.hasMorningRemittance ? 'Morning Remit ✓' : 'Admin Remits',
            sublabel: 'Morning', color: const Color(0xFF1976D2),
            isDone: vm.hasMorningRemittance,
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionBtn(
            icon: Icons.wb_twilight_outlined,
            label: vm.hasAfternoonSession ? 'Afternoon Done ✓' : 'Afternoon Session',
            color: AppColors.warning, isDisabled: vm.hasAfternoonSession, onTap: onAfternoon,
          )),
          const SizedBox(width: 10),
          Expanded(child: _InfoBtn(
            icon: Icons.task_alt_outlined,
            label: vm.hasAfternoonRemittance ? 'Afternoon Remit ✓' : 'Admin Remits',
            sublabel: 'Afternoon', color: AppColors.success,
            isDone: vm.hasAfternoonRemittance,
          )),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.20)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.info),
            SizedBox(width: 8),
            Expanded(child: Text(
              'You can input morning or afternoon independently. '
              'Remittance is recorded by the admin.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            )),
          ]),
        ),
      ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDisabled;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon, required this.label, required this.color,
    required this.isDisabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.border.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDisabled ? AppColors.border : color.withValues(alpha: 0.30)),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: isDisabled ? AppColors.textHint : color),
            const SizedBox(width: 8),
            Expanded(child: Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isDisabled ? AppColors.textHint : color))),
          ]),
        ),
      );
}

class _InfoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isDone;
  const _InfoBtn({
    required this.icon, required this.label, required this.sublabel,
    required this.color, required this.isDone,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDone ? color.withValues(alpha: 0.08) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDone ? color.withValues(alpha: 0.30) : AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: isDone ? color : AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDone ? color : AppColors.textHint)),
            Text(sublabel,
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
        ]),
      );
}

// ── Summary card ──────────────────────────────────────────────
class _TodaySummaryCard extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _TodaySummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          if (vm.hasMorningSession)
            _SessionBlock(
              icon: Icons.wb_sunny_outlined, label: 'Morning', color: AppColors.seller,
              plantsaCount: vm.morningSession?.plantsaCount ?? 0,
              subraPieces:  vm.morningSession?.subraPieces  ?? 0,
              pieces:       vm.morningPiecesTaken,
              expected:     vm.morningExpectedRemittance,
              remitted:     vm.hasMorningRemittance ? vm.morningActualRemittance : null,
              returned:     vm.morningReturnPieces,
              sold:         vm.morningPiecesSold,
              salary:       vm.morningRemittance?.salary,   // ← salary per session
            ),
          if (vm.hasMorningSession && vm.hasAfternoonSession)
            const Divider(height: 1, color: AppColors.border),
          if (vm.hasAfternoonSession)
            _SessionBlock(
              icon: Icons.wb_twilight_outlined, label: 'Afternoon', color: AppColors.warning,
              plantsaCount: vm.afternoonSession?.plantsaCount ?? 0,
              subraPieces:  vm.afternoonSession?.subraPieces  ?? 0,
              pieces:       vm.afternoonPiecesTaken,
              expected:     vm.afternoonExpectedRemittance,
              remitted:     vm.hasAfternoonRemittance ? vm.afternoonActualRemittance : null,
              returned:     vm.afternoonReturnPieces,
              sold:         vm.afternoonPiecesSold,
              salary:       vm.afternoonRemittance?.salary, // ← salary per session
            ),
          if (vm.hasMorningRemittance || vm.hasAfternoonRemittance) ...[
            Container(height: 1, color: AppColors.seller.withValues(alpha: 0.15)),
            _TotalBlock(vm: vm),
          ],
        ]),
      );
}

// ── Session block ─────────────────────────────────────────────
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
  final double?  salary;   // ← per-session salary

  const _SessionBlock({
    required this.icon, required this.label, required this.color,
    required this.plantsaCount, required this.subraPieces, required this.pieces,
    required this.expected, required this.returned, required this.sold,
    this.remitted, this.salary,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ─────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: remitted != null
                    ? AppColors.success.withValues(alpha: 0.10)
                    : AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                remitted != null ? '✓ Remitted' : 'Pending',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: remitted != null ? AppColors.success : AppColors.warning),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Pieces row ─────────────────────────────────
          Row(children: [
            Expanded(child: Text(
              '$plantsaCount plantsa + $subraPieces subra = $pieces pcs',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )),
            Text(formatCurrency(expected),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ]),

          if (remitted != null) ...[
            const SizedBox(height: 8),
            // ── Returned / Sold / Cash ──────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                _MiniStat(label: 'Returned', value: '$returned pcs', color: AppColors.warning),
                const SizedBox(width: 14),
                _MiniStat(label: 'Sold',     value: '$sold pcs',     color: AppColors.success),
                const Spacer(),
                _MiniStat(label: 'Cash', value: formatCurrency(remitted!),
                    color: AppColors.primaryDark, bold: true),
              ]),
            ),

            // ── Session salary chip ─────────────────────
            if (salary != null && salary! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.seller.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.seller.withValues(alpha: 0.20)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Row(children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 13, color: AppColors.seller),
                    SizedBox(width: 6),
                    Text('Session Salary',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.seller)),
                  ]),
                  Text(formatCurrency(salary!),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.seller)),
                ]),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
              ),
              child: const Row(children: [
                Icon(Icons.schedule_outlined, size: 13, color: AppColors.info),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Waiting for admin to record remittance',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                )),
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
    required this.label, required this.value,
    required this.color, this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          Text(value,
              style: TextStyle(fontSize: 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ],
      );
}

// ── Total block with salary ───────────────────────────────────
class _TotalBlock extends StatelessWidget {
  final SellerSessionViewModel vm;
  const _TotalBlock({required this.vm});

  @override
  Widget build(BuildContext context) {
    final totalRemitted = vm.morningActualRemittance + vm.afternoonActualRemittance;
    final totalExpected = vm.morningExpectedRemittance + vm.afternoonExpectedRemittance;
    final totalSold     = vm.morningPiecesSold + vm.afternoonPiecesSold;
    final totalSalary   = (vm.morningRemittance?.salary   ?? 0.0)
                        + (vm.afternoonRemittance?.salary ?? 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.seller, AppColors.seller.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOTAL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white70, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(formatCurrency(totalRemitted),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('$totalSold pcs sold',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
            // ── Total salary line ───────────────────────
            if (totalSalary > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text('Salary: ${formatCurrency(totalSalary)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ],
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _TotPill(label: 'Expected', value: formatCurrency(totalExpected)),
          const SizedBox(height: 4),
          _TotPill(label: 'Remitted', value: formatCurrency(totalRemitted)),
        ]),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$label: $value',
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
      );
}

class _EmptyDayCard extends StatelessWidget {
  final String dateStr;
  const _EmptyDayCard({required this.dateStr});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(Icons.calendar_today_outlined, size: 40,
              color: AppColors.seller.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          const Text('No sessions recorded',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('No data for $dateStr',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: AppColors.seller, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.textHint, letterSpacing: 0.8)),
      ]);
}