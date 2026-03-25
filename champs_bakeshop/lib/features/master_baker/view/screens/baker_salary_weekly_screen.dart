part of 'baker_salary_screen.dart';

// ══════════════════════════════════════════════════════════════
//  WEEKLY TAB
// ══════════════════════════════════════════════════════════════
class _WeeklyTab extends StatefulWidget {
  final Future<void> Function(int) onChangeWeek;
  const _WeeklyTab({required this.onChangeWeek});

  @override
  State<_WeeklyTab> createState() => _WeeklyTabState();
}

class _WeeklyTabState extends State<_WeeklyTab> {
  // Month filter — null means "show all / no filter"
  DateTime? _filterMonth;

  bool get _isCurrentWeek {
    final vm = context.read<BakerSalaryViewModel>();
    final currentWeekStart = getWeekStart(DateTime.now());
    return vm.weekStart == currentWeekStart;
  }

  Future<void> _pickMonth() async {
    // Simple month picker using showDatePicker limited to day=1
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterMonth ?? now,
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
          _filterMonth = DateTime(picked.year, picked.month));
    }
  }

  void _clearMonthFilter() => setState(() => _filterMonth = null);

  void _goToCurrentWeek() {
    final vm = context.read<BakerSalaryViewModel>();
    // Navigate forward/backward until we reach current week
    final currentWeekStart = getWeekStart(DateTime.now());
    if (vm.weekStart == currentWeekStart) return;
    final diff = DateTime.parse(currentWeekStart)
            .difference(DateTime.parse(vm.weekStart))
            .inDays ~/
        7;
    widget.onChangeWeek(diff);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();
    final isThisWeek = _isCurrentWeek;

    // Check if current week matches the month filter
    final weekMatchesFilter = _filterMonth == null ||
        (DateTime.tryParse(vm.weekStart)?.month == _filterMonth!.month &&
            DateTime.tryParse(vm.weekStart)?.year == _filterMonth!.year);

    return RefreshIndicator(
      color: AppColors.masterBaker,
      onRefresh: () async {
        final uid = context.read<AuthViewModel>().currentUser!.id;
        await context.read<BakerSalaryViewModel>().init(uid);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Page header ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Salary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Summary for your selected week',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
                // This week shortcut
                if (!isThisWeek)
                  GestureDetector(
                    onTap: _goToCurrentWeek,
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
                            Text('This Week',
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

            // ── Month filter bar ─────────────────────────────
            _MonthFilterBar(
              selectedMonth: _filterMonth,
              onPick: _pickMonth,
              onClear: _clearMonthFilter,
            ),
            const SizedBox(height: 10),

            // ── Week navigator ───────────────────────────────
            _WeekNavigator(
              weekStart: vm.weekStart,
              weekEnd: vm.weekEnd,
              isCurrentWeek: isThisWeek,
              onPrev: () => widget.onChangeWeek(-1),
              onNext: isThisWeek ? null : () => widget.onChangeWeek(1),
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────
            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else if (!weekMatchesFilter)
              _WeekOutsideFilter(
                month: _filterMonth!,
                onClear: _clearMonthFilter,
              )
            else ...[
              _WeeklyStatRow(vm: vm),
              const SizedBox(height: 14),
              _DeductionsCard(vm: vm),
              const SizedBox(height: 14),
              _TakeHomeCard(vm: vm),
              const SizedBox(height: 20),
              const _SectionLabel('DAILY BREAKDOWN'),
              const SizedBox(height: 10),
              if (vm.dailyEntries.isEmpty)
                _EmptyCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No records for this week',
                )
              else
                ...vm.dailyEntries.asMap().entries.map((e) =>
                    _WeeklyDayCard(entry: e.value, index: e.key)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH FILTER BAR
// ─────────────────────────────────────────────────────────────
class _MonthFilterBar extends StatelessWidget {
  final DateTime? selectedMonth;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _MonthFilterBar({
    required this.selectedMonth,
    required this.onPick,
    required this.onClear,
  });

  String get _label {
    if (selectedMonth == null) return 'All Weeks';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[selectedMonth!.month - 1]} ${selectedMonth!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedMonth != null;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.masterBaker.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered
                ? AppColors.masterBaker.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 15,
            color: isFiltered
                ? AppColors.masterBaker
                : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFiltered
                    ? AppColors.masterBaker
                    : AppColors.textSecondary),
          ),
          if (isFiltered) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.masterBaker,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('FILTERED',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ),
          ],
          const Spacer(),
          if (isFiltered)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      AppColors.masterBaker.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close,
                    size: 13, color: AppColors.masterBaker),
              ),
            )
          else
            Icon(Icons.arrow_drop_down,
                size: 18, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WEEK NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _WeekNavigator extends StatelessWidget {
  final String weekStart;
  final String weekEnd;
  final bool isCurrentWeek;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.weekEnd,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
  });

  String _fmt(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr);
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${m[d.month - 1]} ${d.day}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = weekStart.isEmpty
        ? '—'
        : '${_fmt(weekStart)} – ${_fmt(weekEnd)}';

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
        _WkNavBtn(icon: Icons.chevron_left, onTap: onPrev),

        // Center label
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.date_range_outlined,
                  size: 15,
                  color: isCurrentWeek
                      ? AppColors.masterBaker
                      : AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isCurrentWeek
                          ? AppColors.masterBaker
                          : AppColors.primaryDark,
                      letterSpacing: -0.2),
                ),
                if (isCurrentWeek) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.masterBaker,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('THIS WEEK',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Next (disabled when on current week)
        _WkNavBtn(
          icon: Icons.chevron_right,
          onTap: onNext,
          disabled: onNext == null,
        ),
      ]),
    );
  }
}

