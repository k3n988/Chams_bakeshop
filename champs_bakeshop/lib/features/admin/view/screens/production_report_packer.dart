import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/packer_production_model.dart';
import '../../../../core/services/packer_service.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

// ══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ══════════════════════════════════════════════════════════════
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
      // ── Tab bar ────────────────────────────────────────────
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

      // ── Tab views ─────────────────────────────────────────
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
//  WEEKLY TAB  — shows each packer's weekly bundles & salary
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

  DateTime _weekStart = DateTime.now();
  bool     _isLoading = false;
  String?  _error;
  String?  _expandedPackerId;

  // {packerId: [productions]}
  Map<String, List<PackerProductionModel>> _data = {};

  @override
  void initState() {
    super.initState();
    _setWeekToCurrentMonday();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
  }

  void _setWeekToCurrentMonday() {
    final now  = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    _weekStart = DateTime(now.year, now.month, now.day - diff);
  }

  String get _weekStartStr =>
      _weekStart.toIso8601String().substring(0, 10);

  String get _weekEndStr {
    final end = _weekStart.add(const Duration(days: 6));
    return end.toIso8601String().substring(0, 10);
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

    // Overall totals
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
            const _SectionHeader(
              title: 'Packer Weekly Report',
              subtitle: 'Bundles & salary per packer',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 16),

            // ── Week navigator ─────────────────────────────
            _WeekNav(
              weekStart: _weekStartStr,
              weekEnd:   _weekEndStr,
              onPrev:    () => _changeWeek(-1),
              onNext:    () => _changeWeek(1),
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const _Loader()
            else if (_error != null)
              _ErrCard(_error!)
            else ...[
              // ── Summary banner ───────────────────────────
              if (packers.isNotEmpty)
                _WeeklySummaryBanner(
                  packerCount:  packers.length,
                  totalBundles: totalBundles,
                  totalSalary:  totalSalary,
                ),
              const SizedBox(height: 14),

              // ── Per-packer cards ─────────────────────────
              if (packers.isEmpty)
                _EmptyCard(
                    icon: Icons.inventory_2_outlined,
                    message: 'No packers found')
              else
                ...packers.map((packer) {
                  final prods = _data[packer.id] ?? [];
                  final bundles =
                      prods.fold(0, (s, p) => s + p.bundleCount);
                  final salary = bundles * 4.0;
                  final isExpanded =
                      _expandedPackerId == packer.id;

                  return _ExpandablePackerCard(
                    packer:     packer,
                    productions: prods,
                    bundles:    bundles,
                    salary:     salary,
                    isExpanded: isExpanded,
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

// ── Weekly summary banner ─────────────────────────────────────
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
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.packer.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BannerStat(
                icon: Icons.people_outline,
                label: 'Packers',
                value: '$packerCount'),
            _BannerDivider(),
            _BannerStat(
                icon: Icons.inventory_2_outlined,
                label: 'Total Bundles',
                value: '$totalBundles'),
            _BannerDivider(),
            _BannerStat(
                icon: Icons.payments_outlined,
                label: 'Total Salary',
                value: formatCurrency(totalSalary)),
          ],
        ),
      );
}

// ── Expandable packer card ────────────────────────────────────
class _ExpandablePackerCard extends StatelessWidget {
  final UserModel                      packer;
  final List<PackerProductionModel>    productions;
  final int                            bundles;
  final double                         salary;
  final bool                           isExpanded;
  final VoidCallback                   onTap;

  const _ExpandablePackerCard({
    required this.packer,
    required this.productions,
    required this.bundles,
    required this.salary,
    required this.isExpanded,
    required this.onTap,
  });

  // Group by product
  Map<String, int> get _byProduct {
    final map = <String, int>{};
    for (final p in productions) {
      map[p.productName] = (map[p.productName] ?? 0) + p.bundleCount;
    }
    return map;
  }

  // Group by date → daily entries
  List<_DayEntry> get _byDay {
    final map = <String, List<PackerProductionModel>>{};
    for (final p in productions) {
      map.putIfAbsent(p.date, () => []).add(p);
    }
    final entries = map.entries.map((e) {
      final b = e.value.fold(0, (s, p) => s + p.bundleCount);
      return _DayEntry(date: e.key, bundles: b, salary: b * 4.0,
          productions: e.value);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = bundles > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
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
        // ── Header ────────────────────────────────────────────
        InkWell(
          onTap: hasData ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Avatar
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
                  packer.name.isNotEmpty
                      ? packer.name[0]
                      : 'P',
                  style: TextStyle(
                      fontSize: 18,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text)),
                    const SizedBox(height: 3),
                    Text(
                      hasData
                          ? '${_byDay.length} days · $bundles bundles'
                          : 'No production this week',
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
                    formatCurrency(salary),
                    style: TextStyle(
                        fontSize: 15,
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
                      size: 18,
                      color: AppColors.packer,
                    ),
                ],
              ),
            ]),
          ),
        ),

        // ── Expanded content ──────────────────────────────────
        if (isExpanded && hasData) ...[
          Container(
              height: 1,
              color: AppColors.packer.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product breakdown ────────────────────────
                _SubLabel('PRODUCT BREAKDOWN'),
                const SizedBox(height: 8),
                ..._byProduct.entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.packer
                            .withValues(alpha: 0.04),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text)),
                        ),
                        Text('${e.value} bundles',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.packer)),
                        const SizedBox(width: 12),
                        Text(formatCurrency(e.value * 4.0),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ]),
                    )),

                const SizedBox(height: 10),
                Container(height: 1,
                    color: AppColors.packer.withValues(alpha: 0.10)),
                const SizedBox(height: 10),

                // ── Weekly total ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.packer,
                        AppColors.packer.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Total',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('$bundles bundles × ₱4.00',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70)),
                        ],
                      ),
                      Text(formatCurrency(salary),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Daily breakdown ──────────────────────────
                _SubLabel('DAILY BREAKDOWN'),
                const SizedBox(height: 8),

                ..._byDay.map((day) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4F0),
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
                          child: Text(
                            day.date.substring(8),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.packer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(day.date),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text)),
                              Text(
                                '${day.productions.length} entr${day.productions.length == 1 ? 'y' : 'ies'} · ${day.bundles} bundles',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                        Text(formatCurrency(day.salary),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
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

// ══════════════════════════════════════════════════════════════
//  DAILY TAB  — pick any date, see all packer entries
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

  DateTime _selectedDate = DateTime.now();
  bool     _isLoading    = false;
  String?  _error;

  // {packerId: [productions]}
  Map<String, List<PackerProductionModel>> _data = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
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
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: AppColors.packer,
              onPrimary: Colors.white),
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

    final isToday = _dateStr ==
        DateTime.now().toIso8601String().substring(0, 10);

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Packer Daily Report',
              subtitle: 'All packer entries for a day',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 16),

            // ── Date navigator ─────────────────────────────
            _DayNav(
              dateLabel: _formatDate(_dateStr),
              isToday:   isToday,
              onPrev:    () => _changeDay(-1),
              onNext:    isToday ? null : () => _changeDay(1),
              onPickDate: _pickDate,
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const _Loader()
            else if (_error != null)
              _ErrCard(_error!)
            else ...[
              // ── Day summary ────────────────────────────────
              if (totalBundles > 0)
                _DailySummaryBanner(
                  packerCount:  packers
                      .where((p) =>
                          (_data[p.id] ?? []).isNotEmpty)
                      .length,
                  totalBundles: totalBundles,
                  totalSalary:  totalSalary,
                ),
              const SizedBox(height: 14),

              // ── Per-packer rows ────────────────────────────
              if (packers.isEmpty)
                _EmptyCard(
                    icon: Icons.inventory_2_outlined,
                    message: 'No packers found')
              else if (totalBundles == 0)
                _EmptyCard(
                    icon: Icons.receipt_long_outlined,
                    message: 'No packer entries on $_dateStr')
              else
                ...packers
                    .where((p) =>
                        (_data[p.id] ?? []).isNotEmpty)
                    .map((packer) {
                      final prods = _data[packer.id] ?? [];
                      final bundles = prods.fold(
                          0, (s, p) => s + p.bundleCount);
                      final salary = bundles * 4.0;

                      // Group by product
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

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return dateStr; }
  }
}

// ── Day navigator ─────────────────────────────────────────────
class _DayNav extends StatelessWidget {
  final String      dateLabel;
  final bool        isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onPickDate;

  const _DayNav({
    required this.dateLabel,
    required this.isToday,
    required this.onPrev,
    required this.onPickDate,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.packer.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.packer,
            iconSize: 20,
            onPressed: onPrev,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onPickDate,
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15, color: AppColors.packer),
                    const SizedBox(width: 6),
                    Text(
                      isToday ? 'Today — $dateLabel' : dateLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const Text('Tap to pick a date',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textHint)),
              ]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext != null
                    ? AppColors.packer
                    : AppColors.textHint.withValues(alpha: 0.3)),
            iconSize: 20,
            onPressed: onNext,
          ),
        ]),
      );
}

