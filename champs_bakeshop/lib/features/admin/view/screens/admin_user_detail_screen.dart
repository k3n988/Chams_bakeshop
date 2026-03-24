import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../helper/viewmodel/helper_salary_viewmodel.dart';
import '../../../master_baker/viewmodel/baker_salary_viewmodel.dart';
import '../../../packer/viewmodel/packer_salary_viewmodel.dart';
import '../../../seller/viewmodel/seller_remittance_viewmodel.dart';

// ── Orange accent used throughout this screen ─────────────────
const _kOrange = Color(0xFFFF8C00); // matches dashboard orange

// ══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ══════════════════════════════════════════════════════════════
class AdminUserDetailScreen extends StatelessWidget {
  final UserModel user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.isHelper) {
      final db      = context.read<SupabaseService>();
      final payroll = context.read<PayrollService>();
      return ChangeNotifierProvider(
        create: (_) => HelperSalaryViewModel(db, payroll),
        child: _UserDetailShell(user: user),
      );
    }
    if (user.isMasterBaker) {
      final db = context.read<DatabaseService>();
      return ChangeNotifierProvider(
        create: (_) => BakerSalaryViewModel(db),
        child: _UserDetailShell(user: user),
      );
    }
    if (user.isPacker) {
      return ChangeNotifierProvider(
        create: (_) => PackerSalaryViewModel(),
        child: _UserDetailShell(user: user),
      );
    }
    if (user.isSeller) {
      return ChangeNotifierProvider(
        create: (_) => SellerRemittanceViewModel(),
        child: _UserDetailShell(user: user),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Center(
        child: Text('No detail view for role: ${user.role}',
            style: const TextStyle(color: AppColors.textHint)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHELL
// ══════════════════════════════════════════════════════════════
class _UserDetailShell extends StatelessWidget {
  final UserModel user;
  const _UserDetailShell({required this.user});

  bool get _hasBonus => user.isHelper || user.isMasterBaker;

  Color get _roleColor {
    if (user.isMasterBaker) return AppColors.masterBaker;
    if (user.isHelper)      return _kOrange;
    if (user.isPacker)      return AppColors.packer;
    if (user.isSeller)      return AppColors.success;
    return _kOrange;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.today_outlined),         text: 'Daily'),
      const Tab(icon: Icon(Icons.date_range_outlined),     text: 'Weekly'),
      const Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Monthly'),
      if (_hasBonus)
        const Tab(icon: Icon(Icons.inventory_2_outlined),  text: 'Bonus'),
    ];

    List<Widget> views;
    if (user.isHelper) {
      views = [
        _HelperDailyTab(userId: user.id),
        _HelperWeeklyTab(userId: user.id, isHelper: true),
        _HelperMonthlyTab(userId: user.id),
        _HelperBonusTab(userId: user.id),
      ];
    } else if (user.isMasterBaker) {
      views = [
        _BakerDailyTab(userId: user.id),
        _BakerWeeklyTab(userId: user.id),
        _BakerMonthlyTab(userId: user.id),
        _BakerBonusTab(userId: user.id),
      ];
    } else if (user.isPacker) {
      views = [
        _PackerDailyTab(userId: user.id),
        _PackerWeeklyTab(userId: user.id),
        _PackerMonthlyTab(userId: user.id),
      ];
    } else {
      views = [
        _SellerDailyTab(userId: user.id),
        _SellerWeeklyTab(userId: user.id),
        _SellerMonthlyTab(userId: user.id),
      ];
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(children: [
            // Avatar circle
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _roleColor,
                    _roleColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase() : '?',
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
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primaryDark)),
                Text(user.roleDisplay,
                    style: TextStyle(
                        fontSize: 11,
                        color: _roleColor,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _roleColor.withValues(alpha: 0.30)),
                ),
                child: Text(user.roleDisplay,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _roleColor,
                        letterSpacing: 0.4)),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: TabBar(
                tabs: tabs,
                labelColor: _kOrange,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: _kOrange,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HELPER TABS
// ══════════════════════════════════════════════════════════════

class _HelperDailyTab extends StatefulWidget {
  final String userId;
  const _HelperDailyTab({required this.userId});
  @override
  State<_HelperDailyTab> createState() => _HelperDailyTabState();
}

class _HelperDailyTabState extends State<_HelperDailyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context
      .read<HelperSalaryViewModel>()
      .loadDailyRecordsForMonth(
          widget.userId, _month.year, _month.month);

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required by AutomaticKeepAliveClientMixin
    final vm      = context.watch<HelperSalaryViewModel>();
    final records = vm.dailyRecords;
    final total   = records.fold(0.0, (s, r) => s + r.salary);
    final sacks   = records.fold(0,   (s, r) => s + r.totalSacks);

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 12),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else if (records.isEmpty)
            EmptyState(message:
                'No records for ${_monthNames[_month.month - 1]}')
          else ...[
            _SummaryBar(items: [
              _SI(Icons.work_history_outlined, 'Days',
                  '${records.length}', _kOrange),
              _SI(Icons.inventory_2_outlined, 'Sacks',
                  '$sacks', AppColors.primary),
              _SI(Icons.payments_outlined, 'Total',
                  formatCurrency(total), AppColors.success),
            ]),
            const SizedBox(height: 12),
            ...records.asMap().entries.map(
                (e) => _DailyRecordCard(record: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ── Helper Weekly ─────────────────────────────────────────────
class _HelperWeeklyTab extends StatefulWidget {
  final String userId;
  final bool   isHelper;
  const _HelperWeeklyTab(
      {required this.userId, required this.isHelper});
  @override
  State<_HelperWeeklyTab> createState() => _HelperWeeklyTabState();
}

class _HelperWeeklyTabState extends State<_HelperWeeklyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context
      .read<HelperSalaryViewModel>()
      .loadWeeklySalaryForMonth(
          widget.userId, _month.year, _month.month);

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<HelperSalaryViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 10),
          WeekSelector(
            weekStart: vm.weekStart,
            weekEnd:   vm.weekEnd,
            onPrev: () => context
                .read<HelperSalaryViewModel>()
                .changeWeek(-1, widget.userId),
            onNext: () => context
                .read<HelperSalaryViewModel>()
                .changeWeek(1, widget.userId),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else ...[
            Row(children: [
              Expanded(child: _StatChip(label: 'Gross',
                  value: formatCurrency(vm.grossSalary),
                  color: AppColors.masterBaker)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Days',
                  value: '${vm.daysWorked}', color: _kOrange)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Net',
                  value: formatCurrency(vm.finalSalary),
                  color: AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            _HelperDeductionsCard(vm: vm, isHelper: widget.isHelper),
            const SizedBox(height: 12),
            if (vm.weeklyDaily.isNotEmpty) ...[
              const _Label('DAILY BREAKDOWN'),
              const SizedBox(height: 8),
              ...vm.weeklyDaily.map((d) =>
                  _DailyBreakdownRow(date: d.key, salary: d.value)),
            ] else
              const EmptyState(message: 'No records for this week'),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx, initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ), child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ── Helper Monthly ────────────────────────────────────────────
class _HelperMonthlyTab extends StatefulWidget {
  final String userId;
  const _HelperMonthlyTab({required this.userId});
  @override
  State<_HelperMonthlyTab> createState() => _HelperMonthlyTabState();
}

class _HelperMonthlyTabState extends State<_HelperMonthlyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _weekColors = [
    _kOrange, AppColors.primary,
    AppColors.masterBaker, AppColors.purple,
  ];

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context
      .read<HelperSalaryViewModel>()
      .loadMonthlySummary(widget.userId,
          year: _month.year, month: _month.month);

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<HelperSalaryViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else ...[
            _MonthlyBanner(
              total: vm.monthlyTotalSalary,
              days:  vm.monthlyTotalDays,
              sacks: vm.monthlyTotalSacks,
              weeks: vm.monthlyWeeks.length,
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _StatTile('Gross',
                    formatCurrency(vm.monthlyGrossSalary),
                    Icons.payments_outlined, AppColors.masterBaker),
                _StatTile('Deductions',
                    '-${formatCurrency(vm.monthlyTotalDeductions)}',
                    Icons.remove_circle_outline, AppColors.danger),
                _StatTile('Net Salary',
                    formatCurrency(vm.monthlyTotalSalary),
                    Icons.account_balance_wallet_outlined,
                    AppColors.success),
                _StatTile('Avg/Week',
                    formatCurrency(vm.monthlyAvgPerWeek),
                    Icons.trending_up_outlined, _kOrange),
              ],
            ),
            const SizedBox(height: 14),
            const _Label('WEEKLY BREAKDOWN'),
            const SizedBox(height: 8),
            if (vm.monthlyWeeks.isEmpty)
              EmptyState(message:
                  'No data for ${_monthNames[_month.month - 1]}')
            else
              ...vm.monthlyWeeks.asMap().entries.map((e) =>
                  _WeekTile(
                    week:  e.value,
                    index: e.key,
                    color: _weekColors[e.key % _weekColors.length],
                  )),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx, initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ), child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ── Helper Bonus ──────────────────────────────────────────────
class _HelperBonusTab extends StatefulWidget {
  final String userId;
  const _HelperBonusTab({required this.userId});
  @override
  State<_HelperBonusTab> createState() => _HelperBonusTabState();
}

class _HelperBonusTabState extends State<_HelperBonusTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context
      .read<HelperSalaryViewModel>()
      .loadDailyRecordsForMonth(
          widget.userId, _month.year, _month.month);

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm      = context.watch<HelperSalaryViewModel>();
    final records = vm.dailyRecords;
    final sacks   = records.fold(0,   (s, r) => s + r.totalSacks);
    final value   = records.fold(0.0, (s, r) => s + r.totalValue);

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else if (records.isEmpty)
            EmptyState(message:
                'No records for ${_monthNames[_month.month - 1]}')
          else ...[
            _BonusBanner(sacks: sacks, value: value),
            const SizedBox(height: 14),
            const _Label('DAILY SACK BREAKDOWN'),
            const SizedBox(height: 8),
            ...records.asMap().entries.map(
                (e) => _BonusCard(record: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx, initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ), child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  MASTER BAKER TABS
// ══════════════════════════════════════════════════════════════

class _BakerDailyTab extends StatefulWidget {
  final String userId;
  const _BakerDailyTab({required this.userId});
  @override
  State<_BakerDailyTab> createState() => _BakerDailyTabState();
}

class _BakerDailyTabState extends State<_BakerDailyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final prefix  = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
    context.read<BakerSalaryViewModel>()
        .loadMonthlyData(widget.userId,
            '$prefix-01',
            '$prefix-${lastDay.toString().padLeft(2, '0')}');
  }

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm      = context.watch<BakerSalaryViewModel>();
    final entries = vm.dailyEntries;
    final total   = entries.fold(0.0, (s, e) => s + e.baseSalary);

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 12),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else if (entries.isEmpty)
            EmptyState(message:
                'No records for ${_monthNames[_month.month - 1]}')
          else ...[
            _SummaryBar(items: [
              _SI(Icons.work_history_outlined, 'Days',
                  '${entries.length}', AppColors.masterBaker),
              _SI(Icons.payments_outlined, 'Total',
                  formatCurrency(total), AppColors.success),
              _SI(Icons.star_outline, 'Bonus',
                  formatCurrency(vm.bonusTotal), AppColors.warning),
            ]),
            const SizedBox(height: 12),
            ...entries.asMap().entries.map(
                (e) => _BakerDailyCard(entry: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx, initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ), child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ── Baker Weekly ──────────────────────────────────────────────
class _BakerWeeklyTab extends StatefulWidget {
  final String userId;
  const _BakerWeeklyTab({required this.userId});
  @override
  State<_BakerWeeklyTab> createState() => _BakerWeeklyTabState();
}

class _BakerWeeklyTabState extends State<_BakerWeeklyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<BakerSalaryViewModel>()
            .loadWeeklySalary(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<BakerSalaryViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<BakerSalaryViewModel>()
              .loadWeeklySalary(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          WeekSelector(
            weekStart: vm.weekStart, weekEnd: vm.weekEnd,
            onPrev: () => context.read<BakerSalaryViewModel>()
                .changeWeek(-1, widget.userId),
            onNext: () => context.read<BakerSalaryViewModel>()
                .changeWeek(1, widget.userId),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<BakerSalaryViewModel>()
                    .loadWeeklySalary(widget.userId))
          else ...[
            Row(children: [
              Expanded(child: _StatChip(label: 'Gross',
                  value: formatCurrency(vm.grossSalary),
                  color: AppColors.masterBaker)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Days',
                  value: '${vm.daysWorked}', color: _kOrange)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Net',
                  value: formatCurrency(vm.finalSalary),
                  color: AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            _BakerDeductionsCard(vm: vm),
            const SizedBox(height: 12),
            if (vm.dailyEntries.isNotEmpty) ...[
              const _Label('DAILY BREAKDOWN'),
              const SizedBox(height: 8),
              ...vm.dailyEntries.map((e) =>
                  _DailyBreakdownRow(date: e.date, salary: e.baseSalary)),
            ] else
              const EmptyState(message: 'No records for this week'),
          ],
        ]),
      ),
    );
  }
}

// ── Baker Monthly ─────────────────────────────────────────────
class _BakerMonthlyTab extends StatefulWidget {
  final String userId;
  const _BakerMonthlyTab({required this.userId});
  @override
  State<_BakerMonthlyTab> createState() => _BakerMonthlyTabState();
}

class _BakerMonthlyTabState extends State<_BakerMonthlyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final prefix  = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
    context.read<BakerSalaryViewModel>().loadMonthlyData(
        widget.userId,
        '$prefix-01',
        '$prefix-${lastDay.toString().padLeft(2, '0')}');
  }

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm      = context.watch<BakerSalaryViewModel>();
    final entries = vm.dailyEntries;

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else ...[
            _MonthlyBanner(
              total: vm.finalSalary,
              days:  vm.daysWorked,
              sacks: 0, weeks: 0,
              showBonusInstead: true,
              bonusLabel: formatCurrency(vm.bonusTotal),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _StatTile('Gross', formatCurrency(vm.grossSalary),
                    Icons.payments_outlined, AppColors.masterBaker),
                _StatTile('Deductions',
                    '-${formatCurrency(vm.totalDeductions)}',
                    Icons.remove_circle_outline, AppColors.danger),
                _StatTile('Net Salary', formatCurrency(vm.finalSalary),
                    Icons.account_balance_wallet_outlined,
                    AppColors.success),
                _StatTile('Bonus', formatCurrency(vm.bonusTotal),
                    Icons.star_outline, AppColors.warning),
              ],
            ),
            const SizedBox(height: 14),
            const _Label('DAILY BREAKDOWN'),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              EmptyState(message:
                  'No data for ${_monthNames[_month.month - 1]}')
            else
              ...entries.asMap().entries.map(
                  (e) => _BakerDailyCard(entry: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx, initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ), child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ── Baker Bonus ───────────────────────────────────────────────
class _BakerBonusTab extends StatefulWidget {
  final String userId;
  const _BakerBonusTab({required this.userId});
  @override
  State<_BakerBonusTab> createState() => _BakerBonusTabState();
}

class _BakerBonusTabState extends State<_BakerBonusTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final prefix  = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
    context.read<BakerSalaryViewModel>().loadMonthlyData(
        widget.userId,
        '$prefix-01',
        '$prefix-${lastDay.toString().padLeft(2, '0')}');
  }

  void _changeMonth(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm      = context.watch<BakerSalaryViewModel>();
    final entries = vm.dailyEntries;

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
            label: _monthLabel(_month),
            isCurrentMonth: _isCurrentMonth(_month),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onTap:  () => _pickMonth(context),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else if (entries.isEmpty)
            EmptyState(message:
                'No records for ${_monthNames[_month.month - 1]}')
          else ...[
            _BonusBanner(
                sacks: 0, value: vm.bonusTotal,
                isBakerBonus: true),
            const SizedBox(height: 14),
            const _Label('DAILY BONUS BREAKDOWN'),
            const SizedBox(height: 8),
            ...entries.where((e) => e.bonus > 0).map(
                (e) => _BakerBonusDayCard(entry: e)),
            if (entries.every((e) => e.bonus == 0))
              const EmptyState(message: 'No bonus this month'),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext ctx) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: ctx, initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _kOrange),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ), child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  PACKER TABS
// ══════════════════════════════════════════════════════════════

class _PackerDailyTab extends StatefulWidget {
  final String userId;
  const _PackerDailyTab({required this.userId});
  @override
  State<_PackerDailyTab> createState() => _PackerDailyTabState();
}

class _PackerDailyTabState extends State<_PackerDailyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<PackerSalaryViewModel>()
            .loadMonthly(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm      = context.watch<PackerSalaryViewModel>();
    final entries = vm.dailyEntries;

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<PackerSalaryViewModel>().loadMonthly(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _PackerMonthBar(userId: widget.userId),
          const SizedBox(height: 12),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<PackerSalaryViewModel>()
                    .loadMonthly(widget.userId))
          else if (entries.isEmpty)
            const EmptyState(message: 'No records for this month')
          else ...[
            _SummaryBar(items: [
              _SI(Icons.work_history_outlined, 'Days',
                  '${vm.daysWorked}', AppColors.packer),
              _SI(Icons.inventory_2_outlined, 'Bundles',
                  '${vm.totalBundles}', _kOrange),
              _SI(Icons.payments_outlined, 'Gross',
                  formatCurrency(vm.grossSalary), AppColors.success),
            ]),
            const SizedBox(height: 12),
            ...entries.asMap().entries.map(
                (e) => _PackerDayCard(entry: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }
}

class _PackerWeeklyTab extends StatefulWidget {
  final String userId;
  const _PackerWeeklyTab({required this.userId});
  @override
  State<_PackerWeeklyTab> createState() => _PackerWeeklyTabState();
}

class _PackerWeeklyTabState extends State<_PackerWeeklyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<PackerSalaryViewModel>().init(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<PackerSalaryViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<PackerSalaryViewModel>().init(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          WeekSelector(
            weekStart: vm.weekStart, weekEnd: vm.weekEnd,
            onPrev: () => context.read<PackerSalaryViewModel>()
                .changeWeek(-1, widget.userId),
            onNext: () => context.read<PackerSalaryViewModel>()
                .changeWeek(1, widget.userId),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<PackerSalaryViewModel>()
                    .init(widget.userId))
          else ...[
            Row(children: [
              Expanded(child: _StatChip(label: 'Bundles',
                  value: '${vm.totalBundles}', color: AppColors.packer)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Days',
                  value: '${vm.daysWorked}', color: _kOrange)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Net',
                  value: formatCurrency(vm.netSalary),
                  color: AppColors.success)),
            ]),
            const SizedBox(height: 12),
            _PackerDeductionsCard(vm: vm),
            const SizedBox(height: 12),
            if (vm.dailyEntries.isNotEmpty) ...[
              const _Label('DAILY BREAKDOWN'),
              const SizedBox(height: 8),
              ...vm.dailyEntries.map((e) =>
                  _DailyBreakdownRow(date: e.date, salary: e.salary)),
            ] else
              const EmptyState(message: 'No records for this week'),
          ],
        ]),
      ),
    );
  }
}

class _PackerMonthlyTab extends StatefulWidget {
  final String userId;
  const _PackerMonthlyTab({required this.userId});
  @override
  State<_PackerMonthlyTab> createState() => _PackerMonthlyTabState();
}

class _PackerMonthlyTabState extends State<_PackerMonthlyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<PackerSalaryViewModel>().loadMonthly(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<PackerSalaryViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<PackerSalaryViewModel>().loadMonthly(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _PackerMonthBar(userId: widget.userId),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<PackerSalaryViewModel>()
                    .loadMonthly(widget.userId))
          else ...[
            _MonthlyBanner(
              total: vm.grossSalary, days: vm.daysWorked,
              sacks: vm.totalBundles,
              weeks: vm.weeklySummaries.length,
              sacksLabel: 'Bundles',
            ),
            const SizedBox(height: 14),
            const _Label('WEEKLY BREAKDOWN'),
            const SizedBox(height: 8),
            if (vm.weeklySummaries.isEmpty)
              const EmptyState(message: 'No data this month')
            else
              ...vm.weeklySummaries.asMap().entries.map((e) =>
                  _PackerWeekRow(summary: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SELLER TABS
// ══════════════════════════════════════════════════════════════

class _SellerDailyTab extends StatefulWidget {
  final String userId;
  const _SellerDailyTab({required this.userId});
  @override
  State<_SellerDailyTab> createState() => _SellerDailyTabState();
}

class _SellerDailyTabState extends State<_SellerDailyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<SellerRemittanceViewModel>().init(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm   = context.watch<SellerRemittanceViewModel>();
    final list = vm.sortedRemittances;

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<SellerRemittanceViewModel>().init(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          WeekSelector(
            weekStart: vm.weekStart, weekEnd: vm.weekEnd,
            onPrev: () => context.read<SellerRemittanceViewModel>()
                .changeWeek(-1, widget.userId),
            onNext: () => context.read<SellerRemittanceViewModel>()
                .changeWeek(1, widget.userId),
          ),
          const SizedBox(height: 12),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<SellerRemittanceViewModel>()
                    .init(widget.userId))
          else if (list.isEmpty)
            const EmptyState(message: 'No remittances this week')
          else ...[
            _SummaryBar(items: [
              _SI(Icons.storefront_outlined, 'Days',
                  '${vm.daysRemitted}', AppColors.success),
              _SI(Icons.shopping_bag_outlined, 'Sold',
                  '${vm.totalPiecesSold}', _kOrange),
              _SI(Icons.payments_outlined, 'Total',
                  formatCurrency(vm.totalActualRemittance),
                  AppColors.primary),
            ]),
            const SizedBox(height: 12),
            ...list.map((r) => _SellerRemittanceCard(record: r)),
          ],
        ]),
      ),
    );
  }
}

