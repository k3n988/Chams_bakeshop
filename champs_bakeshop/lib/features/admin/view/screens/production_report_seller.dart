import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/seller_session_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/seller_service.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

class ProductionReportSeller extends StatefulWidget {
  const ProductionReportSeller({super.key});

  @override
  State<ProductionReportSeller> createState() =>
      _ProductionReportSellerState();
}

class _ProductionReportSellerState
    extends State<ProductionReportSeller>
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
            labelColor: AppColors.seller,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.seller,
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
            _SellerWeeklyReportTab(),
            _SellerDailyReportTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  WEEKLY TAB
// ══════════════════════════════════════════════════════════════
class _SellerWeeklyReportTab extends StatefulWidget {
  const _SellerWeeklyReportTab();

  @override
  State<_SellerWeeklyReportTab> createState() =>
      _SellerWeeklyReportTabState();
}

class _SellerWeeklyReportTabState
    extends State<_SellerWeeklyReportTab> {
  final _service = SellerService();
  late DateTime _weekStart;
  bool    _isLoading = false;
  String? _error;
  String? _expandedSellerId;
  Map<String, List<SellerSessionModel>> _data = {};

  @override
  void initState() {
    super.initState();
    // ── Default: current week (Monday) ──────────────────
    _weekStart = _currentMonday();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
  }

  // ── Helpers ─────────────────────────────────────────────────
  DateTime _currentMonday() {
    final now  = DateTime.now();
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

  String _fmtWeek(String ws, String we) {
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

  // ── Data ─────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final sellers = context
          .read<AdminUserViewModel>()
          .nonAdminUsers
          .where((u) => u.isSeller)
          .toList();
      final newData = <String, List<SellerSessionModel>>{};
      await Future.wait(sellers.map((s) async {
        final sessions = await _service.getSessionsByRange(
          sellerId: s.id,
          fromDate: _weekStartStr,
          toDate:   _weekEndStr,
        );
        newData[s.id] = sessions;
      }));
      setState(() { _data = newData; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellers = context
        .watch<AdminUserViewModel>()
        .nonAdminUsers
        .where((u) => u.isSeller)
        .toList();

    int    totalPieces   = 0;
    double totalExpected = 0;
    for (final s in sellers) {
      for (final session in _data[s.id] ?? []) {
        totalPieces   += (session.totalPiecesTaken as num).toInt();
        totalExpected += (session.expectedRemittance as num).toDouble();
      }
    }

    return RefreshIndicator(
      color: AppColors.seller,
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
                const _Header(
                  title:    'Seller Weekly Report',
                  subtitle: 'Sessions & pieces per seller',
                  icon:     Icons.storefront_outlined,
                ),
                // This week shortcut
                if (!_isCurrentWeek)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _weekStart        = _currentMonday();
                        _expandedSellerId = null;
                      });
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.seller
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.seller
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 12,
                                color: AppColors.seller),
                            SizedBox(width: 4),
                            Text('This Week',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.seller)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Week navigator ───────────────────────────
            _WeekNav(
              label:         _fmtWeek(_weekStartStr, _weekEndStr),
              isCurrentWeek: _isCurrentWeek,
              onPrev: () {
                setState(() {
                  _weekStart = _weekStart
                      .subtract(const Duration(days: 7));
                  _expandedSellerId = null;
                });
                _load();
              },
              // Disable next when on current week
              onNext: _isCurrentWeek
                  ? null
                  : () {
                      setState(() {
                        _weekStart =
                            _weekStart.add(const Duration(days: 7));
                        _expandedSellerId = null;
                      });
                      _load();
                    },
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const _Loader()
            else if (_error != null)
              _ErrCard(_error!)
            else ...[
              if (totalPieces > 0)
                _WeeklySummaryBanner(
                  sellerCount:   sellers.length,
                  totalPieces:   totalPieces,
                  totalExpected: totalExpected,
                ),
              const SizedBox(height: 14),
              if (sellers.isEmpty)
                const _EmptyCard(message: 'No sellers found')
              else
                ...sellers.map((seller) {
                  final sessions = _data[seller.id] ?? [];
                  final isExpanded =
                      _expandedSellerId == seller.id;
                  return _ExpandableSellerCard(
                    seller:     seller,
                    sessions:   sessions,
                    isExpanded: isExpanded,
                    onTap: () => setState(() {
                      _expandedSellerId =
                          isExpanded ? null : seller.id;
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
class _SellerDailyReportTab extends StatefulWidget {
  const _SellerDailyReportTab();

  @override
  State<_SellerDailyReportTab> createState() =>
      _SellerDailyReportTabState();
}

class _SellerDailyReportTabState
    extends State<_SellerDailyReportTab> {
  final _service = SellerService();
  // ── Default: today ──────────────────────────────────────────
  late DateTime _selDate;
  bool    _isLoading = false;
  String? _error;
  Map<String, List<SellerSessionModel>> _data = {};

  @override
  void initState() {
    super.initState();
    _selDate = DateTime.now();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selDate.year == now.year &&
        _selDate.month == now.month &&
        _selDate.day == now.day;
  }

  String get _dateStr =>
      _selDate.toIso8601String().substring(0, 10);

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final sellers = context
          .read<AdminUserViewModel>()
          .nonAdminUsers
          .where((u) => u.isSeller)
          .toList();
      final newData = <String, List<SellerSessionModel>>{};
      await Future.wait(sellers.map((s) async {
        final sessions = await _service.getSessionsByRange(
          sellerId: s.id,
          fromDate: _dateStr,
          toDate:   _dateStr,
        );
        newData[s.id] = sessions;
      }));
      setState(() { _data = newData; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _changeDay(int dir) {
    final next = _selDate.add(Duration(days: dir));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selDate = next);
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selDate,
      firstDate:   DateTime(DateTime.now().year - 1),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary:   AppColors.seller,
              onSurface: AppColors.text),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selDate = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellers = context
        .watch<AdminUserViewModel>()
        .nonAdminUsers
        .where((u) => u.isSeller)
        .toList();

    int    totalPieces   = 0;
    double totalExpected = 0;
    for (final s in sellers) {
      for (final session in _data[s.id] ?? []) {
        totalPieces   += (session.totalPiecesTaken as num).toInt();
        totalExpected += (session.expectedRemittance as num).toDouble();
      }
    }
    final activeSellers = sellers
        .where((s) => (_data[s.id] ?? []).isNotEmpty)
        .length;

    return RefreshIndicator(
      color: AppColors.seller,
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
                const _Header(
                  title:    'Seller Daily Report',
                  subtitle: 'All seller sessions for a day',
                  icon:     Icons.receipt_long_outlined,
                ),
                // Today shortcut
                if (!_isToday)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selDate = DateTime.now());
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.seller
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.seller
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined,
                                size: 12,
                                color: AppColors.seller),
                            SizedBox(width: 4),
                            Text('Today',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.seller)),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Day navigator ────────────────────────────
            _DayNav(
              selectedDate: _selDate,
              isToday:      _isToday,
              onPrev:       () => _changeDay(-1),
              onNext:       _isToday ? null : () => _changeDay(1),
              onPick:       _pickDate,
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const _Loader()
            else if (_error != null)
              _ErrCard(_error!)
            else ...[
              if (totalPieces > 0)
                _DailySummaryBanner(
                  activeSellers: activeSellers,
                  totalPieces:   totalPieces,
                  totalExpected: totalExpected,
                ),
              const SizedBox(height: 14),
              if (sellers.isEmpty)
                const _EmptyCard(message: 'No sellers found')
              else if (totalPieces == 0)
                _EmptyCard(message: 'No sessions on $_dateStr')
              else
                ...sellers
                    .where((s) =>
                        (_data[s.id] ?? []).isNotEmpty)
                    .map((seller) {
                      final sessions = _data[seller.id] ?? [];
                      final morning   = sessions
                          .where((s) => s.isMorning)
                          .firstOrNull;
                      final afternoon = sessions
                          .where((s) => s.isAfternoon)
                          .firstOrNull;
                      return _SellerDayCard(
                        seller:    seller,
                        morning:   morning,
                        afternoon: afternoon,
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
              ? AppColors.seller.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentWeek
                ? AppColors.seller.withValues(alpha: 0.25)
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
          _SelNavBtn(
              icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range_outlined,
                      size:  15,
                      color: isCurrentWeek
                          ? AppColors.seller
                          : AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize:   13,
                          color: isCurrentWeek
                              ? AppColors.seller
                              : AppColors.primaryDark,
                          letterSpacing: -0.2)),
                  if (isCurrentWeek) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.seller,
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
          _SelNavBtn(
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
  final VoidCallback  onPick;

  const _DayNav({
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
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
              ? AppColors.seller.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? AppColors.seller.withValues(alpha: 0.25)
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
          _SelNavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onPick,
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
                            ? AppColors.seller
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Text(_label,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize:   13,
                              color: isToday
                                  ? AppColors.seller
                                  : AppColors.primaryDark,
                              letterSpacing: -0.2)),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.seller,
                            borderRadius:
                                BorderRadius.circular(6),
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
          _SelNavBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

// ── Shared nav button ────────────────────────────────────────
class _SelNavBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _SelNavBtn(
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
                  : AppColors.seller),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  ALL REMAINING WIDGETS — UNCHANGED
// ══════════════════════════════════════════════════════════════

class _ExpandableSellerCard extends StatelessWidget {
  final UserModel                  seller;
  final List<SellerSessionModel>   sessions;
  final bool                       isExpanded;
  final VoidCallback               onTap;
  const _ExpandableSellerCard({
    required this.seller,
    required this.sessions,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalPieces   =
        sessions.fold(0, (s, e) => s + e.totalPiecesTaken);
    final totalExpected =
        sessions.fold(0.0, (s, e) => s + e.expectedRemittance);
    final hasData = sessions.isNotEmpty;

    final byDate = <String, List<SellerSessionModel>>{};
    for (final s in sessions) {
      byDate.putIfAbsent(s.date, () => []).add(s);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.seller.withValues(alpha: 0.40)
              : AppColors.border,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: isExpanded
                  ? AppColors.seller.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        InkWell(
          onTap: hasData ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppColors.seller
                      : AppColors.seller.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  seller.name.isNotEmpty ? seller.name[0] : 'S',
                  style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.w900,
                      color: isExpanded
                          ? Colors.white
                          : AppColors.seller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.name,
                        style: const TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w800,
                            color:      AppColors.text)),
                    Text(
                      hasData
                          ? '${byDate.length} days · ${sessions.length} sessions'
                          : 'No sessions this week',
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
                    hasData ? '$totalPieces pcs' : '—',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w800,
                        color: hasData
                            ? AppColors.seller
                            : AppColors.textHint),
                  ),
                  if (hasData)
                    Text(formatCurrency(totalExpected),
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColors.textSecondary)),
                  if (hasData)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18, color: AppColors.seller,
                    ),
                ],
              ),
            ]),
          ),
        ),
        if (isExpanded && hasData) ...[
          Container(height: 1,
              color: AppColors.seller.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...byDate.entries.map((e) {
                  final morning =
                      e.value.where((s) => s.isMorning).firstOrNull;
                  final afternoon = e.value
                      .where((s) => s.isAfternoon)
                      .firstOrNull;
                  return _DaySessionRow(
                      date:      e.key,
                      morning:   morning,
                      afternoon: afternoon);
                }),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.seller,
                        AppColors.seller.withValues(alpha: 0.75),
                      ],
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
                          Text('$totalPieces pieces',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:    Colors.white70)),
                        ],
                      ),
                      Text(formatCurrency(totalExpected),
                          style: const TextStyle(
                              fontSize:   20,
                              fontWeight: FontWeight.w900,
                              color:      Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

class _DaySessionRow extends StatelessWidget {
  final String               date;
  final SellerSessionModel?  morning;
  final SellerSessionModel?  afternoon;
  const _DaySessionRow({
    required this.date,
    this.morning,
    this.afternoon,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:        const Color(0xFFF8F4F0),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: AppColors.seller.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(date.substring(8),
                    style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w800,
                        color:      AppColors.seller)),
              ),
              const SizedBox(width: 8),
              Text(_formatDate(date),
                  style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.text)),
            ]),
            if (morning != null) ...[
              const SizedBox(height: 6),
              _SessionPill(
                  label:    '☀️ Morning',
                  pieces:   morning!.totalPiecesTaken,
                  expected: morning!.expectedRemittance,
                  color:    AppColors.seller),
            ],
            if (afternoon != null) ...[
              const SizedBox(height: 4),
              _SessionPill(
                  label:    '🌅 Afternoon',
                  pieces:   afternoon!.totalPiecesTaken,
                  expected: afternoon!.expectedRemittance,
                  color:    AppColors.warning),
            ],
          ],
        ),
      );

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return d; }
  }
}

class _SessionPill extends StatelessWidget {
  final String label;
  final int    pieces;
  final double expected;
  final Color  color;
  const _SessionPill({
    required this.label,
    required this.pieces,
    required this.expected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        const SizedBox(width: 38),
        Text(label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      color)),
        const SizedBox(width: 8),
        Text('$pieces pcs',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textHint)),
        const Spacer(),
        Text(formatCurrency(expected),
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w700,
                color:      color)),
      ]);
}

