import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/packer_production_model.dart';
import '../../../../core/models/packer_payroll_model.dart';
import '../../../../core/services/packer_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

// ══════════════════════════════════════════════════════════════
//  PACKER PAYROLL TAB  — vale deduction only
// ══════════════════════════════════════════════════════════════
class PackerPayrollTab extends StatefulWidget {
  const PackerPayrollTab({super.key});

  @override
  State<PackerPayrollTab> createState() =>
      _PackerPayrollTabState();
}

class _PackerPayrollTabState extends State<PackerPayrollTab> {
  final _service = PackerService();

  DateTime _weekStart = DateTime.now();
  bool     _isLoading = false;
  String?  _error;

  Map<String, List<PackerProductionModel>> _prodData    = {};
  Map<String, PackerPayrollModel?>         _payrollData = {};

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

      final newProds    = <String, List<PackerProductionModel>>{};
      final newPayrolls = <String, PackerPayrollModel?>{};

      await Future.wait(packers.map((p) async {
        final prods = await _service.getProductionsByWeek(
          packerId:  p.id,
          weekStart: _weekStartStr,
          weekEnd:   _weekEndStr,
        );
        final payroll = await _service.getPayrollByWeek(
          packerId:  p.id,
          weekStart: _weekStartStr,
          weekEnd:   _weekEndStr,
        );
        newProds[p.id]    = prods;
        newPayrolls[p.id] = payroll;
      }));