class _WkNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  const _WkNavBtn(
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
            color: disabled ? AppColors.border : AppColors.masterBaker,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  WEEK OUTSIDE FILTER STATE
// ─────────────────────────────────────────────────────────────
class _WeekOutsideFilter extends StatelessWidget {
  final DateTime month;
  final VoidCallback onClear;

  const _WeekOutsideFilter(
      {required this.month, required this.onClear});

  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final label = '${months[month.month - 1]} ${month.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.masterBaker.withValues(alpha: 0.07),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.filter_alt_outlined,
              size: 32, color: AppColors.masterBaker),
        ),
        const SizedBox(height: 14),
        Text('Week not in $label',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.text)),
        const SizedBox(height: 4),
        const Text('Navigate weeks or clear the filter',
            style:
                TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onClear,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.masterBaker,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Clear Filter',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

// ── Weekly 3-stat row ─────────────────────────────────────────
class _WeeklyStatRow extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _WeeklyStatRow({required this.vm});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.wallet_outlined,
            value: formatCurrency(vm.grossSalary),
            label: 'Gross',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.calendar_today_outlined,
            value: '${vm.daysWorked}',
            label: 'Days',
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.price_check_outlined,
            value: formatCurrency(vm.finalSalary),
            label: 'Net',
            color: AppColors.masterBaker,
          ),
        ),
      ]);
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

// ── Deductions card ───────────────────────────────────────────
class _DeductionsCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _DeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('DEDUCTIONS BREAKDOWN'),
            const SizedBox(height: 14),
            _DeducRow(label: 'Gas',  value: vm.gasDeduction),
            _DeducRow(label: 'Vale', value: vm.valeDeduction),
            _DeducRow(label: 'Wifi', value: vm.wifiDeduction),
          ],
        ),
      );
}

class _DeducRow extends StatelessWidget {
  final String label;
  final double value;
  const _DeducRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(
                value > 0
                    ? Icons.remove_circle_outline
                    : Icons.remove_outlined,
                size: 14,
                color:
                    value > 0 ? AppColors.danger : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary)),
            ]),
            Text(
              value > 0 ? '-${formatCurrency(value)}' : '—',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: value > 0
                      ? AppColors.danger
                      : AppColors.textHint),
            ),
          ],
        ),
      );
}

// ── Take-home card ────────────────────────────────────────────
class _TakeHomeCard extends StatelessWidget {
  final BakerSalaryViewModel vm;
  const _TakeHomeCard({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00).withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text('TAKE-HOME PAY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatCurrency(vm.finalSalary),
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TakeHomePill(
                      label: 'Gross',
                      value: formatCurrency(vm.grossSalary),
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    _TakeHomePill(
                      label: '-Deductions',
                      value: vm.totalDeductions > 0
                          ? formatCurrency(vm.totalDeductions)
                          : '₱0.00',
                      bgColor: Colors.red.withValues(alpha: 0.25),
                      textColor: Colors.red.shade100,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

class _TakeHomePill extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;
  const _TakeHomePill({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor),
        ),
      );
}

// ── Weekly day card (matches screenshot style) ────────────────
class _WeeklyDayCard extends StatelessWidget {
  final BakerDailyEntry entry;
  final int index;
  const _WeeklyDayCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 50),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
          // ── Main row ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.masterBaker.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.receipt_outlined,
                    color: AppColors.masterBaker, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.text,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 3),
                    Text(
                      entry.bakerIncentive > 0
                          ? '${formatCurrency(entry.baseOnly)} base + ${formatCurrency(entry.bakerIncentive)} incentive'
                          : 'Base: ${formatCurrency(entry.baseSalary)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(entry.baseSalary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.15)),
                    ),
                    child: const Text('Earned',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                  ),
                ],
              ),
            ]),
          ),

          // ── Breakdown footer ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.masterBaker.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: entry.bakerIncentive > 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BreakdownPill(
                        label: 'Base',
                        value: formatCurrency(entry.baseOnly),
                        color: AppColors.textSecondary,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('+',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint
                                    .withValues(alpha: 0.5),
                                fontWeight: FontWeight.w700)),
                      ),
                      _BreakdownPill(
                        label: 'Incentive',
                        value: formatCurrency(entry.bakerIncentive),
                        color: const Color(0xFF1976D2),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('=',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint
                                    .withValues(alpha: 0.5),
                                fontWeight: FontWeight.w700)),
                      ),
                      _BreakdownPill(
                        label: 'Total',
                        value: formatCurrency(entry.baseSalary),
                        color: AppColors.masterBaker,
                        highlight: true,
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'Base salary: ${formatCurrency(entry.baseSalary)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _BreakdownPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;
  const _BreakdownPill({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 1),
          Text(value,
              style: TextStyle(
                  fontSize: highlight ? 13 : 12,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      );
}