class _SellerWeeklyTab extends StatefulWidget {
  final String userId;
  const _SellerWeeklyTab({required this.userId});
  @override
  State<_SellerWeeklyTab> createState() => _SellerWeeklyTabState();
}

class _SellerWeeklyTabState extends State<_SellerWeeklyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<SellerRemittanceViewModel>().init(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<SellerRemittanceViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<SellerRemittanceViewModel>().init(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          WeekSelector(
            weekStart: vm.weekStart, weekEnd: vm.weekEnd,
            onPrev: () => context.read<SellerRemittanceViewModel>()
                .changeWeek(-1, widget.userId),
            onNext: () => context.read<SellerRemittanceViewModel>()
                .changeWeek(1, widget.userId),
          ),
          const SizedBox(height: 14),
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<SellerRemittanceViewModel>()
                    .init(widget.userId))
          else ...[
            Row(children: [
              Expanded(child: _StatChip(label: 'Days',
                  value: '${vm.daysRemitted}', color: AppColors.success)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Sold',
                  value: '${vm.totalPiecesSold}', color: _kOrange)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Total',
                  value: formatCurrency(vm.totalActualRemittance),
                  color: AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            _SellerWeekSummaryCard(vm: vm),
            const SizedBox(height: 12),
            if (vm.sortedRemittances.isNotEmpty) ...[
              const _Label('DAILY REMITTANCES'),
              const SizedBox(height: 8),
              ...vm.sortedRemittances.map(
                  (r) => _SellerRemittanceCard(record: r)),
            ] else
              const EmptyState(message: 'No remittances this week'),
          ],
        ]),
      ),
    );
  }
}