class _SellerDayCard extends StatelessWidget {
  final UserModel           seller;
  final SellerSessionModel? morning;
  final SellerSessionModel? afternoon;
  const _SellerDayCard({
    required this.seller,
    this.morning,
    this.afternoon,
  });

  @override
  Widget build(BuildContext context) {
    final total    = (morning?.totalPiecesTaken ?? 0) +
        (afternoon?.totalPiecesTaken ?? 0);
    final expected = (morning?.expectedRemittance ?? 0) +
        (afternoon?.expectedRemittance ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.seller.withValues(alpha: 0.20)),
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
                color: AppColors.seller.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                seller.name.isNotEmpty ? seller.name[0] : 'S',
                style: const TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w900,
                    color:      AppColors.seller),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(seller.name,
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w800,
                          color:      AppColors.text)),
                  Text('$total total pieces',
                      style: const TextStyle(
                          fontSize: 11,
                          color:    AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$total pcs',
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.seller)),
                Text(formatCurrency(expected),
                    style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w900,
                        color:      AppColors.primaryDark)),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          Container(height: 1,
              color: AppColors.seller.withValues(alpha: 0.10)),
          const SizedBox(height: 10),
          if (morning != null)
            _SessionDetailRow(
                label:   '☀️ Morning',
                session: morning!,
                color:   AppColors.seller),
          if (morning != null && afternoon != null)
            const SizedBox(height: 6),
          if (afternoon != null)
            _SessionDetailRow(
                label:   '🌅 Afternoon',
                session: afternoon!,
                color:   AppColors.warning),
        ],
      ),
    );
  }
}

