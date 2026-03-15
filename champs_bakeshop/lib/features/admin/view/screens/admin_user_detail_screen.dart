import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../helper/viewmodel/helper_salary_viewmodel.dart';

// ─────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────
class AdminUserDetailScreen extends StatelessWidget {
  final UserModel user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final db      = context.read<SupabaseService>(); // ✅ SupabaseService
    final payroll = context.read<PayrollService>();

    return ChangeNotifierProvider(
      create: (_) => HelperSalaryViewModel(db, payroll),
      child: _UserDetailShell(user: user),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHELL with TabBar
// ─────────────────────────────────────────────────────────
class _UserDetailShell extends StatelessWidget {
  final UserModel user;
  const _UserDetailShell({required this.user});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      Tab(icon: Icon(Icons.today_outlined),         text: 'Daily'),
      Tab(icon: Icon(Icons.date_range_outlined),     text: 'Weekly'),
      Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Monthly'),
      Tab(icon: Icon(Icons.inventory_2_outlined),    text: 'Bonus'),
    ];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.primaryDark)),
              Text(user.roleDisplay,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            tabs: tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
          ),
        ),
        body: TabBarView(
          children: [
            _AdminDailyTab(userId: user.id),
            _AdminWeeklyTab(userId: user.id, isHelper: user.isHelper),
            _AdminMonthlyTab(userId: user.id),
            _AdminBonusTab(userId: user.id),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 1 — DAILY
// ─────────────────────────────────────────────────────────
class _AdminDailyTab extends StatefulWidget {
  final String userId;
  const _AdminDailyTab({required this.userId});

  @override
  State<_AdminDailyTab> createState() => _AdminDailyTabState();
}

class _AdminDailyTabState extends State<_AdminDailyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<HelperSalaryViewModel>().loadDailyRecordsForMonth(
        widget.userId, _month.year, _month.month);
  }

  void _changeMonth(int dir) {
    setState(
        () => _month = DateTime(_month.year, _month.month + dir));
    _load();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm         = context.watch<HelperSalaryViewModel>();
    final monthLabel =
        '${_monthNames[_month.month - 1]} ${_month.year}';
    final records    = vm.dailyRecords;
    final total      = records.fold(0.0, (s, r) => s + r.salary);
    final totalSacks = records.fold(0,   (s, r) => s + r.totalSacks);

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
              label: monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap: _pickMonth),
          const SizedBox(height: 12),

          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else if (records.isEmpty)
            EmptyState(
                message:
                    'No records for ${_monthNames[_month.month - 1]}')
          else ...[
            _SummaryBar(items: [
              _SummaryItem(Icons.work_history_outlined, 'Days',
                  '${records.length}', AppColors.info),
              _SummaryItem(Icons.inventory_2_outlined, 'Sacks',
                  '$totalSacks', AppColors.primary),
              _SummaryItem(Icons.payments_outlined, 'Total',
                  formatCurrency(total), AppColors.success),
            ]),
            const SizedBox(height: 12),
            ...records.asMap().entries.map(
                (e) => _DailyCard(record: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 2 — WEEKLY
// ─────────────────────────────────────────────────────────
class _AdminWeeklyTab extends StatefulWidget {
  final String userId;
  final bool   isHelper;
  const _AdminWeeklyTab(
      {required this.userId, required this.isHelper});

  @override
  State<_AdminWeeklyTab> createState() => _AdminWeeklyTabState();
}

class _AdminWeeklyTabState extends State<_AdminWeeklyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<HelperSalaryViewModel>().loadWeeklySalaryForMonth(
        widget.userId, _month.year, _month.month);
  }

  void _changeMonth(int dir) {
    setState(
        () => _month = DateTime(_month.year, _month.month + dir));
    _load();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm         = context.watch<HelperSalaryViewModel>();
    final monthLabel =
        '${_monthNames[_month.month - 1]} ${_month.year}';

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
              label: monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap: _pickMonth),
          const SizedBox(height: 10),
          WeekSelector(
            weekStart: vm.weekStart,
            weekEnd: vm.weekEnd,
            onPrev: () => context
                .read<HelperSalaryViewModel>()
                .changeWeek(-1, widget.userId),
            onNext: () => context
                .read<HelperSalaryViewModel>()
                .changeWeek(1, widget.userId),
          ),
          const SizedBox(height: 14),

          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else ...[
            Row(children: [
              Expanded(
                  child: _StatChip(
                      label: 'Gross',
                      value: formatCurrency(vm.grossSalary),
                      color: AppColors.masterBaker)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Days',
                      value: '${vm.daysWorked}',
                      color: AppColors.info)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Net',
                      value: formatCurrency(vm.finalSalary),
                      color: AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            _DeductionsCard(vm: vm, isHelper: widget.isHelper),
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
}

// ─────────────────────────────────────────────────────────
//  TAB 3 — MONTHLY
// ─────────────────────────────────────────────────────────
class _AdminMonthlyTab extends StatefulWidget {
  final String userId;
  const _AdminMonthlyTab({required this.userId});

  @override
  State<_AdminMonthlyTab> createState() => _AdminMonthlyTabState();
}

class _AdminMonthlyTabState extends State<_AdminMonthlyTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  static const _weekColors = [
    AppColors.info,
    AppColors.primary,
    AppColors.masterBaker,
    AppColors.purple,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<HelperSalaryViewModel>().loadMonthlySummary(
        widget.userId,
        year: _month.year,
        month: _month.month);
  }

  void _changeMonth(int dir) {
    setState(
        () => _month = DateTime(_month.year, _month.month + dir));
    _load();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm         = context.watch<HelperSalaryViewModel>();
    final monthLabel =
        '${_monthNames[_month.month - 1]} ${_month.year}';

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
              label: monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap: _pickMonth),
          const SizedBox(height: 14),

          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else ...[
            // Total banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                const Text('TOTAL MONTHLY EARNINGS',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    formatCurrency(vm.monthlyTotalSalary),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BChip(Icons.work_history_outlined,
                          '${vm.monthlyTotalDays} days'),
                      const SizedBox(width: 14),
                      _BChip(Icons.inventory_2_outlined,
                          '${vm.monthlyTotalSacks} sacks'),
                      const SizedBox(width: 14),
                      _BChip(Icons.calendar_view_week_outlined,
                          '${vm.monthlyWeeks.length} weeks'),
                    ]),
              ]),
            ),
            const SizedBox(height: 14),

            // 2×2 stat grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _StatTile('Gross',
                    formatCurrency(vm.monthlyGrossSalary),
                    Icons.payments_outlined,
                    AppColors.masterBaker),
                _StatTile(
                    'Deductions',
                    '-${formatCurrency(vm.monthlyTotalDeductions)}',
                    Icons.remove_circle_outline,
                    AppColors.danger),
                _StatTile('Net Salary',
                    formatCurrency(vm.monthlyTotalSalary),
                    Icons.account_balance_wallet_outlined,
                    AppColors.success),
                _StatTile('Avg/Week',
                    formatCurrency(vm.monthlyAvgPerWeek),
                    Icons.trending_up_outlined,
                    AppColors.info),
              ],
            ),
            const SizedBox(height: 14),

            const _Label('WEEKLY BREAKDOWN'),
            const SizedBox(height: 8),
            if (vm.monthlyWeeks.isEmpty)
              EmptyState(
                  message:
                      'No data for ${_monthNames[_month.month - 1]}')
            else
              ...vm.monthlyWeeks.asMap().entries.map((e) => _WeekTile(
                    week: e.value,
                    index: e.key,
                    color: _weekColors[e.key % _weekColors.length],
                  )),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 4 — BONUS
