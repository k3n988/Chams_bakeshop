part of 'baker_salary_screen.dart';

// ══════════════════════════════════════════════════════════════
//  DAILY TAB
// ══════════════════════════════════════════════════════════════
class _DailyTab extends StatefulWidget {
  final String userId;
  const _DailyTab({required this.userId});

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab> {
  // Default to today
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForDate());
  }

  String get _dateStr =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _goDay(int dir) {
    setState(() =>
        _selectedDate = _selectedDate.add(Duration(days: dir)));
    _loadForDate();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
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
      setState(() => _selectedDate = picked);
      _loadForDate();
    }
  }

  void _loadForDate() {
    context.read<BakerSalaryViewModel>().loadDailyForDate(
          widget.userId,
          _dateStr,
        );
  }

  void _showPreviewSheet(BuildContext context, BakerDailyEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.60,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
                      Text(entry.date,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.3)),
                      const Text('Daily Production Detail',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint)),
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
                        color:
                            AppColors.masterBaker.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👨‍🍳', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text('Baker',
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
                  // Salary breakdown
                  _PreviewCard(children: [
                    const _PreviewCardLabel('SALARY BREAKDOWN'),
                    const SizedBox(height: 12),
                    _PreviewDataRow(
                      icon: Icons.people_outline,
                      label: 'Base (per worker)',
                      value: formatCurrency(entry.baseOnly),
                      valueColor: AppColors.masterBaker,
                    ),
                    if (entry.bakerIncentive > 0)
                      _PreviewDataRow(
                        icon: Icons.star_outline,
                        label: 'Baker Incentive',
                        value: formatCurrency(entry.bakerIncentive),
                        valueColor: const Color(0xFF1976D2),
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
                          formatCurrency(entry.baseSalary),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Baker incentive info
                  if (entry.bakerIncentive > 0) ...[
                    _PreviewCard(children: [
                      const _PreviewCardLabel('BAKER INCENTIVE'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.masterBaker
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.masterBaker
                                  .withValues(alpha: 0.15)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.masterBaker
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.star_outline,
                                size: 16,
                                color: AppColors.masterBaker),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Incentive is included in your salary total above.',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // Status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle_outline,
                            color: AppColors.success, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Production Recorded',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.success)),
                            SizedBox(height: 2),
                            Text(
                              'Included in your weekly salary.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerSalaryViewModel>();

    // Filter entries for selected date
    final todayEntries = vm.dailyEntries
        .where((e) => e.date == _dateStr)
        .toList();

    final hasData = todayEntries.isNotEmpty;
    final totalEarned = todayEntries.fold(
        0.0, (sum, e) => sum + e.baseSalary);

    return RefreshIndicator(
      color: AppColors.masterBaker,
      onRefresh: () async => _loadForDate(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Salary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Earnings per production day',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
                // Today shortcut
                if (!_isToday)
                  GestureDetector(
                    onTap: () {
                      setState(
                          () => _selectedDate = DateTime.now());
                      _loadForDate();
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
                            Text('Today',
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

            // ── Day navigator ──────────────────────────────────
            _DayNavigator(
              selectedDate: _selectedDate,
              isToday: _isToday,
              onPrev: () => _goDay(-1),
              onNext: _isToday ? null : () => _goDay(1),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // ── Summary card ───────────────────────────────────
            _DailyStatCard(
              hasData: hasData,
              totalEarned: totalEarned,
              entriesCount: todayEntries.length,
              dateStr: _dateStr,
            ),
            const SizedBox(height: 16),

            // ── Records section ────────────────────────────────
            const _SectionLabel('RECORDS'),
            const SizedBox(height: 10),

            if (vm.isLoading)
              const _Loader()
            else if (vm.error != null)
              _ErrCard(vm.error!)
            else if (!hasData)
              _NoDayRecord(isToday: _isToday)
            else
              ...todayEntries.asMap().entries.map((e) =>
                  _DailyEntryCard(
                    entry: e.value,
                    index: e.key,
                    onTap: () =>
                        _showPreviewSheet(context, e.value),
                  )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DAY NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _DayNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTap;

  const _DayNavigator({
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  String get _label {
    if (isToday) return 'Today';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (selectedDate.year == yesterday.year &&
        selectedDate.month == yesterday.month &&
        selectedDate.day == yesterday.day) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';
  }

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
        _NavBtn(
          icon: Icons.chevron_left,
          onTap: onPrev,
        ),

        // Center date display
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isToday
                        ? Icons.today
                        : Icons.calendar_today_outlined,
                    size: 15,
                    color: isToday
                        ? AppColors.masterBaker
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isToday
                            ? AppColors.masterBaker
                            : AppColors.text,
                        letterSpacing: -0.2),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.masterBaker,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TODAY',
                          style: TextStyle(
                              fontSize: 9,
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

        // Next (disabled if today)
        _NavBtn(
          icon: Icons.chevron_right,
          onTap: onNext,
          disabled: onNext == null,
        ),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  const _NavBtn(
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
//  DAILY STAT CARD
// ─────────────────────────────────────────────────────────────
class _DailyStatCard extends StatelessWidget {
  final bool hasData;
  final double totalEarned;
  final int entriesCount;
  final String dateStr;

  const _DailyStatCard({
    required this.hasData,
    required this.totalEarned,
    required this.entriesCount,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: hasData
            ? const LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasData ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasData
            ? null
            : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: hasData
                ? const Color(0xFFFF7A00).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasData
          ? Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earned Today',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalEarned),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$entriesCount batch${entriesCount > 1 ? 'es' : ''} recorded',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Colors.white, size: 28),
              ),
            ])
          : Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.border
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: AppColors.textHint, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No earnings yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text)),
                  SizedBox(height: 2),
                  Text('No production recorded for this day',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint)),
                ],
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NO RECORD STATE
// ─────────────────────────────────────────────────────────────
class _NoDayRecord extends StatelessWidget {
  final bool isToday;
  const _NoDayRecord({required this.isToday});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.masterBaker.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 36, color: AppColors.masterBaker),
            ),
            const SizedBox(height: 14),
            Text(
              isToday
                  ? 'No production today yet'
                  : 'No production on this day',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              isToday
                  ? 'Start a batch from the Produce tab'
                  : 'No records were found for this date',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  DAILY ENTRY CARD
// ─────────────────────────────────────────────────────────────
class _DailyEntryCard extends StatelessWidget {
  final BakerDailyEntry entry;
  final int index;
  final VoidCallback onTap;
  const _DailyEntryCard({
    required this.entry,
    required this.index,
    required this.onTap,
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
      child: GestureDetector(
        onTap: onTap,
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.masterBaker
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_outlined,
                        color: AppColors.masterBaker, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Batch ${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.text)),
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
                            color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.success
                                  .withValues(alpha: 0.15)),
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
              // Tap hint strip
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.masterBaker
                      .withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View breakdown',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.masterBaker
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    Icon(Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppColors.masterBaker
                            .withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PREVIEW SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────────
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
          width: 3, height: 13,
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