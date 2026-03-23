import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/packer_production_model.dart';
import '../../../../core/services/packer_service.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

class ProductionReportPacker extends StatefulWidget {
  const ProductionReportPacker({super.key});

  @override
  State<ProductionReportPacker> createState() =>
      _ProductionReportPackerState();
}

class _ProductionReportPackerState
    extends State<ProductionReportPacker>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = ['Weekly', 'Daily'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.packer,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.packer,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          Container(height: 1, color: AppColors.border),
        ]),
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: const [
            _PackerWeeklyReportTab(),
            _PackerDailyReportTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  WEEKLY TAB
// ══════════════════════════════════════════════════════════════
class _PackerWeeklyReportTab extends StatefulWidget {
  const _PackerWeeklyReportTab();

  @override
  State<_PackerWeeklyReportTab> createState() =>
      _PackerWeeklyReportTabState();
}

class _PackerWeeklyReportTabState
    extends State<_PackerWeeklyReportTab> {
  final _service = PackerService();

  late DateTime _weekStart;
  bool    _isLoading = false;
  String? _error;
  String? _expandedPackerId;
  Map<String, List<PackerProductionModel>> _data = {};

  @override
  void initState() {
    super.initState();
    // ── Default: current week ────────────────────────────
    _weekStart = _currentMonday();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
  }

  DateTime _currentMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  bool get _isCurrentWeek {
    final cm = _currentMonday();
    return _weekStart.year == cm.year &&
        _weekStart.month == cm.month &&
        _weekStart.day == cm.day;
  }

  String get _weekStartStr =>
      _weekStart.toIso8601String().substring(0, 10);

  String get _weekEndStr {
    final end = _weekStart.add(const Duration(days: 6));
    return end.toIso8601String().substring(0, 10);
  }

  String _fmtWeekLabel(String ws, String we) {
  try {
    final s = DateTime.parse(ws);
    final e = DateTime.parse(we);
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    if (s.month == e.month) {
      return '${m[s.month - 1]} ${s.day}–${e.day}, ${s.year}';
    }
    return '${m[s.month - 1]} ${s.day} – ${m[e.month - 1]} ${e.day}, ${e.year}';
  } catch (_) {
    return '$ws – $we';
  }
}

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final packers = context
          .read<AdminUserViewModel>()
          .nonAdminUsers
          .where((u) => u.isPacker)
          .toList();
      final newData = <String, List<PackerProductionModel>>{};
      await Future.wait(packers.map((p) async {
        final prods = await _service.getProductionsByWeek(
          packerId:  p.id,
          weekStart: _weekStartStr,
          weekEnd:   _weekEndStr,
        );
        newData[p.id] = prods;
      }));
      setState(() { _data = newData; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _changeWeek(int dir) async {
    // Block going forward past current week
    if (dir > 0 && _isCurrentWeek) return;
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * dir));
      _expandedPackerId = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final packers = context
        .watch<AdminUserViewModel>()
        .nonAdminUsers
        .where((u) => u.isPacker)
        .toList();

    int    totalBundles = 0;
    double totalSalary  = 0;
    for (final prods in _data.values) {
      final b = prods.fold(0, (s, p) => s + p.bundleCount);
      totalBundles += b;
      totalSalary  += b * 4.0;
    }

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: _load,
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
                const _SectionHeader(
                  title:    'Packer Weekly Report',
                  subtitle: 'Bundles & salary per packer',
                  icon:     Icons.inventory_2_outlined,
                ),
                if (!_isCurrentWeek)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _weekStart        = _currentMonday();
                        _expandedPackerId = null;
                      });
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.packer
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.packer
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 12,
                                color: AppColors.packer),
                            SizedBox(width: 4),
                            Text('This Week',
                                style: TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w700,
                                    color:      AppColors.packer)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Week navigator ───────────────────────────
            _WeekNav(
              label:         _fmtWeekLabel(_weekStartStr, _weekEndStr),
              isCurrentWeek: _isCurrentWeek,
              onPrev:        () => _changeWeek(-1),
              onNext:        _isCurrentWeek ? null : () => _changeWeek(1),
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const _Loader()
            else if (_error != null)
              _ErrCard(_error!)
            else ...[
              if (packers.isNotEmpty)
                _WeeklySummaryBanner(
                  packerCount:  packers.length,
                  totalBundles: totalBundles,
                  totalSalary:  totalSalary,
                ),
              const SizedBox(height: 14),
              if (packers.isEmpty)
                const _EmptyCard(
                    icon: Icons.inventory_2_outlined,
                    message: 'No packers found')
              else
                ...packers.map((packer) {
                  final prods     = _data[packer.id] ?? [];
                  final bundles   =
                      prods.fold(0, (s, p) => s + p.bundleCount);
                  final salary    = bundles * 4.0;
                  final isExpanded =
                      _expandedPackerId == packer.id;
                  return _ExpandablePackerCard(
                    packer:      packer,
                    productions: prods,
                    bundles:     bundles,
                    salary:      salary,
                    isExpanded:  isExpanded,
                    onTap: () => setState(() {
                      _expandedPackerId =
                          isExpanded ? null : packer.id;
                    }),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DAILY TAB
// ══════════════════════════════════════════════════════════════
class _PackerDailyReportTab extends StatefulWidget {
  const _PackerDailyReportTab();

  @override
  State<_PackerDailyReportTab> createState() =>
      _PackerDailyReportTabState();
}

class _PackerDailyReportTabState
    extends State<_PackerDailyReportTab> {
  final _service = PackerService();

  // ── Default: today ───────────────────────────────────────
  late DateTime _selectedDate;
  bool    _isLoading = false;
  String? _error;
  Map<String, List<PackerProductionModel>> _data = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateStr =>
      _selectedDate.toIso8601String().substring(0, 10);

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final packers = context
          .read<AdminUserViewModel>()
          .nonAdminUsers
          .where((u) => u.isPacker)
          .toList();
      final newData = <String, List<PackerProductionModel>>{};
      await Future.wait(packers.map((p) async {
        final prods = await _service.getProductionsByDate(
          packerId: p.id,
          date:     _dateStr,
        );
        newData[p.id] = prods;
      }));
      setState(() { _data = newData; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime(DateTime.now().year - 1),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary:   AppColors.packer,
              onSurface: AppColors.text),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _load();
    }
  }

  void _changeDay(int dir) {
    final next = _selectedDate.add(Duration(days: dir));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final packers = context
        .watch<AdminUserViewModel>()
        .nonAdminUsers
        .where((u) => u.isPacker)
        .toList();

    int    totalBundles = 0;
    double totalSalary  = 0;
    for (final prods in _data.values) {
      final b = prods.fold(0, (s, p) => s + p.bundleCount);
      totalBundles += b;
      totalSalary  += b * 4.0;
    }

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: _load,
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
                const _SectionHeader(
                  title:    'Packer Daily Report',
                  subtitle: 'All packer entries for a day',
                  icon:     Icons.receipt_long_outlined,
                ),
                if (!_isToday)
                  GestureDetector(
                    onTap: () {
                      setState(
                          () => _selectedDate = DateTime.now());
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.packer
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.packer
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 12,
                                color: AppColors.packer),
                            SizedBox(width: 4),
                            Text('Today',
                                style: TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w700,
                                    color:      AppColors.packer)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Day navigator ────────────────────────────
            _DayNav(
              selectedDate: _selectedDate,
              isToday:      _isToday,
              onPrev:       () => _changeDay(-1),
              onNext:       _isToday ? null : () => _changeDay(1),
              onPickDate:   _pickDate,
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const _Loader()
            else if (_error != null)
              _ErrCard(_error!)
            else ...[
              if (totalBundles > 0)
                _DailySummaryBanner(
                  packerCount: packers
                      .where((p) => (_data[p.id] ?? []).isNotEmpty)
                      .length,
                  totalBundles: totalBundles,
                  totalSalary:  totalSalary,
                ),
              const SizedBox(height: 14),
              if (packers.isEmpty)
                const _EmptyCard(
                    icon:    Icons.inventory_2_outlined,
                    message: 'No packers found')
              else if (totalBundles == 0)
                _EmptyCard(
                    icon:    Icons.receipt_long_outlined,
                    message: 'No packer entries on $_dateStr')
              else
                ...packers
                    .where((p) => (_data[p.id] ?? []).isNotEmpty)
                    .map((packer) {
                      final prods   = _data[packer.id] ?? [];
                      final bundles =
                          prods.fold(0, (s, p) => s + p.bundleCount);
                      final salary  = bundles * 4.0;
                      final byProduct = <String, int>{};
                      for (final p in prods) {
                        byProduct[p.productName] =
                            (byProduct[p.productName] ?? 0) +
                                p.bundleCount;
                      }
                      return _DailyPackerCard(
                        packer:    packer,
                        prods:     prods,
                        bundles:   bundles,
                        salary:    salary,
                        byProduct: byProduct,
                      );
                    }),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  UPDATED WEEK NAVIGATOR
// ══════════════════════════════════════════════════════════════
class _WeekNav extends StatelessWidget {
  final String        label;
  final bool          isCurrentWeek;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;

  const _WeekNav({
    required this.label,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isCurrentWeek
              ? AppColors.packer.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentWeek
                ? AppColors.packer.withValues(alpha: 0.25)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          _PkrNavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range_outlined,
                      size:  15,
                      color: isCurrentWeek
                          ? AppColors.packer
                          : AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize:   13,
                          color: isCurrentWeek
                              ? AppColors.packer
                              : AppColors.primaryDark,
                          letterSpacing: -0.2)),
                  if (isCurrentWeek) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.packer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('THIS WEEK',
                          style: TextStyle(
                              fontSize:   8,
                              fontWeight: FontWeight.w800,
                              color:      Colors.white,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _PkrNavBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  UPDATED DAY NAVIGATOR
// ══════════════════════════════════════════════════════════════
class _DayNav extends StatelessWidget {
  final DateTime      selectedDate;
  final bool          isToday;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onPickDate;

  const _DayNav({
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
  });

  String get _label {
    if (isToday) return 'Today';
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    if (selectedDate.year == yesterday.year &&
        selectedDate.month == yesterday.month &&
        selectedDate.day == yesterday.day) return 'Yesterday';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.packer.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? AppColors.packer.withValues(alpha: 0.25)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          _PkrNavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isToday
                            ? Icons.today
                            : Icons.calendar_today_outlined,
                        size:  15,
                        color: isToday
                            ? AppColors.packer
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Text(_label,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize:   13,
                              color: isToday
                                  ? AppColors.packer
                                  : AppColors.primaryDark,
                              letterSpacing: -0.2)),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.packer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('TODAY',
                              style: TextStyle(
                                  fontSize:   8,
                                  fontWeight: FontWeight.w800,
                                  color:      Colors.white,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          size: 18, color: AppColors.textHint),
                    ],
                  ),
                  const Text('Tap to pick a date',
                      style: TextStyle(
                          fontSize: 10,
                          color:    AppColors.textHint)),
                ]),
              ),
            ),
          ),
          _PkrNavBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

class _PkrNavBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _PkrNavBtn(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Icon(icon,
              size:  20,
              color: disabled
                  ? AppColors.border
                  : AppColors.packer),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  ALL REMAINING WIDGETS — UNCHANGED
// ══════════════════════════════════════════════════════════════

class _WeeklySummaryBanner extends StatelessWidget {
  final int    packerCount;
  final int    totalBundles;
  final double totalSalary;
  const _WeeklySummaryBanner({
    required this.packerCount,
    required this.totalBundles,
    required this.totalSalary,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.packer,
              AppColors.packer.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      AppColors.packer.withValues(alpha: 0.28),
              blurRadius: 14,
              offset:     const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BannerStat(icon: Icons.people_outline,
                label: 'Packers',       value: '$packerCount'),
            _BannerDivider(),
            _BannerStat(icon: Icons.inventory_2_outlined,
                label: 'Total Bundles', value: '$totalBundles'),
            _BannerDivider(),
            _BannerStat(icon: Icons.payments_outlined,
                label: 'Total Salary',
                value: formatCurrency(totalSalary)),
          ],
        ),
      );
}

class _ExpandablePackerCard extends StatelessWidget {
  final UserModel                   packer;
  final List<PackerProductionModel> productions;
  final int                         bundles;
  final double                      salary;
  final bool                        isExpanded;
  final VoidCallback                onTap;

  const _ExpandablePackerCard({
    required this.packer,
    required this.productions,
    required this.bundles,
    required this.salary,
    required this.isExpanded,
    required this.onTap,
  });

  Map<String, int> get _byProduct {
    final map = <String, int>{};
    for (final p in productions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  List<_DayEntry> get _byDay {
    final map = <String, List<PackerProductionModel>>{};
    for (final p in productions) {
      map.putIfAbsent(p.date, () => []).add(p);
    }
    return map.entries.map((e) {
      final b = e.value.fold(0, (s, p) => s + p.bundleCount);
      return _DayEntry(
          date:        e.key,
          bundles:     b,
          salary:      b * 4.0,
          productions: e.value);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final hasData = bundles > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve:    Curves.easeInOut,
      margin:   const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.packer.withValues(alpha: 0.40)
              : AppColors.border,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: isExpanded
                  ? AppColors.packer.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        InkWell(
          onTap:        hasData ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppColors.packer
                      : AppColors.packer.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  packer.name.isNotEmpty ? packer.name[0] : 'P',
                  style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.w900,
                      color: isExpanded
                          ? Colors.white
                          : AppColors.packer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(packer.name,
                        style: const TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w800,
                            color:      AppColors.text)),
                    const SizedBox(height: 3),
                    Text(
                      hasData
                          ? '${_byDay.length} days · $bundles bundles'
                          : 'No production this week',
                      style: const TextStyle(
                          fontSize: 12,
                          color:    AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(salary),
                    style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w800,
                        color: hasData
                            ? AppColors.primaryDark
                            : AppColors.textHint),
                  ),
                  const SizedBox(height: 4),
                  if (hasData)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size:  18,
                      color: AppColors.packer,
                    ),
                ],
              ),
            ]),
          ),
        ),
        if (isExpanded && hasData) ...[
          Container(height: 1,
              color: AppColors.packer.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SubLabel('PRODUCT BREAKDOWN'),
                const SizedBox(height: 8),
                ..._byProduct.entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.packer.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.packer
                                .withValues(alpha: 0.12)),
                      ),
                      child: Row(children: [
                        Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: AppColors.packer,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColors.text)),
                        ),
                        Text('${e.value} bundles',
                            style: const TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700,
                                color:      AppColors.packer)),
                        const SizedBox(width: 12),
                        Text(formatCurrency(e.value * 4.0),
                            style: const TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.success)),
                      ]),
                    )),
                const SizedBox(height: 10),
                Container(height: 1,
                    color: AppColors.packer.withValues(alpha: 0.10)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.packer,
                        AppColors.packer.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Total',
                              style: TextStyle(
                                  fontSize:   11,
                                  color:      Colors.white70,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('$bundles bundles × ₱4.00',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:    Colors.white70)),
                        ],
                      ),
                      Text(formatCurrency(salary),
                          style: const TextStyle(
                              fontSize:   20,
                              fontWeight: FontWeight.w900,
                              color:      Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SubLabel('DAILY BREAKDOWN'),
                const SizedBox(height: 8),
                ..._byDay.map((day) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFF8F4F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.packer
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(day.date.substring(8),
                              style: const TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w800,
                                  color:      AppColors.packer)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(day.date),
                                  style: const TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w600,
                                      color:      AppColors.text)),
                              Text(
                                '${day.productions.length} entr${day.productions.length == 1 ? 'y' : 'ies'} · ${day.bundles} bundles',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                        Text(formatCurrency(day.salary),
                            style: const TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700,
                                color:      AppColors.primaryDark)),
                      ]),
                    )),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return dateStr; }
  }
}