class _SellerMonthlyTab extends StatefulWidget {
  final String userId;
  const _SellerMonthlyTab({required this.userId});
  @override
  State<_SellerMonthlyTab> createState() => _SellerMonthlyTabState();
}

class _SellerMonthlyTabState extends State<_SellerMonthlyTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<SellerRemittanceViewModel>()
            .loadMonthly(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← required
    final vm = context.watch<SellerRemittanceViewModel>();

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () async =>
          context.read<SellerRemittanceViewModel>()
              .loadMonthly(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (vm.isLoading) const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!,
                onRetry: () => context.read<SellerRemittanceViewModel>()
                    .loadMonthly(widget.userId))
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [_kOrange, _kOrange.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                const Text('TOTAL MONTHLY REMITTANCE',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(formatCurrency(vm.totalActualRemittance),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 34, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  _BChip(Icons.storefront_outlined,
                      '${vm.daysRemitted} days'),
                  const SizedBox(width: 14),
                  _BChip(Icons.shopping_bag_outlined,
                      '${vm.totalPiecesSold} sold'),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            const _Label('WEEKLY BREAKDOWN'),
            const SizedBox(height: 8),
            if (vm.weeklySummaries.isEmpty)
              const EmptyState(message: 'No data this period')
            else
              ...vm.weeklySummaries.asMap().entries.map((e) =>
                  _SellerWeekCard(summary: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ROLE-SPECIFIC CARDS
// ══════════════════════════════════════════════════════════════

class _DailyRecordCard extends StatelessWidget {
  final HelperDailyRecord record;
  final int index;
  const _DailyRecordCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                record.date.length >= 10
                    ? record.date.substring(8, 10) : '?',
                style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 16, color: _kOrange),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_fmtFullDate(record.date),
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 14, color: AppColors.text)),
                const SizedBox(height: 3),
                Text('${record.totalWorkers} workers · '
                    '${record.totalSacks} sacks',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              Text(formatCurrency(record.salary),
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Earned',
                    style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ]),
          ]),
        ),
      );
}