// ─────────────────────────────────────────────────────────
class _AdminBonusTab extends StatefulWidget {
  final String userId;
  const _AdminBonusTab({required this.userId});

  @override
  State<_AdminBonusTab> createState() => _AdminBonusTabState();
}

class _AdminBonusTabState extends State<_AdminBonusTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<HelperSalaryViewModel>().loadDailyRecordsForMonth(
        widget.userId, _month.year, _month.month);
  }

  void _changeMonth(int dir) {
    setState(
        () => _month = DateTime(_month.year, _month.month + dir));
    _load();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm         = context.watch<HelperSalaryViewModel>();
    final monthLabel =
        '${_monthNames[_month.month - 1]} ${_month.year}';
    final records    = vm.dailyRecords;
    final totalSacks = records.fold(0,   (s, r) => s + r.totalSacks);
    final totalValue = records.fold(0.0, (s, r) => s + r.totalValue);

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _MonthBar(
              label: monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap: _pickMonth),
          const SizedBox(height: 14),

          if (vm.isLoading)
            const _Loader()
          else if (vm.error != null)
            _ErrorCard(message: vm.error!, onRetry: _load)
          else if (records.isEmpty)
            EmptyState(
                message:
                    'No records for ${_monthNames[_month.month - 1]}')
          else ...[
            // Bonus banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.purple.withValues(alpha: 0.85),
                    AppColors.purple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                const Text('SACK BONUS OVERVIEW',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    '$totalSacks sacks',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total value: ${formatCurrency(totalValue)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bonus is paid separately — not included in payroll',
                  style: TextStyle(
                      color: Colors.white60, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(height: 14),

            const _Label('DAILY SACK BREAKDOWN'),
            const SizedBox(height: 8),
            ...records.asMap().entries.map((e) =>
                _BonusCard(record: e.value, index: e.key)),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrev, onNext, onTap;
  const _MonthBar(
      {required this.label,
      required this.onPrev,
      required this.onNext,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.info.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              color: AppColors.info,
              onPressed: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.info)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: AppColors.info),
                ],
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              color: AppColors.info,
              onPressed: onNext),
        ]),
      );
}

