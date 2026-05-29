import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';
import '../../../master_baker/viewmodel/baker_production_viewmodel.dart';
import 'helper_dashboard.dart' show DashColors;

class HelperDailyScreen extends StatefulWidget {
  const HelperDailyScreen({super.key});

  @override
  State<HelperDailyScreen> createState() => _HelperDailyScreenState();
}

class _HelperDailyScreenState extends State<HelperDailyScreen> {
  // Default: today
  late DateTime _selectedDate;

  // Batch list for selected date
  List<Map<String, dynamic>> _batches  = [];
  Map<String, String>        _products = {}; // productId → productName
  bool _batchesLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

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
    final next = _selectedDate.add(Duration(days: dir));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _load();
  }

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime(2024),
      lastDate:    now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   DashColors.primary,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  void _load() {
    final vm = context.read<HelperSalaryViewModel>();
    vm.loadDailyRecordsForDate(_userId, _dateStr);
    vm.loadPaidWeeks(_userId);
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    if (!mounted) return;
    setState(() => _batchesLoading = true);
    try {
      final db = context.read<DatabaseService>();
      final rows = await db.getHelperBatches(
        helperId: _userId,
        dateFrom: _dateStr,
        dateTo:   _dateStr,
      );
      // Build product name map lazily
      if (_products.isEmpty) {
        final prods = await db.getAllProducts();
        if (mounted) {
          setState(() {
            _products = {for (final p in prods) p.id: p.name};
          });
        }
      }
      if (mounted) setState(() => _batches = rows);
    } catch (_) {
      if (mounted) setState(() => _batches = []);
    } finally {
      if (mounted) setState(() => _batchesLoading = false);
    }
  }

  String _weekStartOf(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return monday.toString().split(' ')[0];
  }

  bool _isPaid(String date, Set<String> paidWeeks) =>
      paidWeeks.contains(_weekStartOf(date));

  // ─────────────────────────────────────────────────────────
  //  FULL PRODUCTION DETAIL SHEET  (Mirrors Baker but NO incentive)
  // ─────────────────────────────────────────────────────────
  void _showPreview(HelperDailyRecord rec, bool paid) {
    final userId  = _userId;
    final prodVm  = context.read<BakerProductionViewModel>();
    final dayProds = prodVm.productions
        .where((p) => p.date == rec.date && p.helperIds.contains(userId))
        .toList();

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize:     0.4,
        maxChildSize:     0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // ── Handle ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashColors.primary.withValues(alpha: 0.08),
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
                              fontSize:     17,
                              fontWeight:   FontWeight.w800,
                              color:        AppColors.text,
                              letterSpacing: -0.3)),
                      const Text('Production Detail',
                          style: TextStyle(
                              fontSize: 12,
                              color:    AppColors.textHint)),
                    ],
                  ),
                ),
                _PaidBadge(paid: paid, large: true),
              ]),
            ),

            const Divider(height: 20, color: AppColors.border),

            // ── Content ───────────────────────────────────────
            Expanded(
              child: dayProds.isEmpty

                  // ── Fallback: summary only (no production model loaded) ──
                  ? ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        _SheetCard(children: [
                          const _SheetLabel('PRODUCTION SUMMARY'),
                          const SizedBox(height: 12),
                          _SheetRow(
                            icon:  Icons.groups_outlined,
                            label: 'Total Workers',
                            value: '${rec.totalWorkers}',
                          ),
                          _SheetRow(
                            icon:  Icons.inventory_2_outlined,
                            label: 'Total Sacks',
                            value: '${rec.totalSacks} sacks',
                          ),
                          _SheetRow(
                            icon:       Icons.attach_money,
                            label:      'Batch Value',
                            value:      formatCurrency(rec.totalValue),
                            valueColor: DashColors.primary,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _SheetCard(children: [
                          const _SheetLabel('SALARY BREAKDOWN'),
                          const SizedBox(height: 12),
                          _SheetRow(
                            icon:  Icons.people_outline,
                            label: 'Per Worker (base)',
                            value: formatCurrency(rec.salary),
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Earnings',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize:   15,
                                      color:      AppColors.text)),
                              Text(
                                formatCurrency(rec.salary),
                                style: const TextStyle(
                                    fontWeight:   FontWeight.w900,
                                    fontSize:     22,
                                    color:        DashColors.primaryDark,
                                    letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _buildPaymentStatus(paid),
                      ],
                    )

                  // ── Full detail from ProductionModel ──────────
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        for (final prod in dayProds) ...[

                          // Batch label (only when multiple batches)
                          if (dayProds.length > 1) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Container(
                                  width: 3, height: 13,
                                  decoration: BoxDecoration(
                                      color: DashColors.primary,
                                      borderRadius: BorderRadius.circular(2)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BATCH ${dayProds.indexOf(prod) + 1}'
                                  ' OF ${dayProds.length}',
                                  style: const TextStyle(
                                      fontSize:     11,
                                      fontWeight:   FontWeight.w800,
                                      color:        AppColors.textHint,
                                      letterSpacing: 0.8),
                                ),
                              ]),
                            ),
                          ],

                          // ── PRODUCTION SUMMARY ──────────────────
                          _SheetCard(children: [
                            const _SheetLabel('PRODUCTION SUMMARY'),
                            const SizedBox(height: 12),
                            _SheetRow(
                              icon:  Icons.groups_outlined,
                              label: 'Total Workers',
                              value: '${prod.totalWorkers}',
                            ),
                            _SheetRow(
                              icon:  Icons.inventory_2_outlined,
                              label: 'Total Sacks',
                              value: prod.totalExtraKg > 0
                                  ? '${prod.totalSacks} sacks + ${prod.totalExtraKg} kg'
                                  : '${prod.totalSacks} sacks',
                            ),
                            _SheetRow(
                              icon:       Icons.attach_money,
                              label:      'Batch Value',
                              value:      formatCurrency(
                                  prodVm.computeDaily(prod).totalValue),
                              valueColor: DashColors.primary,
                            ),
                          ]),
                          const SizedBox(height: 12),

                          // ── SALARY BREAKDOWN (NO baker incentive) ──
                          _SheetCard(children: [
                            const _SheetLabel('SALARY BREAKDOWN'),
                            const SizedBox(height: 12),
                            _SheetRow(
                              icon:  Icons.people_outline,
                              label: 'Per Worker (base)',
                              value: formatCurrency(
                                  prodVm.computeDaily(prod).salaryPerWorker),
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your Earnings',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize:   15,
                                        color:      AppColors.text)),
                                Text(
                                  formatCurrency(
                                      prodVm.computeDaily(prod).salaryPerWorker),
                                  style: const TextStyle(
                                      fontWeight:   FontWeight.w900,
                                      fontSize:     22,
                                      color:        DashColors.primaryDark,
                                      letterSpacing: -0.5),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 12),

                          // ── HELPERS ASSIGNED ────────────────────
                          if (prod.helperIds.isNotEmpty) ...[
                            _SheetCard(children: [
                              const _SheetLabel('HELPERS ASSIGNED'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing:    8,
                                runSpacing: 8,
                                children: prod.helperIds.map((hId) {
                                  final h = prodVm.helpers
                                      .where((u) => u.id == hId)
                                      .firstOrNull;
                                  final isMe = hId == userId;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: DashColors.primary
                                          .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: DashColors.primary
                                              .withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isMe
                                                ? Icons.person
                                                : Icons.person_outline,
                                            size:  13,
                                            color: DashColors.primary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            h?.name ?? 'Helper',
                                            style: const TextStyle(
                                                fontSize:   12,
                                                fontWeight: FontWeight.w600,
                                                color:      DashColors.primary),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: DashColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text('You',
                                                  style: TextStyle(
                                                      fontSize:   8,
                                                      color:      Colors.white,
                                                      fontWeight: FontWeight.w800)),
                                            ),
                                          ],
                                        ]),
                                  );
                                }).toList(),
                              ),
                            ]),
                            const SizedBox(height: 12),
                          ],

                          // ── PRODUCTS PRODUCED ───────────────────
                          _SheetCard(children: [
                            const _SheetLabel('PRODUCTS PRODUCED'),
                            const SizedBox(height: 12),
                            ...prod.items.map((item) {
                              final p = prodVm.products
                                  .where((x) => x.id == item.productId)
                                  .firstOrNull;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: DashColors.primary
                                          .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.bakery_dining_outlined,
                                        size:  14,
                                        color: DashColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      p?.name ?? 'Unknown Product',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color:    AppColors.textSecondary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: DashColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.extraKg > 0
                                          ? '${item.sacks} sacks + ${item.extraKg} kg'
                                          : '${item.sacks} sacks',
                                      style: const TextStyle(
                                          fontSize:   11,
                                          fontWeight: FontWeight.w700,
                                          color:      DashColors.primary),
                                    ),
                                  ),
                                ]),
                              );
                            }),
                          ]),
                          const SizedBox(height: 12),

                          // ── PAYMENT STATUS ──────────────────────
                          _buildPaymentStatus(paid),

                          if (dayProds.indexOf(prod) < dayProds.length - 1)
                            const SizedBox(height: 20),
                        ],
                      ],
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPaymentStatus(bool paid) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.04)
              : Colors.orange.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.15)
                : Colors.orange.withValues(alpha: 0.15),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: paid
                  ? AppColors.success.withValues(alpha: 0.10)
                  : Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              paid
                  ? Icons.check_circle_outline
                  : Icons.schedule_outlined,
              color: paid ? AppColors.success : Colors.orange,
              size:  22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid ? 'Salary Paid' : 'Pending Payment',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   14,
                      color: paid ? AppColors.success : Colors.orange),
                ),
                const SizedBox(height: 2),
                Text(
                  paid
                      ? 'Your salary for this week has been released by admin.'
                      : 'Your salary for this week is pending admin approval.',
                  style: TextStyle(
                      fontSize: 11,
                      color: paid
                          ? AppColors.success.withValues(alpha: 0.8)
                          : Colors.orange.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final vm        = context.watch<HelperSalaryViewModel>();
    final records   = vm.dailyRecords
        .where((r) => r.date == _dateStr)
        .toList();
    final paidWeeks = vm.paidWeekStarts;
    final hasData   = records.isNotEmpty;
    final totalEarned =
        records.fold(0.0, (s, r) => s + r.salary);

    return RefreshIndicator(
      color:     DashColors.primary,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Page header ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Salary',
                        style: TextStyle(
                            fontSize:     20,
                            fontWeight:   FontWeight.w900,
                            color:        AppColors.text,
                            letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Earnings per production day',
                        style: TextStyle(
                            fontSize: 12,
                            color:    AppColors.textHint)),
                  ],
                ),
                if (!_isToday)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = DateTime.now());
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DashColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: DashColors.primary
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size:  13,
                                color: DashColors.primary),
                            SizedBox(width: 5),
                            Text('Today',
                                style: TextStyle(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w700,
                                    color:      DashColors.primary)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Day navigator ────────────────────────────
            _DayNavigator(
              selectedDate: _selectedDate,
              isToday:      _isToday,
              onPrev:       () => _goDay(-1),
              onNext:       _isToday ? null : () => _goDay(1),
              onTap:        _pickDate,
            ),
            const SizedBox(height: 16),

            // ── Stat card ────────────────────────────────
            _DailyStatCard(
              hasData:      hasData,
              totalEarned:  totalEarned,
              recordsCount: records.length,
            ),
            const SizedBox(height: 16),

            // ── Records ──────────────────────────────────
            const _SectionLabel('RECORDS'),
            const SizedBox(height: 10),

            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _load)
            else if (!hasData)
              _NoDayRecord(isToday: _isToday)
            else
              ...records.asMap().entries.map((e) {
                final rec  = e.value;
                final paid = _isPaid(rec.date, paidWeeks);
                return _DailyCard(
                  record: rec,
                  index:  e.key,
                  paid:   paid,
                  onTap:  () => _showPreview(rec, paid),
                );
              }),

            // ── My Batches ───────────────────────────────
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('MY BATCHES'),
                if (_batches.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DashColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_batches.length} batch${_batches.length != 1 ? 'es' : ''}',
                      style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      DashColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_batchesLoading)
              const _LoadingCard()
            else if (_batches.isEmpty)
              _NoBatchRecord(isToday: _isToday)
            else
              ..._batches.asMap().entries.map((e) =>
                  _BatchCard(
                    batch:       e.value,
                    index:       e.key,
                    productName: _products[e.value['product_id'] as String? ?? ''] ?? 'Unknown',
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
  final DateTime      selectedDate;
  final bool          isToday;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onTap;

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
        selectedDate.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset:    const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isToday
                        ? Icons.today
                        : Icons.calendar_today_outlined,
                    size:  15,
                    color: isToday ? DashColors.primary : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _label,
                    style: TextStyle(
                        fontWeight:   FontWeight.w800,
                        fontSize:     14,
                        color: isToday ? DashColors.primary : AppColors.text,
                        letterSpacing: -0.2),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: DashColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TODAY',
                          style: TextStyle(
                              fontSize:     9,
                              fontWeight:   FontWeight.w800,
                              color:        Colors.white,
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
        _NavBtn(
          icon:     Icons.chevron_right,
          onTap:    onNext,
          disabled: onNext == null,
        ),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _NavBtn(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Icon(icon,
              size:  20,
              color: disabled ? AppColors.border : DashColors.primary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  DAILY STAT CARD
// ─────────────────────────────────────────────────────────────
class _DailyStatCard extends StatelessWidget {
  final bool   hasData;
  final double totalEarned;
  final int    recordsCount;

  const _DailyStatCard({
    required this.hasData,
    required this.totalEarned,
    required this.recordsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: hasData
            ? const LinearGradient(
                colors: [DashColors.primary, DashColors.primaryLight],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              )
            : null,
        color:        hasData ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       hasData ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: hasData
                ? DashColors.primary.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: hasData
          ? Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earned Today',
                        style: TextStyle(
                            fontSize:   12,
                            color:      Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalEarned),
                      style: const TextStyle(
                          fontSize:     26,
                          fontWeight:   FontWeight.w900,
                          color:        Colors.white,
                          letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$recordsCount batch${recordsCount > 1 ? 'es' : ''} recorded',
                      style: TextStyle(
                          fontSize: 12,
                          color:    Colors.white.withValues(alpha: 0.85)),
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
                  color: AppColors.border.withValues(alpha: 0.5),
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
                          fontSize:   14,
                          color:      AppColors.text)),
                  SizedBox(height: 2),
                  Text('No production recorded for this day',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColors.textHint)),
                ],
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _NoDayRecord extends StatelessWidget {
  final bool isToday;
  const _NoDayRecord({required this.isToday});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DashColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 36, color: DashColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            isToday
                ? 'No production today yet'
                : 'No production on this day',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize:   15,
                color:      AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'Your records will appear here once added'
                : 'No records were found for this date',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textHint),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  DAILY RECORD CARD
// ─────────────────────────────────────────────────────────────
class _DailyCard extends StatelessWidget {
  final HelperDailyRecord record;
  final int               index;
  final bool              paid;
  final VoidCallback      onTap;

  const _DailyCard({
    required this.record,
    required this.index,
    required this.paid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 50),
      curve:    Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color:     Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset:    const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            // Main row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: DashColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_outlined,
                      color: DashColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch ${index + 1}',
                        style: const TextStyle(
                            fontWeight:   FontWeight.w800,
                            fontSize:     14,
                            color:        AppColors.text,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${record.totalWorkers} workers  ·  '
                        '${record.totalSacks} sacks',
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(record.salary),
                      style: const TextStyle(
                          fontWeight:   FontWeight.w900,
                          fontSize:     15,
                          color:        DashColors.primaryDark,
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 5),
                    _PaidBadge(paid: paid),
                  ],
                ),
              ]),
            ),

            // Footer strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: DashColors.primary.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                border: Border(
                    top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View breakdown',
                      style: TextStyle(
                          fontSize:   11,
                          color: DashColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down,
                      size:  14,
                      color: DashColors.primary.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAID BADGE
// ─────────────────────────────────────────────────────────────
class _PaidBadge extends StatelessWidget {
  final bool paid;
  final bool large;
  const _PaidBadge({required this.paid, this.large = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: large ? 10 : 7,
            vertical:   large ? 5  : 3),
        decoration: BoxDecoration(
          color: paid
              ? AppColors.success.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(large ? 8 : 6),
          border: Border.all(
            color: paid
                ? AppColors.success.withValues(alpha: 0.25)
                : Colors.orange.withValues(alpha: 0.25),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            paid ? Icons.check_circle : Icons.schedule,
            size:  large ? 14 : 10,
            color: paid ? AppColors.success : Colors.orange,
          ),
          SizedBox(width: large ? 4 : 3),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(
                fontSize:   large ? 12 : 10,
                fontWeight: FontWeight.w700,
                color:      paid ? AppColors.success : Colors.orange),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
                fontSize:     11,
                fontWeight:   FontWeight.w800,
                color:        AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

// ─────────────────────────────────────────────────────────────
//  SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────────
class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color:     Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset:    const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

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
                fontSize:     11,
                fontWeight:   FontWeight.w800,
                color:        AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _SheetRow({
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
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      valueColor ?? AppColors.text)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  NO BATCH RECORD
// ─────────────────────────────────────────────────────────────
class _NoBatchRecord extends StatelessWidget {
  final bool isToday;
  const _NoBatchRecord({required this.isToday});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.layers_outlined,
                size: 30, color: DashColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            isToday ? 'No batches added today' : 'No batches on this day',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize:   14,
                color:      AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'Use "Add Production Batch" to log your work'
                : 'No batch records found for this date',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  BATCH CARD
// ─────────────────────────────────────────────────────────────
class _BatchCard extends StatelessWidget {
  final Map<String, dynamic> batch;
  final int                  index;
  final String               productName;

  const _BatchCard({
    required this.batch,
    required this.index,
    required this.productName,
  });

  String _categorySummary() {
    final parts = <String>[
      if ((batch['cat60'] ?? 0) > 0) '60: ${batch['cat60']}',
      if ((batch['cat36'] ?? 0) > 0) '36: ${batch['cat36']}',
      if ((batch['cat48'] ?? 0) > 0) '48: ${batch['cat48']}',
      if ((batch['subra'] ?? 0) > 0) 'Subra: ${batch['subra']}',
      if ((batch['saka']  ?? 0) > 0) 'Saka: ${batch['saka']}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final sacks   = (batch['saka'] ?? 0) as int;
    final summary = _categorySummary();

    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 50),
      curve:    Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Index circle
            Container(
              width: 36, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DashColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w800,
                    color:      DashColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            // Product + categories
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   14,
                          color:      AppColors.text)),
                  const SizedBox(height: 4),
                  if (summary.isNotEmpty)
                    Text(summary,
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColors.textHint)),
                ],
              ),
            ),
            // Sacks badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        DashColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$sacks sack${sacks != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      DashColors.primary),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOADING + ERROR
// ─────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: DashColors.primary, strokeWidth: 2.5),
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
          color:        AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
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
            icon:  const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ]),
      );
}