class _BakerDailyCard extends StatelessWidget {
  final BakerDailyEntry entry;
  final int             index;
  const _BakerDailyCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.masterBaker.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.date.length >= 10
                  ? entry.date.substring(8, 10) : '?',
              style: const TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 16, color: AppColors.masterBaker),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_fmtFullDate(entry.date),
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppColors.text)),
              const SizedBox(height: 3),
              Text('Incentive: ${formatCurrency(entry.bakerIncentive)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text(formatCurrency(entry.baseSalary),
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark)),
            if (entry.bonus > 0) ...[
              const SizedBox(height: 3),
              Text('+${formatCurrency(entry.bonus)}',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ],
          ]),
        ]),
      );
}

class _BakerBonusDayCard extends StatelessWidget {
  final BakerDailyEntry entry;
  const _BakerBonusDayCard({required this.entry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_outline,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(_fmtFullDate(entry.date),
                style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14, color: AppColors.text)),
          ),
          Text(formatCurrency(entry.bonus),
              style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.warning)),
        ]),
      );
}

class _PackerDayCard extends StatelessWidget {
  final PackerDailyEntry entry;
  final int              index;
  const _PackerDayCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.date.length >= 10
                  ? entry.date.substring(8, 10) : '?',
              style: const TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 16, color: AppColors.packer),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_fmtFullDate(entry.date),
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppColors.text)),
              Text('${entry.totalBundles} bundles',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ]),
          ),
          Text(formatCurrency(entry.salary),
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark)),
        ]),
      );
}

