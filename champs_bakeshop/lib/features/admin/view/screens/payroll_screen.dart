import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import 'payroll_packer_screen.dart';
import 'payroll_seller_screen.dart';

// ══════════════════════════════════════════════════════════════
//  ROOT — 3-tab switcher
// ══════════════════════════════════════════════════════════════
class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  State<AdminPayrollScreen> createState() =>
      _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _tabs = [
    '👨‍🍳  Baker / Helper',
    '📦  Packer',
    '🥖  Seller',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
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
            _BakerHelperPayrollTab(),
            PackerPayrollTab(),
            SellerPayrollTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  BAKER / HELPER TAB
// ══════════════════════════════════════════════════════════════
class _BakerHelperPayrollTab extends StatefulWidget {
  const _BakerHelperPayrollTab();

  @override
  State<_BakerHelperPayrollTab> createState() =>
      _BakerHelperPayrollTabState();
}

class _BakerHelperPayrollTabState
    extends State<_BakerHelperPayrollTab> {
  // ── Default: current month ───────────────────────────────────
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadCurrentWeek());
  }

  // ── Current week helpers ─────────────────────────────────────
  String get _currentWeekStart => getWeekStart(DateTime.now());

  bool get _isCurrentWeek {
    final payVM = context.read<AdminPayrollViewModel>();
    return payVM.weekStart == _currentWeekStart;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  String get _monthLabel {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${names[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  // ── Loaders ──────────────────────────────────────────────────
  void _loadCurrentWeek() {
    final payVM  = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    payVM.loadWeeklyPayroll(
        _currentWeekStart,
        prodVM.products,
        userVM.userNameMap,
        userVM.userRoleMap);
  }

  void _load() {
    final payVM  = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    final ws     = payVM.weekStart.isEmpty
        ? _currentWeekStart
        : payVM.weekStart;
    payVM.loadWeeklyPayroll(
        ws, prodVM.products, userVM.userNameMap, userVM.userRoleMap);
  }

  void _changeWeek(int dir) {
    final payVM  = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    // Block going forward past current week
    if (dir > 0 && _isCurrentWeek) return;
    payVM.changeWeek(
        dir, prodVM.products, userVM.userNameMap, userVM.userRoleMap);
  }

  void _changeMonth(int dir) {
    final next =
        DateTime(_selectedMonth.year, _selectedMonth.month + dir);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
    final firstDay =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monday =
        firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final ws     = monday.toString().split(' ')[0];
    final payVM  = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    payVM.loadWeeklyPayroll(
        ws, prodVM.products, userVM.userNameMap, userVM.userRoleMap);
  }

  Future<void> _pickMonth() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedMonth,
      firstDate:   DateTime(2024),
      lastDate:    now,
      helpText:    'Select Month',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary:   AppColors.primary,
              onSurface: AppColors.text),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() =>
          _selectedMonth = DateTime(picked.year, picked.month));
      _changeMonth(0);
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────
  void _showDeductionDialog(PayrollEntry entry) {
    final isHelper = entry.role != 'master_baker';
    final autoOven = isHelper ? entry.daysWorked * 20.0 : 0.0;
    final ovenCtrl = TextEditingController(
        text: entry.ovenDeduction.toStringAsFixed(0));
    final gasCtrl  = TextEditingController(
        text: entry.gasDeduction.toStringAsFixed(0));
    final valeCtrl = TextEditingController(
        text: entry.valeDeduction.toStringAsFixed(0));
    final wifiCtrl = TextEditingController(
        text: entry.wifiDeduction.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.remove_circle_outline,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deductions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text(entry.name,
                    style: const TextStyle(
                        fontSize:   12,
                        color:      AppColors.textHint,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHelper
                      ? AppColors.info.withValues(alpha: 0.06)
                      : AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.microwave_outlined,
                      size: 15,
                      color: isHelper
                          ? AppColors.info
                          : AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHelper
                          ? 'Auto: ₱${autoOven.toStringAsFixed(0)} (₱20 × ${entry.daysWorked}d). Override below.'
                          : 'Master Baker — no oven deduction.',
                      style: TextStyle(
                          fontSize: 11,
                          color: isHelper
                              ? AppColors.info
                              : AppColors.textHint),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              _DeducField(
                controller: ovenCtrl,
                label:   'Oven (₱)',
                icon:    Icons.microwave_outlined,
                enabled: isHelper,
                hint:    autoOven.toStringAsFixed(0),
                helper:  isHelper
                    ? 'Leave 0 to use auto amount'
                    : 'N/A for master baker',
              ),
              const Divider(height: 24),
              _DeducField(
                  controller: gasCtrl,
                  label: 'Gas (₱)',
                  icon:  Icons.local_fire_department_outlined),
              const SizedBox(height: 12),
              _DeducField(
                  controller: valeCtrl,
                  label: 'Vale (₱)',
                  icon:  Icons.money_outlined),
              const SizedBox(height: 12),
              _DeducField(
                  controller: wifiCtrl,
                  label: 'Wifi (₱)',
                  icon:  Icons.wifi),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () async {
              final payVM     =
                  context.read<AdminPayrollViewModel>();
              final messenger =
                  ScaffoldMessenger.of(context);
              await payVM.saveDeduction(
                userId:    entry.userId,
                weekStart: payVM.weekStart,
                oven:  double.tryParse(ovenCtrl.text)  ?? 0,
                gas:   double.tryParse(gasCtrl.text)   ?? 0,
                vale:  double.tryParse(valeCtrl.text)  ?? 0,
                wifi:  double.tryParse(wifiCtrl.text)  ?? 0,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                    content: const Text('Deductions saved!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmMarkPaid(PayrollEntry entry) {
    final adminId =
        context.read<AuthViewModel>().currentUser?.id ?? 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Confirm Payment',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Mark ${entry.name} as paid for this week?',
              style: const TextStyle(
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Final Salary',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(formatCurrency(entry.finalSalary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color:      AppColors.success,
                        fontSize:   20)),
              ],
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton.icon(
            icon:  const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Confirm Paid'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final payVM     =
                  context.read<AdminPayrollViewModel>();
              final messenger =
                  ScaffoldMessenger.of(context);
              final ok = await payVM.markAsPaid(
                userId: entry.userId,
                paidBy: adminId,
                amount: entry.finalSalary,
              );
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? '${entry.name} marked as paid!'
                      : 'Error saving payment.'),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmMarkAllPaid(List<PayrollEntry> unpaid) {
    final adminId =
        context.read<AuthViewModel>().currentUser?.id ?? 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Pay All',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Text(
          'Mark all ${unpaid.length} unpaid employee${unpaid.length > 1 ? 's' : ''} as paid this week?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton.icon(
            icon:  const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Pay All'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final payVM     =
                  context.read<AdminPayrollViewModel>();
              final messenger =
                  ScaffoldMessenger.of(context);
              final ok =
                  await payVM.markAllAsPaid(paidBy: adminId);
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'All employees marked as paid!'
                      : 'Error saving payments.'),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payVM = context.watch<AdminPayrollViewModel>();

    // ── Sort: unpaid first, paid last ────────────────────────
    final sortedEntries = [...payVM.entries]
      ..sort((a, b) {
        if (a.isPaid == b.isPaid) return 0;
        return a.isPaid ? 1 : -1; // unpaid floats to top
      });

    final unpaidEntries =
        sortedEntries.where((e) => !e.isPaid).toList();
    final paidCount =
        sortedEntries.where((e) => e.isPaid).length;

    final isThisWeek = payVM.weekStart.isNotEmpty &&
        payVM.weekStart == _currentWeekStart;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Page header ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _PageHeader(
                title:    'Baker / Helper Payroll',
                subtitle: 'Automated salary computation',
                icon:     Icons.payments_outlined,
              ),
              // This week shortcut
              if (!isThisWeek)
                GestureDetector(
                  onTap: _loadCurrentWeek,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary
                              .withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today_outlined,
                              size: 12,
                              color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('This Week',
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColors.primary)),
                        ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Month navigator ──────────────────────────────
          _MonthNavigator(
            label:          _monthLabel,
            isCurrentMonth: _isCurrentMonth,
            onPrev:         () => _changeMonth(-1),
            onNext:         _isCurrentMonth
                ? null
                : () => _changeMonth(1),
            onTap: _pickMonth,
          ),
          const SizedBox(height: 10),

          // ── Week navigator ───────────────────────────────
          _WeekNavigator(
            weekStart:     payVM.weekStart,
            weekEnd:       payVM.weekEnd,
            isCurrentWeek: isThisWeek,
            onPrev:        () => _changeWeek(-1),
            onNext:        isThisWeek ? null : () => _changeWeek(1),
          ),
          const SizedBox(height: 16),

          // ── Content ──────────────────────────────────────
          if (payVM.isLoading)
            const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary))
          else if (sortedEntries.isEmpty)
            const _EmptyPayroll(
                message: 'No production data for this week.')
          else ...[
            _PaymentProgressBar(
              paidCount:   paidCount,
              totalCount:  sortedEntries.length,
              unpaid:      unpaidEntries,
              isPaying:    payVM.isPaying,
              onPayAll:    () => _confirmMarkAllPaid(unpaidEntries),
              accentColor: AppColors.primary,
            ),
            const SizedBox(height: 16),

            // ── Unpaid section label ─────────────────────
            if (unpaidEntries.isNotEmpty) ...[
              _SectionDivider(
                label: 'UNPAID  ·  ${unpaidEntries.length}',
                color: AppColors.danger,
              ),
              const SizedBox(height: 8),
              ...unpaidEntries.map((e) => _EmployeeCard(
                    entry:            e,
                    onEditDeductions: () => _showDeductionDialog(e),
                    onMarkPaid:       () => _confirmMarkPaid(e),
                    isPaying:         payVM.isPaying,
                  )),
              const SizedBox(height: 8),
            ],

            // ── Paid section label ───────────────────────
            if (paidCount > 0) ...[
              _SectionDivider(
                label: 'PAID  ·  $paidCount',
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              ...sortedEntries
                  .where((e) => e.isPaid)
                  .map((e) => _EmployeeCard(
                        entry:            e,
                        onEditDeductions: () =>
                            _showDeductionDialog(e),
                        onMarkPaid: () => _confirmMarkPaid(e),
                        isPaying:   payVM.isPaying,
                      )),
              const SizedBox(height: 8),
            ],

            _TotalPayrollBanner(total: payVM.totalPayroll),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MONTH NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _MonthNavigator extends StatelessWidget {
  final String        label;
  final bool          isCurrentMonth;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onTap;

  const _MonthNavigator({
    required this.label,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
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
        child: Row(children: [
          _PayNavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size:  15,
                        color: isCurrentMonth
                            ? AppColors.primary
                            : AppColors.textHint),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize:   14,
                            color: isCurrentMonth
                                ? AppColors.primary
                                : AppColors.text,
                            letterSpacing: -0.2)),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('THIS MONTH',
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
              ),
            ),
          ),
          _PayNavBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  WEEK NAVIGATOR
// ─────────────────────────────────────────────────────────────
class _WeekNavigator extends StatelessWidget {
  final String        weekStart;
  final String        weekEnd;
  final bool          isCurrentWeek;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.weekEnd,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
  });


  String get _label {
    if (weekStart.isEmpty) return '—';
    final s = DateTime.tryParse(weekStart);
    final e = DateTime.tryParse(weekEnd);
    if (s == null || e == null) return '$weekStart – $weekEnd';
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    if (s.month == e.month) {
      return '${m[s.month - 1]} ${s.day}–${e.day}, ${s.year}';
    }
    return '${m[s.month - 1]} ${s.day} – ${m[e.month - 1]} ${e.day}, ${e.year}';
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isCurrentWeek
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentWeek
                ? AppColors.primary.withValues(alpha: 0.25)
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
          _PayNavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range_outlined,
                      size:  15,
                      color: isCurrentWeek
                          ? AppColors.primary
                          : AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(_label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize:   13,
                          color: isCurrentWeek
                              ? AppColors.primary
                              : AppColors.primaryDark,
                          letterSpacing: -0.2)),
                  if (isCurrentWeek) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
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
          _PayNavBtn(
            icon:     Icons.chevron_right,
            onTap:    onNext,
            disabled: onNext == null,
          ),
        ]),
      );
}

class _PayNavBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          disabled;
  const _PayNavBtn(
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
                  : AppColors.primary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  SECTION DIVIDER (Unpaid / Paid labels)
// ─────────────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  final String label;
  final Color  color;
  const _SectionDivider({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      color,
                letterSpacing: 0.8)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: color.withValues(alpha: 0.2),
          ),
        ),
      ]);
}