// ── Daily packer card ─────────────────────────────────────────
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.20)),
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
            // ── Packer header ──────────────────────────────
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.packer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(packer.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text)),
                    Text('${prods.length} entries',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$bundles bundles',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.packer)),
                  Text(formatCurrency(salary),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark)),
                ],
              ),
            ]),

            const SizedBox(height: 10),
            Container(height: 1,
                color: AppColors.packer.withValues(alpha: 0.10)),
            const SizedBox(height: 10),

            // ── Product breakdown ──────────────────────────
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
                              color: AppColors.textSecondary)),
                    ),
                    Text('${e.value} bundles',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.packer)),
                    const SizedBox(width: 10),
                    Text(formatCurrency(e.value * 4.0),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ]),
                )),

            const SizedBox(height: 10),

            // ── Entry log with timestamps ──────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 5),
                  Text('ENTRY LOG',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHint
                              .withValues(alpha: 0.8),
                          letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 6),
                ...prods.map((p) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 5, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(p.productName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ),
                        Text('${p.bundleCount} bundles',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.packer)),
                        const SizedBox(width: 8),
                        Text(_formatTime(p.timestamp),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint)),
                      ]),
                    )),
              ]),
            ),
          ],
        ),
      );
}

// ── Daily summary banner ──────────────────────────────────────
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
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.packer.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BannerStat(
                icon: Icons.people_outline,
                label: 'Active',
                value: '$packerCount'),
            _BannerDivider(),
            _BannerStat(
                icon: Icons.inventory_2_outlined,
                label: 'Bundles',
                value: '$totalBundles'),
            _BannerDivider(),
            _BannerStat(
                icon: Icons.payments_outlined,
                label: 'Total Salary',
                value: formatCurrency(totalSalary)),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════
class _DayEntry {
  final String date;
  final int    bundles;
  final double salary;
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
            color: AppColors.packer.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.packer, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.3)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ]),
      ]);
}

class _WeekNav extends StatelessWidget {
  final String       weekStart;
  final String       weekEnd;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _WeekNav({
    required this.weekStart,
    required this.weekEnd,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.packer.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.packer.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.packer,
            iconSize: 20,
            onPressed: onPrev,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range_outlined,
                    size: 15,
                    color: AppColors.packer.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text('$weekStart — $weekEnd',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primaryDark)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.packer,
            iconSize: 20,
            onPressed: onNext,
          ),
        ]),
      );
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
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.packer.withValues(alpha: 0.8),
                letterSpacing: 0.8)),
      ]);
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _BannerStat(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 10)),
      ]);
}

class _BannerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 34,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
        ]),
      );
}