class _PackerWeekRow extends StatelessWidget {
  final PackerWeeklySummary summary;
  final int                 index;
  const _PackerWeekRow({required this.summary, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: summary.grossSalary > 0
                ? _kOrange.withValues(alpha: 0.20)
                : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('W${index + 1}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800, color: _kOrange)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${summary.weekStart} – ${summary.weekEnd}',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              Text('${summary.days} days · ${summary.bundles} bundles',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ]),
          ),
          Text(formatCurrency(summary.grossSalary),
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark)),
        ]),
      );
}

class _SellerRemittanceCard extends StatelessWidget {
  final dynamic record;
  const _SellerRemittanceCard({required this.record});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_fmtFullDate(record.date as String),
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppColors.text)),
              Text('${record.piecesSold} sold · '
                  '${record.returnPieces} returned',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text(formatCurrency(record.actualRemittance as double),
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark)),
            Text('Expected: ${formatCurrency(
                record.adjustedRemittance as double)}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
      );
}

class _SellerWeekSummaryCard extends StatelessWidget {
  final SellerRemittanceViewModel vm;
  const _SellerWeekSummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const _Label('WEEK SUMMARY'),
          const SizedBox(height: 12),
          _WRow('Total Sold',      '${vm.totalPiecesSold} pieces', null),
          _WRow('Actual Remittance',
              formatCurrency(vm.totalActualRemittance), null),
          _WRow('Adjusted Remittance',
              formatCurrency(vm.totalAdjustedRemittance), null),
          _WRow('Total Returns',   '${vm.totalReturns} pieces', null),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            const Text('Variance',
                style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text(
              vm.totalVariance >= 0
                  ? '+${formatCurrency(vm.totalVariance)}'
                  : formatCurrency(vm.totalVariance),
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16,
                  color: vm.totalVariance >= 0
                      ? AppColors.success : AppColors.danger),
            ),
          ]),
        ]),
      );
}