class _DailyPackerCard extends StatelessWidget {
  final UserModel                   packer;
  final List<PackerProductionModel> prods;
  final int                         bundles;
  final double                      salary;
  final Map<String, int>            byProduct;

  const _DailyPackerCard({
    required this.packer,
    required this.prods,
    required this.bundles,
    required this.salary,
    required this.byProduct,
  });

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset:     const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.packer.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  packer.name.isNotEmpty ? packer.name[0] : 'P',
                  style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w900,
                      color:      AppColors.packer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(packer.name,
                        style: const TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w800,
                            color:      AppColors.text)),
                    Text('${prods.length} entries',
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$bundles bundles',
                      style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.packer)),
                  Text(formatCurrency(salary),
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w900,
                          color:      AppColors.primaryDark)),
                ],
              ),
            ]),
            const SizedBox(height: 10),
            Container(height: 1,
                color: AppColors.packer.withValues(alpha: 0.10)),
            const SizedBox(height: 10),
            ...byProduct.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: AppColors.packer,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColors.textSecondary)),
                    ),
                    Text('${e.value} bundles',
                        style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.packer)),
                    const SizedBox(width: 10),
                    Text(formatCurrency(e.value * 4.0),
                        style: const TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.success)),
                  ]),
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        const Color(0xFFF8F4F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 5),
                  Text('ENTRY LOG',
                      style: TextStyle(
                          fontSize:   9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHint
                              .withValues(alpha: 0.8),
                          letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 6),
                ...prods.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 5, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(p.productName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:    AppColors.textSecondary)),
                        ),
                        Text('${p.bundleCount} bundles',
                            style: const TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.packer)),
                        const SizedBox(width: 8),
                        Text(_formatTime(p.timestamp),
                            style: const TextStyle(
                                fontSize: 10,
                                color:    AppColors.textHint)),
                      ]),
                    )),
              ]),
            ),
          ],
        ),
      );
}