class _SessionDetailRow extends StatelessWidget {
  final String             label;
  final SellerSessionModel session;
  final Color              color;
  const _SessionDetailRow({
    required this.label,
    required this.session,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(
              color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      color)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${session.plantsaCount} plantsa + '
              '${session.subraPieces} subra = '
              '${session.totalPiecesTaken} pcs',
              style: const TextStyle(
                  fontSize: 11,
                  color:    AppColors.textSecondary),
            ),
          ),
          Text(formatCurrency(session.expectedRemittance),
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      color)),
        ]),
      );
}

class _WeeklySummaryBanner extends StatelessWidget {
  final int    sellerCount;
  final int    totalPieces;
  final double totalExpected;
  const _WeeklySummaryBanner({
    required this.sellerCount,
    required this.totalPieces,
    required this.totalExpected,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.seller,
            AppColors.seller.withValues(alpha: 0.75),
          ]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      AppColors.seller.withValues(alpha: 0.25),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BannerStat(icon: Icons.people_outline,
                label: 'Sellers',  value: '$sellerCount'),
            _BannerDiv(),
            _BannerStat(icon: Icons.inventory_2_outlined,
                label: 'Total Pieces', value: '$totalPieces'),
            _BannerDiv(),
            _BannerStat(icon: Icons.payments_outlined,
                label: 'Expected',
                value: formatCurrency(totalExpected)),
          ],
        ),
      );
}

class _DailySummaryBanner extends StatelessWidget {
  final int    activeSellers;
  final int    totalPieces;
  final double totalExpected;
  const _DailySummaryBanner({
    required this.activeSellers,
    required this.totalPieces,
    required this.totalExpected,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.seller,
            AppColors.seller.withValues(alpha: 0.75),
          ]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      AppColors.seller.withValues(alpha: 0.25),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BannerStat(icon: Icons.storefront_outlined,
                label: 'Active',   value: '$activeSellers'),
            _BannerDiv(),
            _BannerStat(icon: Icons.inventory_2_outlined,
                label: 'Pieces',   value: '$totalPieces'),
            _BannerDiv(),
            _BannerStat(icon: Icons.payments_outlined,
                label: 'Expected',
                value: formatCurrency(totalExpected)),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final IconData icon;
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.seller.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.seller, size: 22),
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

class _BannerDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 34,
      color: Colors.white.withValues(alpha: 0.3));
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

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
          Icon(Icons.storefront_outlined,
              size:  40,
              color: AppColors.seller.withValues(alpha: 0.3)),
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
              color: AppColors.seller, strokeWidth: 2.5),
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