class _SellerWeekCard extends StatelessWidget {
  final dynamic summary;
  final int     index;
  const _SellerWeekCard({required this.summary, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('W${index + 1}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800, color: _kOrange)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${summary.weekStart} – ${summary.weekEnd}',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              Text('${summary.days} days · '
                  '${summary.piecesSold} sold',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ]),
          ),
          Text(formatCurrency(summary.totalRemittance as double),
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  DEDUCTION CARDS
// ══════════════════════════════════════════════════════════════

class _HelperDeductionsCard extends StatelessWidget {
  final HelperSalaryViewModel vm;
  final bool isHelper;
  const _HelperDeductionsCard(
      {required this.vm, required this.isHelper});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const _Label('DEDUCTIONS'),
          const SizedBox(height: 12),
          if (isHelper)
            _DedRow(
              'Oven (₱${AppConstants.helperOvenDeductionPerDay
                  .toStringAsFixed(0)}/day × ${vm.daysWorked}d)',
              vm.ovenDeduction,
            ),
          _DedRow('Gas',  vm.gasDeduction),
          _DedRow('Vale', vm.valeDeduction),
          _DedRow('Wifi', vm.wifiDeduction),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            const Text('Take-Home Pay',
                style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text(formatCurrency(vm.finalSalary),
                style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 18, color: AppColors.primaryDark)),
          ]),
        ]),
      );
}