      setState(() {
        _prodData    = newProds;
        _payrollData = newPayrolls;
        _isLoading   = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _changeWeek(int dir) async {
    setState(() =>
        _weekStart = _weekStart.add(Duration(days: 7 * dir)));
    await _load();
  }

  // ── Vale deduction dialog ─────────────────────────────────
  void _showValeDialog(UserModel packer) {
    final existing    = _payrollData[packer.id];
    final prods       = _prodData[packer.id] ?? [];
    final bundles     =
        prods.fold(0, (s, p) => s + p.bundleCount);
    final gross       = bundles * 4.0;
    final currentVale = existing?.valeDeduction ?? 0.0;
    final valeCtrl    = TextEditingController(
        text: currentVale.toStringAsFixed(0));

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
            child: const Icon(Icons.money_outlined,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vale Deduction',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text(packer.name,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.packer.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gross Salary',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                  Text(formatCurrency(gross),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.packer)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller:   valeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:  'Vale (₱)',
                helperText: 'Amount borrowed by packer',
                prefixIcon:
                    const Icon(Icons.money_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.packer, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.packer),
            onPressed: () async {
              final vale      =
                  double.tryParse(valeCtrl.text) ?? 0;
              final messenger =
                  ScaffoldMessenger.of(context);
              try {
                await _service.upsertPayroll(
                  packerId:      packer.id,
                  weekStart:     _weekStartStr,
                  weekEnd:       _weekEndStr,
                  totalBundles:  bundles,
                  grossSalary:   gross,
                  valeDeduction: vale,
                  netSalary:     gross - vale,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
                if (mounted) {
                  messenger.showSnackBar(SnackBar(
                    content: const Text('Vale saved!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.danger,
                  ));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Mark paid ─────────────────────────────────────────────
  void _confirmPackerPaid(UserModel packer) {
    final prods   = _prodData[packer.id] ?? [];
    final payroll = _payrollData[packer.id];
    final bundles =
        prods.fold(0, (s, p) => s + p.bundleCount);
    final gross   = bundles * 4.0;
    final vale    = payroll?.valeDeduction ?? 0.0;
    final net     = gross - vale;

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
          Text('Mark ${packer.name} as paid for this week?',
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
                  color: AppColors.success
                      .withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text('Take-Home',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(formatCurrency(net),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        fontSize: 20)),
              ],
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle_outline,
                size: 18),
            label: const Text('Confirm Paid'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger =
                  ScaffoldMessenger.of(context);
              try {
                await _service.upsertPayroll(
                  packerId:      packer.id,
                  weekStart:     _weekStartStr,
                  weekEnd:       _weekEndStr,
                  totalBundles:  bundles,
                  grossSalary:   gross,
                  valeDeduction: vale,
                  netSalary:     net,
                  isPaid:        true,
                );
                await _load();
                if (mounted) {
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        '${packer.name} marked as paid!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.danger,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packers = context
        .watch<AdminUserViewModel>()
        .nonAdminUsers
        .where((u) => u.isPacker)
        .toList();

    double totalNet = 0;
    for (final p in packers) {
      final prods   = _prodData[p.id] ?? [];
      final payroll = _payrollData[p.id];
      final bundles =
          prods.fold(0, (s, pr) => s + pr.bundleCount);
      final gross   = bundles * 4.0;
      final vale    = payroll?.valeDeduction ?? 0.0;
      totalNet += gross - vale;
    }

    final paidCount = packers
        .where((p) => _payrollData[p.id]?.isPaid == true)
        .length;

    return RefreshIndicator(
      color: AppColors.packer,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PackerPageHeader(),
            const SizedBox(height: 16),

            // ── Week navigator ─────────────────────────────
            _PackerWeekNav(
              weekStart: _weekStartStr,
              weekEnd:   _weekEndStr,
              onPrev:    () => _changeWeek(-1),
              onNext:    () => _changeWeek(1),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.packer))
            else if (_error != null)
              _PackerErrCard(_error!)
            else if (packers.isEmpty)
              const _PackerEmpty(
                  message: 'No packers found.')
            else ...[
              // ── Progress bar ────────────────────────────
              _PackerProgressBar(
                paidCount:  paidCount,
                totalCount: packers.length,
              ),
              const SizedBox(height: 16),

              // ── Per-packer cards ─────────────────────────
              ...packers.map((packer) {
                final prods   = _prodData[packer.id] ?? [];
                final payroll = _payrollData[packer.id];
                final bundles = prods.fold(
                    0, (s, p) => s + p.bundleCount);
                final gross   = bundles * 4.0;
                final vale    =
                    payroll?.valeDeduction ?? 0.0;
                final net     = gross - vale;
                final isPaid  = payroll?.isPaid ?? false;

                return _PackerPayrollCard(
                  packer:     packer,
                  bundles:    bundles,
                  gross:      gross,
                  vale:       vale,
                  net:        net,
                  isPaid:     isPaid,
                  onVale:     () => _showValeDialog(packer),
                  onMarkPaid: () =>
                      _confirmPackerPaid(packer),
                );
              }),

              // ── Total ────────────────────────────────────
              _PackerTotalBanner(total: totalNet),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PACKER PAYROLL CARD
// ══════════════════════════════════════════════════════════════
class _PackerPayrollCard extends StatelessWidget {
  final UserModel    packer;
  final int          bundles;
  final double       gross;
  final double       vale;
  final double       net;
  final bool         isPaid;
  final VoidCallback onVale;
  final VoidCallback onMarkPaid;

  const _PackerPayrollCard({
    required this.packer,
    required this.bundles,
    required this.gross,
    required this.vale,
    required this.net,
    required this.isPaid,
    required this.onVale,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPaid
              ? Border.all(
                  color:
                      AppColors.success.withValues(alpha: 0.3),
                  width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color:
                        AppColors.packer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    packer.name.isNotEmpty
                        ? packer.name[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.packer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(packer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.packer
                                .withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: const Text('Packer',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.packer)),
                        ),
                        const SizedBox(width: 8),
                        Text('$bundles bundles',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint)),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCurrency(net),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A))),
                    const Text('Take-Home',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint)),
                  ],
                ),
              ]),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Breakdown ────────────────────────────────
              BreakdownRow(
                  label: 'Gross ($bundles × ₱4.00)',
                  value: formatCurrency(gross),
                  color: AppColors.success),
              if (vale > 0)
                BreakdownRow(
                    label: 'Vale',
                    value: '-${formatCurrency(vale)}',
                    color: AppColors.danger),

              const SizedBox(height: 14),

              // ── Buttons ──────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVale,
                    icon: const Icon(Icons.money_outlined,
                        size: 16),
                    label: const Text('Set Vale'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.packer,
                      side: BorderSide(
                          color: AppColors.packer
                              .withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                isPaid
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.success
                                  .withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 16,
                                color: AppColors.success),
                            SizedBox(width: 6),
                            Text('Paid',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppColors.success)),
                          ],
                        ),
                      )
                    : FilledButton.icon(
                        onPressed:
                            bundles > 0 ? onMarkPaid : null,
                        icon: const Icon(
                            Icons.payments_outlined,
                            size: 16),
                        label: const Text('Mark Paid'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 12,
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

// ── Small shared widgets ──────────────────────────────────────
class _PackerPageHeader extends StatelessWidget {
  const _PackerPageHeader();

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2_outlined,
              color: Color(0xFFFF7A00), size: 22),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Packer Payroll',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3)),
            Text('Vale deduction only',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      ]);
}

class _PackerWeekNav extends StatelessWidget {
  final String       weekStart;
  final String       weekEnd;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _PackerWeekNav({
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
                    color:
                        AppColors.packer.withValues(alpha: 0.8)),
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

class _PackerProgressBar extends StatelessWidget {
  final int paidCount;
  final int totalCount;
  const _PackerProgressBar({
    required this.paidCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final allPaid  = paidCount == totalCount && totalCount > 0;
    final color    = allPaid ? AppColors.success : AppColors.packer;
    final progress =
        totalCount > 0 ? paidCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                      ? 'All packers paid!'
                      : '${totalCount - paidCount} unpaid',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color),
                ),
                Text('$paidCount of $totalCount paid',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }
}

class _PackerTotalBanner extends StatelessWidget {
  final double total;
  const _PackerTotalBanner({required this.total});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
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
              color: const Color(0xFFFF7A00)
                  .withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontSize: 11)),
                SizedBox(height: 4),
                Text('Packer net this week',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11)),
              ],
            ),
            Text(formatCurrency(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5)),
          ],
        ),
      );
}

class _PackerEmpty extends StatelessWidget {
  final String message;
  const _PackerEmpty({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Text('📦',
                style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          const Text('No packers',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ]),
      );
}

class _PackerErrCard extends StatelessWidget {
  final String message;
  const _PackerErrCard(this.message);

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