class _DailySummaryBanner extends StatelessWidget {
  final int    packerCount;
  final int    totalBundles;
  final double totalSalary;
  const _DailySummaryBanner({
    required this.packerCount,
    required this.totalBundles,
    required this.totalSalary,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.packer,
              AppColors.packer.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      AppColors.packer.withValues(alpha: 0.25),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BannerStat(icon: Icons.people_outline,
                label: 'Active',       value: '$packerCount'),
            _BannerDivider(),
            _BannerStat(icon: Icons.inventory_2_outlined,
                label: 'Bundles',      value: '$totalBundles'),
            _BannerDivider(),
            _BannerStat(icon: Icons.payments_outlined,
                label: 'Total Salary',
                value: formatCurrency(totalSalary)),
          ],
        ),
      );
}

class _DayEntry {
  final String                      date;
  final int                         bundles;
  final double                      salary;
  final List<PackerProductionModel> productions;
  const _DayEntry({
    required this.date,
    required this.bundles,
    required this.salary,
    required this.productions,
  });
}

class _SectionHeader extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final IconData icon;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.packer.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.packer, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(title,
              style: const TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                  color:      AppColors.text,
                  letterSpacing: -0.3)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ]),
      ]);
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.inventory_2_outlined,
            size: 13, color: AppColors.packer),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w800,
                color: AppColors.packer.withValues(alpha: 0.8),
                letterSpacing: 0.8)),
      ]);
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _BannerStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w900,
                fontSize:   13)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 10)),
      ]);
}

class _BannerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 34,
      color: Colors.white.withValues(alpha: 0.3));
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 40,
              color: AppColors.packer.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 14)),
        ]),
      );
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.packer, strokeWidth: 2.5),
        ),
      );
}

class _ErrCard extends StatelessWidget {
  final String message;
  const _ErrCard(this.message);

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
        ]),
      );
}