class _BakerDeductionsCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _BakerDeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const _Label('DEDUCTIONS'),
          const SizedBox(height: 12),
          _DedRow('Gas',  vm.gasDeduction),
          _DedRow('Vale', vm.valeDeduction),
          _DedRow('Wifi', vm.wifiDeduction),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            const Text('Take-Home Pay',
                style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text(formatCurrency(vm.finalSalary),
                style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 18, color: AppColors.primaryDark)),
          ]),
        ]),
      );
}

class _PackerDeductionsCard extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _PackerDeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const _Label('DEDUCTIONS'),
          const SizedBox(height: 12),
          _DedRow('Vale', vm.valeDeduction),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            const Text('Take-Home Pay',
                style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text(formatCurrency(vm.netSalary),
                style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 18, color: AppColors.primaryDark)),
          ]),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  PACKER MONTH BAR
// ══════════════════════════════════════════════════════════════
class _PackerMonthBar extends StatelessWidget {
  final String userId;
  const _PackerMonthBar({required this.userId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PackerSalaryViewModel>();
    return _MonthBar(
      label: vm.monthDisplay,
      isCurrentMonth: vm.isCurrentMonth,
      onPrev: () => context.read<PackerSalaryViewModel>()
          .changeMonth(-1, userId),
      onNext: () => context.read<PackerSalaryViewModel>()
          .changeMonth(1, userId),
      onTap: () async {
        final now    = DateTime.now();
        final picked = await showDatePicker(
          context: context, initialDate: now,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 1, 12),
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.light(primary: _kOrange),
              dialogTheme: const DialogThemeData(
                  backgroundColor: Colors.white),
            ), child: child!,
          ),
        );
        if (picked != null && context.mounted) {
          context.read<PackerSalaryViewModel>()
              .goToDate(picked, userId);
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED WIDGETS — orange-themed
// ══════════════════════════════════════════════════════════════

class _MonthlyBanner extends StatelessWidget {
  final double total;
  final int    days, sacks, weeks;
  final String sacksLabel;
  final bool   showBonusInstead;
  final String bonusLabel;

  const _MonthlyBanner({
    required this.total, required this.days,
    required this.sacks, required this.weeks,
    this.sacksLabel = 'sacks',
    this.showBonusInstead = false,
    this.bonusLabel = '',
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_kOrange, _kOrange.withValues(alpha: 0.80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: _kOrange.withValues(alpha: 0.30),
                blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(children: [
          const Text('TOTAL MONTHLY EARNINGS',
              style: TextStyle(color: Colors.white70, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(formatCurrency(total),
                style: const TextStyle(color: Colors.white,
                    fontSize: 34, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            _BChip(Icons.work_history_outlined, '$days days'),
            const SizedBox(width: 14),
            if (showBonusInstead)
              _BChip(Icons.star_outline, 'Bonus: $bonusLabel')
            else
              _BChip(Icons.inventory_2_outlined, '$sacks $sacksLabel'),
            if (!showBonusInstead && weeks > 0) ...[
              const SizedBox(width: 14),
              _BChip(Icons.calendar_view_week_outlined,
                  '$weeks weeks'),
            ],
          ]),
        ]),
      );
}

class _BonusBanner extends StatelessWidget {
  final int    sacks;
  final double value;
  final bool   isBakerBonus;
  const _BonusBanner({
    required this.sacks, required this.value,
    this.isBakerBonus = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.purple.withValues(alpha: 0.85),
                AppColors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(children: [
          Text(isBakerBonus
                  ? 'BAKER BONUS OVERVIEW'
                  : 'SACK BONUS OVERVIEW',
              style: const TextStyle(color: Colors.white70,
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              isBakerBonus ? formatCurrency(value) : '$sacks sacks',
              style: const TextStyle(color: Colors.white,
                  fontSize: 34, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBakerBonus
                ? 'Total baker bonus this month'
                : 'Total value: ${formatCurrency(value)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ]),
      );
}

// ── Month pill bar ─────────────────────────────────────────────
class _MonthBar extends StatelessWidget {
  final String label;
  final bool   isCurrentMonth;
  final VoidCallback onPrev, onNext, onTap;
  const _MonthBar({
    required this.label, required this.isCurrentMonth,
    required this.onPrev, required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _kOrange.withValues(alpha: 0.25), width: 1.4),
          boxShadow: [
            BoxShadow(color: _kOrange.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          // ◀ prev
          InkWell(onTap: onPrev, borderRadius: BorderRadius.circular(14),
            child: const SizedBox(width: 44, height: 44,
              child: Icon(Icons.chevron_left_rounded,
                  size: 20, color: _kOrange)),
          ),
          Container(width: 1, height: 24,
              color: _kOrange.withValues(alpha: 0.15)),
          // centre
          Expanded(
            child: GestureDetector(
              onTap: onTap, behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 15,
                        color: _kOrange.withValues(alpha: 0.80)),
                    const SizedBox(width: 7),
                    if (isCurrentMonth) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('THIS MONTH',
                            style: TextStyle(fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: _kOrange, letterSpacing: 0.4)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primaryDark)),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more_rounded, size: 16,
                        color: _kOrange.withValues(alpha: 0.60)),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 24,
              color: _kOrange.withValues(alpha: 0.15)),
          // ▶ next
          InkWell(onTap: onNext, borderRadius: BorderRadius.circular(14),
            child: const SizedBox(width: 44, height: 44,
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: _kOrange)),
          ),
        ]),
      );
}

class _SummaryBar extends StatelessWidget {
  final List<_SI> items;
  const _SummaryBar({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _kOrange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _kOrange.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((i) => Column(children: [
            Icon(i.icon, size: 18, color: i.color),
            const SizedBox(height: 4),
            Text(i.value, style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14, color: AppColors.text)),
            Text(i.label, style: const TextStyle(
                fontSize: 11, color: AppColors.textHint)),
          ])).toList(),
        ),
      );
}

class _SI {
  final IconData icon;
  final String label, value;
  final Color color;
  const _SI(this.icon, this.label, this.value, this.color);
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15, color: color)),
          ),
          Text(label, style: const TextStyle(
              fontSize: 10, color: AppColors.textHint)),
        ]),
      );
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color    color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: color)),
          ),
          Text(label, style: const TextStyle(
              fontSize: 10, color: AppColors.textHint)),
        ]),
      );
}