class _SummaryBar extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryBar({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.info.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items
              .map((i) => Column(children: [
                    Icon(i.icon, size: 18, color: i.color),
                    const SizedBox(height: 4),
                    Text(i.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.text)),
                    Text(i.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint)),
                  ]))
              .toList(),
        ),
      );
}

class _SummaryItem {
  final IconData icon;
  final String label, value;
  final Color color;
  const _SummaryItem(this.icon, this.label, this.value, this.color);
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: color)),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
            ]),
      );
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
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
                child: Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
            ]),
      );
}

class _DeductionsCard extends StatelessWidget {
  final HelperSalaryViewModel vm;
  final bool isHelper;
  const _DeductionsCard(
      {required this.vm, required this.isHelper});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('DEDUCTIONS'),
              const SizedBox(height: 12),
              if (isHelper)
                _DedRow(
                  'Oven (₱${AppConstants.helperOvenDeductionPerDay.toStringAsFixed(0)}/day × ${vm.daysWorked}d)',
                  vm.ovenDeduction,
                ),
              _DedRow('Gas',  vm.gasDeduction),
              _DedRow('Vale', vm.valeDeduction),
              _DedRow('Wifi', vm.wifiDeduction),
              const Divider(height: 20),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Take-Home Pay',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(formatCurrency(vm.finalSalary),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.primaryDark)),
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
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ),
              Text(
                value > 0 ? '-${formatCurrency(value)}' : '—',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: value > 0
                        ? AppColors.danger
                        : AppColors.textHint),
              ),
            ]),
      );
}

class _WeekTile extends StatelessWidget {
  final WeeklySummary week;
  final int index;
  final Color color;
  const _WeekTile(
      {required this.week,
      required this.index,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('W${index + 1}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 14)),
            ),
            title: Text(week.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(
              '${week.daysWorked} days · ${week.totalSacks} sacks',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
            trailing: Text(formatCurrency(week.finalSalary),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: color)),
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(children: [
                  const Divider(),
                  _WRow('Gross Salary',
                      formatCurrency(week.grossSalary), null),
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

class _WRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _WRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: valueColor ?? AppColors.text)),
            ]),
      );
}

class _DailyCard extends StatelessWidget {
  final HelperDailyRecord record;
  final int index;
  const _DailyCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.info, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(
                      '${record.totalWorkers} workers · ${record.totalSacks} sacks',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint),
                    ),
                    Text(
                      'Batch total: ${formatCurrency(record.totalValue)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              Text(formatCurrency(record.salary),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Earned',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ]),
          ]),
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
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.today_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(date,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14))),
          Text(formatCurrency(salary),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary)),
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
              color: AppColors.purple.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
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
                  Text(record.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.text)),
                  Text(
                    '${record.totalWorkers} workers',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text('${record.totalSacks} sacks',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple)),
            Text(formatCurrency(record.totalValue),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ]),
        ]),
      );
}

class _BChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ]);
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint,
          letterSpacing: 0.8));
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.info, strokeWidth: 2.5)),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
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
          Text(message,
              textAlign: TextAlign.center,
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