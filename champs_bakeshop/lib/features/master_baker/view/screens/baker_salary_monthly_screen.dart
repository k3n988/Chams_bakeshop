part of 'baker_salary_screen.dart';

// ══════════════════════════════════════════════════════════════
//  MONTHLY TAB
// ══════════════════════════════════════════════════════════════
class _MonthlyTab extends StatefulWidget {
  @override
  State<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<_MonthlyTab> {
  // Default: current month
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  String get _monthStart =>
      '${_selectedMonth.year}-'
      '${_selectedMonth.month.toString().padLeft(2, '0')}-01';

  String get _monthEnd {
    final lastDay = DateTime(
        _selectedMonth.year, _selectedMonth.month + 1, 0);
    return '${lastDay.year}-'
        '${lastDay.month.toString().padLeft(2, '0')}-'
        '${lastDay.day.toString().padLeft(2, '0')}';
  }

  String get _monthLabel {
    const names = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${names[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _goMonth(int dir) {
    setState(() => _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + dir));
    _load();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: 'Select Month',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.masterBaker,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _selectedMonth = DateTime(picked.year, picked.month));
      _load();
    }
  }

  Future<void> _load() async {
    final userId =
        context.read<AuthViewModel>().currentUser!.id;
    await context
        .read<BakerSalaryViewModel>()
        .loadMonthlyData(userId, _monthStart, _monthEnd);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    // Group dailyEntries by week
    final weeks = _groupByWeek(vm.dailyEntries);
    final avgPerWeek =
        weeks.isNotEmpty ? vm.grossSalary / weeks.length : 0.0;

    return RefreshIndicator(
      color: AppColors.masterBaker,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Page header ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Summary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Earnings overview per month',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
                if (!_isCurrentMonth)
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      setState(() => _selectedMonth =
                          DateTime(now.year, now.month));
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.masterBaker
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.masterBaker
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 13,
                                color: AppColors.masterBaker),
                            SizedBox(width: 5),
                            Text('This Month',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.masterBaker)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Month navigator ────────────────────────────
            _MonthNavigator(
              label: _monthLabel,
              isCurrentMonth: _isCurrentMonth,
              onPrev: () => _goMonth(-1),
              onNext: _isCurrentMonth ? null : () => _goMonth(1),
              onTap: _pickMonth,
            ),
            const SizedBox(height: 16),

            // ── Content ────────────────────────────────────
            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else if (vm.dailyEntries.isEmpty)
              _NoMonthRecord(monthLabel: _monthLabel)
            else ...[
              _MonthlyHeroCard(
                total: vm.grossSalary,
                daysWorked: vm.daysWorked,
                monthLabel: _monthLabel,
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  _GridStat(
                      icon: Icons.wallet_outlined,
                      label: 'Gross',
                      value: formatCurrency(vm.grossSalary),
                      color: AppColors.success),
                  _GridStat(
                      icon: Icons.remove_circle_outline,
                      label: 'Deductions',
                      value: vm.totalDeductions > 0
                          ? '-${formatCurrency(vm.totalDeductions)}'
                          : '₱0.00',
                      color: AppColors.danger),
                  _GridStat(
                      icon: Icons.price_check,
                      label: 'Net Salary',
                      value: formatCurrency(vm.finalSalary),
                      color: AppColors.masterBaker),
                  _GridStat(
                      icon: Icons.trending_up_outlined,
                      label: 'Avg/Week',
                      value: formatCurrency(avgPerWeek),
                      color: const Color(0xFF1976D2)),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionLabel('WEEKLY BREAKDOWN'),
              const SizedBox(height: 12),
              ...weeks.asMap().entries.map((e) => _WeekCard(
                    weekNum: e.key + 1,
                    entries: e.value,
                    totalWeeks: weeks.length,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  /// Groups daily entries into weeks (Mon–Sun buckets)
  List<List<BakerDailyEntry>> _groupByWeek(
      List<BakerDailyEntry> entries) {
    if (entries.isEmpty) return [];

    final sorted = [...entries]
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<List<BakerDailyEntry>> weeks = [];
    List<BakerDailyEntry> currentWeek = [];

    DateTime? weekStart;
    for (final entry in sorted) {
      final date = DateTime.parse(entry.date);
      if (weekStart == null) {
        weekStart = date.subtract(
            Duration(days: date.weekday - 1)); // Monday
        currentWeek.add(entry);
      } else {
        final weekEnd =
            weekStart.add(const Duration(days: 6)); // Sunday
        if (!date.isAfter(weekEnd)) {
          currentWeek.add(entry);
        } else {
          weeks.add(currentWeek);
          currentWeek = [entry];
          weekStart = date.subtract(
              Duration(days: date.weekday - 1));
        }
      }
    }
    if (currentWeek.isNotEmpty) weeks.add(currentWeek);
    return weeks;
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _MonthNavigator extends StatelessWidget {
  final String label;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTap;

  const _MonthNavigator({
    required this.label,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(children: [
        // Prev
        _MNavBtn(icon: Icons.chevron_left, onTap: onPrev),

        // Center
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: isCurrentMonth
                        ? AppColors.masterBaker
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isCurrentMonth
                            ? AppColors.masterBaker
                            : AppColors.text,
                        letterSpacing: -0.2),
                  ),
                  if (isCurrentMonth) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.masterBaker,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('THIS MONTH',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        ),

        // Next (disabled on current month)
        _MNavBtn(
          icon: Icons.chevron_right,
          onTap: onNext,
          disabled: onNext == null,
        ),
      ]),
    );
  }
}

class _MNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  const _MNavBtn(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Icon(
            icon,
            size: 20,
            color: disabled
                ? AppColors.border
                : AppColors.masterBaker,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  MONTHLY HERO CARD
// ─────────────────────────────────────────────────────────────
class _MonthlyHeroCard extends StatelessWidget {
  final double total;
  final int daysWorked;
  final String monthLabel;
  const _MonthlyHeroCard({
    required this.total,
    required this.daysWorked,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5A8F3E), Color(0xFF7DB85C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A8F3E).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(children: [
          Text(monthLabel.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('TOTAL EARNINGS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Text(
            formatCurrency(total),
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.8),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text('$daysWorked days worked',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  GRID STAT
// ─────────────────────────────────────────────────────────────
class _GridStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _GridStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  WEEK CARD (real data grouped by week)
// ─────────────────────────────────────────────────────────────
class _WeekCard extends StatefulWidget {
  final int weekNum;
  final List<BakerDailyEntry> entries;
  final int totalWeeks;
  const _WeekCard({
    required this.weekNum,
    required this.entries,
    required this.totalWeeks,
  });

  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  bool _expanded = false;

  String get _weekRange {
    if (widget.entries.isEmpty) return '—';
    final dates =
        widget.entries.map((e) => DateTime.parse(e.date)).toList()
          ..sort();
    final start = dates.first;
    final end = dates.last;
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (start.month == end.month) {
      return '${m[start.month - 1]} ${start.day}–${end.day}';
    }
    return '${m[start.month - 1]} ${start.day} – ${m[end.month - 1]} ${end.day}';
  }

  double get _weekTotal =>
      widget.entries.fold(0.0, (s, e) => s + e.baseSalary);

  bool get _isLatestWeek => widget.weekNum == widget.totalWeeks;

  @override
  void initState() {
    super.initState();
    // Auto-expand the latest week
    _expanded = _isLatestWeek;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLatestWeek
              ? AppColors.masterBaker.withValues(alpha: 0.25)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // ── Week header (tappable) ───────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(16),
            bottom: _expanded
                ? Radius.zero
                : const Radius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Week badge
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _isLatestWeek
                      ? AppColors.masterBaker
                          .withValues(alpha: 0.10)
                      : const Color(0xFFF3F0EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('W${widget.weekNum}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isLatestWeek
                            ? AppColors.masterBaker
                            : AppColors.textHint)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_weekRange,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      if (_isLatestWeek) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.masterBaker,
                            borderRadius:
                                BorderRadius.circular(5),
                          ),
                          child: const Text('LATEST',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.entries.length} day${widget.entries.length > 1 ? 's' : ''} worked',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              // Total + expand icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(_weekTotal),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _weekTotal > 0
                            ? AppColors.primaryDark
                            : AppColors.textHint),
                  ),
                  const SizedBox(height: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration:
                        const Duration(milliseconds: 200),
                    child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textHint),
                  ),
                ],
              ),
            ]),
          ),
        ),

        // ── Expanded daily entries ───────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            const Divider(height: 1, color: AppColors.border),
            ...widget.entries.map((entry) => _DayRow(
                  entry: entry,
                  isLast: entry == widget.entries.last,
                )),
          ]),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DAY ROW (inside expanded week)
// ─────────────────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final BakerDailyEntry entry;
  final bool isLast;
  const _DayRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: isLast
            ? const BorderRadius.vertical(
                bottom: Radius.circular(16))
            : BorderRadius.zero,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        // Date dot
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppColors.masterBaker.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        // Date
        Text(entry.date,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        // Breakdown
        Expanded(
          child: Text(
            entry.bakerIncentive > 0
                ? '${formatCurrency(entry.baseOnly)} + ${formatCurrency(entry.bakerIncentive)} incentive'
                : 'Base only',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Amount
        Text(
          formatCurrency(entry.baseSalary),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _NoMonthRecord extends StatelessWidget {
  final String monthLabel;
  const _NoMonthRecord({required this.monthLabel});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.masterBaker.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined,
                size: 36, color: AppColors.masterBaker),
          ),
          const SizedBox(height: 14),
          Text('No data for $monthLabel',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('No productions were recorded this month',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}