class _WeekTile extends StatelessWidget {
  final WeeklySummary week;
  final int   index;
  final Color color;
  const _WeekTile(
      {required this.week, required this.index, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('W${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.w900,
                      color: color, fontSize: 14)),
            ),
            title: Text(week.label, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(
              '${week.daysWorked} days · ${week.totalSacks} sacks',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
            trailing: Text(formatCurrency(week.finalSalary),
                style: TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 16, color: color)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(children: [
                  const Divider(),
                  _WRow('Gross', formatCurrency(week.grossSalary), null),
                  _WRow('Oven',
                      '-${formatCurrency(week.ovenDeduction)}',
                      AppColors.danger),
                  _WRow('Gas',
                      '-${formatCurrency(week.gasDeduction)}',
                      AppColors.danger),
                  _WRow('Vale',
                      '-${formatCurrency(week.vale)}',
                      AppColors.danger),
                  _WRow('Wifi',
                      '-${formatCurrency(week.wifi)}',
                      AppColors.danger),
                  const Divider(),
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('Net Salary',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(formatCurrency(week.finalSalary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primaryDark)),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      );
}

class _DailyBreakdownRow extends StatelessWidget {
  final String date;
  final double salary;
  const _DailyBreakdownRow(
      {required this.date, required this.salary});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.today_outlined,
                color: _kOrange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_fmtFullDate(date),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14))),
          Text(formatCurrency(salary),
              style: const TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 15, color: _kOrange)),
        ]),
      );
}

class _BonusCard extends StatelessWidget {
  final HelperDailyRecord record;
  final int index;
  const _BonusCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.purple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_fmtFullDate(record.date),
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 15, color: AppColors.text)),
              Text('${record.totalWorkers} workers',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text('${record.totalSacks} sacks',
                style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple)),
            Text(formatCurrency(record.totalValue),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ]),
        ]),
      );
}

class _DedRow extends StatelessWidget {
  final String label;
  final double value;
  const _DedRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Flexible(child: Text(label,
              style: const TextStyle(fontSize: 13,
                  color: AppColors.textSecondary))),
          Text(
            value > 0 ? '-${formatCurrency(value)}' : '—',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: value > 0
                    ? AppColors.danger : AppColors.textHint),
          ),
        ]),
      );
}

class _WRow extends StatelessWidget {
  final String  label, value;
  final Color?  valueColor;
  const _WRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(label, style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600,
              fontSize: 13, color: valueColor ?? AppColors.text)),
        ]),
      );
}

class _BChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _BChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 12)),
      ]);
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint, letterSpacing: 0.8));
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: _kOrange, strokeWidth: 2.5),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined,
              size: 36, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ]),
      );
}

// ── Pure helpers ──────────────────────────────────────────────
const _monthNames = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December',
];

String _monthLabel(DateTime d) =>
    '${_monthNames[d.month - 1]} ${d.year}';

bool _isCurrentMonth(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month;
}

String _fmtFullDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${_monthNames[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return iso;
  }
}