// ══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════════════

class _TotalPayrollBanner extends StatelessWidget {
  final double total;
  const _TotalPayrollBanner({required this.total});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFA03A)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      const Color(0xFFFF7A00).withValues(alpha: 0.3),
              blurRadius: 14,
              offset:     const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL PAYROLL',
                    style: TextStyle(
                        color:         Colors.white70,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1,
                        fontSize:      11)),
                SizedBox(height: 4),
                Text('This week',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
            Text(formatCurrency(total),
                style: const TextStyle(
                    color:         Colors.white,
                    fontWeight:    FontWeight.w900,
                    fontSize:      26,
                    letterSpacing: -0.5)),
          ],
        ),
      );
}

class _PaymentProgressBar extends StatelessWidget {
  final int           paidCount;
  final int           totalCount;
  final List<dynamic> unpaid;
  final bool          isPaying;
  final VoidCallback  onPayAll;
  final Color         accentColor;
  const _PaymentProgressBar({
    required this.paidCount,
    required this.totalCount,
    required this.unpaid,
    required this.isPaying,
    required this.onPayAll,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final allPaid  = paidCount == totalCount && totalCount > 0;
    final color    = allPaid ? AppColors.success : accentColor;
    final progress =
        totalCount > 0 ? paidCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              allPaid
                  ? Icons.check_circle_outline
                  : Icons.payments_outlined,
              color: color, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allPaid
                      ? 'All paid!'
                      : '${totalCount - paidCount} unpaid',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   13,
                      color:      color),
                ),
                Text('$paidCount of $totalCount paid',
                    style: const TextStyle(
                        fontSize: 11,
                        color:    AppColors.textHint)),
              ],
            ),
          ),
          if (!allPaid)
            FilledButton(
              onPressed: isPaying ? null : onPayAll,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                textStyle: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700),
              ),
              child: const Text('Pay All'),
            ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           progress,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor:      AlwaysStoppedAnimation<Color>(color),
            minHeight:       5,
          ),
        ),
      ]),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final PayrollEntry entry;
  final VoidCallback onEditDeductions;
  final VoidCallback onMarkPaid;
  final bool         isPaying;
  const _EmployeeCard({
    required this.entry,
    required this.onEditDeductions,
    required this.onMarkPaid,
    required this.isPaying,
  });

  @override
  Widget build(BuildContext context) {
    final e         = entry;
    final isBaker   = e.role == 'master_baker';
    final roleColor =
        isBaker ? AppColors.masterBaker : AppColors.helper;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: e.isPaid
            ? Border.all(
                color: AppColors.danger.withValues(alpha: 0.25),
                width: 1.5)
            : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color:        roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.name.isNotEmpty
                      ? e.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize:   18,
                      color:      roleColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize:   15)),
                    const SizedBox(height: 3),
                    Row(children: [
                      RoleBadge(role: e.role),
                      const SizedBox(width: 8),
                      Text('${e.daysWorked} days',
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColors.textHint)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCurrency(e.finalSalary),
                      style: const TextStyle(
                          fontSize:   20,
                          fontWeight: FontWeight.w900,
                          color:      Color(0xFF1A1A1A))),
                  const Text('Take-Home',
                      style: TextStyle(
                          fontSize: 10,
                          color:    AppColors.textHint)),
                ],
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            BreakdownRow(
                label: 'Gross Salary',
                value: formatCurrency(e.grossSalary),
                color: AppColors.success),
            if (e.bonusTotal > 0)
              BreakdownRow(
                  label: 'Sack Bonus',
                  value: formatCurrency(e.bonusTotal),
                  color: AppColors.masterBaker),
            if (e.ovenDeduction > 0)
              BreakdownRow(
                  label: 'Oven',
                  value: '-${formatCurrency(e.ovenDeduction)}',
                  color: AppColors.danger),
            if (e.gasDeduction > 0)
              BreakdownRow(
                  label: 'Gas',
                  value: '-${formatCurrency(e.gasDeduction)}',
                  color: AppColors.danger),
            if (e.valeDeduction > 0)
              BreakdownRow(
                  label: 'Vale',
                  value: '-${formatCurrency(e.valeDeduction)}',
                  color: AppColors.danger),
            if (e.wifiDeduction > 0)
              BreakdownRow(
                  label: 'Wifi',
                  value: '-${formatCurrency(e.wifiDeduction)}',
                  color: AppColors.danger),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditDeductions,
                  icon:  const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Deductions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary
                            .withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── PAID = red badge  |  UNPAID = green button ──
              e.isPaid
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger
                                .withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size:  16,
                              color: AppColors.danger),
                          SizedBox(width: 6),
                          Text('Paid',
                              style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColors.danger)),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: isPaying ? null : onMarkPaid,
                      icon:  const Icon(
                          Icons.payments_outlined, size: 16),
                      label: const Text('Mark Paid'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final IconData icon;
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        const Color(0xFFFF7A00)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: const Color(0xFFFF7A00), size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1A1A),
                    letterSpacing: -0.3)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12,
                    color:    AppColors.textHint)),
          ],
        ),
      ]);
}

class _EmptyPayroll extends StatelessWidget {
  final String message;
  const _EmptyPayroll({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No data',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  color:      Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 13,
                  color:    AppColors.textSecondary)),
        ]),
      );
}

class _DeducField extends StatelessWidget {
  final TextEditingController controller;
  final String   label;
  final IconData icon;
  final bool     enabled;
  final String?  hint;
  final String?  helper;
  const _DeducField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.hint,
    this.helper,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller:   controller,
        keyboardType: TextInputType.number,
        enabled:      enabled,
        decoration: InputDecoration(
          labelText:  label,
          hintText:   hint,
          helperText: helper,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
          filled:    !enabled,
          fillColor: enabled
              ? null
              : AppColors.border.withValues(alpha: 0.3),
        ),
      );
}