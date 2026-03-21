import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_session_viewmodel.dart';

class SellerDailyScreen extends StatefulWidget {
  const SellerDailyScreen({super.key});

  @override
  State<SellerDailyScreen> createState() => _SellerDailyScreenState();
}

class _SellerDailyScreenState extends State<SellerDailyScreen> {
  // Default to today
  DateTime _selectedDate = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateStr => _selectedDate.toIso8601String().substring(0, 10);

  String get _displayDate {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = _selectedDate;
    return '${weekdays[d.weekday - 1]}, ${months[d.month]} ${d.day}, ${d.year}';
  }

  void _loadDate() {
    final uid = context.read<AuthViewModel>().currentUser!.id;
    context.read<SellerSessionViewModel>().loadDateRecord(uid, _dateStr);
  }

  void _changeDay(int dir) {
    final next = _selectedDate.add(Duration(days: dir));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _loadDate();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: AppColors.seller, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadDate();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDate());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SellerSessionViewModel>();

    final remittances = [
      if (vm.morningRemittance != null) vm.morningRemittance!,
      if (vm.afternoonRemittance != null) vm.afternoonRemittance!,
    ];

    final totalRemitted = remittances.fold(0.0, (s, r) => s + r.actualRemittance);
    final totalSalary   = remittances.fold(0.0, (s, r) => s + r.salary);
    final totalSold     = remittances.fold(0, (s, r) => s + r.piecesSold);

    return RefreshIndicator(
      color: AppColors.seller,
      onRefresh: () async => _loadDate(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PageHeader(
            title: 'Daily Records',
            subtitle: 'Your pandesal sales per day',
          ),
          const SizedBox(height: 16),

          // ── Day navigator ────────────────────────────────
          _DayNav(
            displayDate: _displayDate,
            isToday:     _isToday,
            onPrev:      () => _changeDay(-1),
            onNext:      _isToday ? null : () => _changeDay(1),
            onCalendar:  _pickDate,
          ),
          const SizedBox(height: 16),

          if (vm.isLoading)
            const _Loader()
          else ...[

            // ── Summary stats ────────────────────────────
            if (remittances.isNotEmpty) ...[
              _DayStatRow(
                totalSold:     totalSold,
                totalRemitted: totalRemitted,
                totalSalary:   totalSalary,
              ),
              const SizedBox(height: 16),
            ],

            const _SectionLabel('SESSION RECORDS'),
            const SizedBox(height: 10),

            if (!vm.hasMorningSession && !vm.hasAfternoonSession)
              _EmptyCard(
                icon:    Icons.receipt_long_outlined,
                message: 'No sessions recorded for $_displayDate',
              )
            else ...[
              if (vm.hasMorningSession)
                _SessionRecordCard(
                  label:   'Morning',
                  icon:    Icons.wb_sunny_outlined,
                  color:   AppColors.seller,
                  session: vm.morningSession!,
                  remit:   vm.morningRemittance,
                  index:   0,
                ),
              if (vm.hasAfternoonSession)
                _SessionRecordCard(
                  label:   'Afternoon',
                  icon:    Icons.wb_twilight_outlined,
                  color:   AppColors.warning,
                  session: vm.afternoonSession!,
                  remit:   vm.afternoonRemittance,
                  index:   1,
                ),
              if (remittances.isNotEmpty)
                _DayTotalFooter(
                  totalRemitted: totalRemitted,
                  totalSalary:   totalSalary,
                  totalSold:     totalSold,
                ),
            ],
          ],
        ]),
      ),
    );
  }
}

// ── Day navigator ─────────────────────────────────────────────
class _DayNav extends StatelessWidget {
  final String        displayDate;
  final bool          isToday;
  final VoidCallback  onPrev;
  final VoidCallback? onNext;
  final VoidCallback  onCalendar;

  const _DayNav({
    required this.displayDate, required this.isToday,
    required this.onPrev, required this.onCalendar, this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.seller.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.seller.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.seller, iconSize: 20, onPressed: onPrev,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onCalendar,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.seller.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    isToday ? '$displayDate (Today)' : displayDate,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13,
                        color: isToday ? AppColors.seller : AppColors.primaryDark),
                  ),
                ]),
                const Text('Tap to pick a date',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              ]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext != null
                    ? AppColors.seller
                    : AppColors.seller.withValues(alpha: 0.25)),
            iconSize: 20, onPressed: onNext,
          ),
        ]),
      );
}

// ── Day stat row ──────────────────────────────────────────────
class _DayStatRow extends StatelessWidget {
  final int    totalSold;
  final double totalRemitted;
  final double totalSalary;
  const _DayStatRow({
    required this.totalSold, required this.totalRemitted, required this.totalSalary,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(child: _MiniStat(
            icon: Icons.sell_outlined, label: 'Pieces Sold',
            value: '$totalSold', color: AppColors.success,
          )),
          const SizedBox(width: 10),
          Expanded(child: _MiniStat(
            icon: Icons.payments_outlined, label: 'Remitted',
            value: formatCurrency(totalRemitted), color: AppColors.seller,
          )),
        ]),
        if (totalSalary > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.seller.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.seller.withValues(alpha: 0.18)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [
                Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.seller),
                SizedBox(width: 6),
                Text('Total Daily Salary',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ]),
              Text(formatCurrency(totalSalary),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.seller)),
            ]),
          ),
        ],
      ]);
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _MiniStat({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ]),
      );
}

// ── Session record card ───────────────────────────────────────
class _SessionRecordCard extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final dynamic  session;
  final dynamic  remit;
  final int      index;

  const _SessionRecordCard({
    required this.label, required this.icon, required this.color,
    required this.session, required this.index, this.remit,
  });

  Color get _varianceColor {
    if (remit == null) return AppColors.textHint;
    if (remit!.variance > 0) return AppColors.success;
    if (remit!.variance < 0) return AppColors.danger;
    return AppColors.textHint;
  }

  @override
  Widget build(BuildContext context) {
    final hasRemit = remit != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 80),
      curve: Curves.easeOut,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasRemit
                ? AppColors.success.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.20),
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
              Text(
                '${session.plantsaCount} plantsa + ${session.subraPieces} subra'
                ' = ${session.totalPiecesTaken} pcs',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasRemit
                    ? AppColors.success.withValues(alpha: 0.10)
                    : AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hasRemit ? '✓ Remitted' : 'Pending',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: hasRemit ? AppColors.success : AppColors.warning),
              ),
            ),
          ]),

          if (hasRemit) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.12)),
              ),
              child: Row(children: [
                _Stat(label: 'Returned', value: '${remit!.returnPieces} pcs', color: AppColors.warning),
                const SizedBox(width: 14),
                _Stat(label: 'Sold',     value: '${remit!.piecesSold} pcs', color: AppColors.success),
                const Spacer(),
                _Stat(label: 'Cash', value: formatCurrency(remit!.actualRemittance),
                    color: AppColors.primaryDark, bold: true),
              ]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _varianceColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Expected: ${formatCurrency(remit!.adjustedRemittance)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  'Variance: ${remit!.variance >= 0 ? '+' : ''}${formatCurrency(remit!.variance)}',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _varianceColor),
                ),
              ]),
            ),
            if (remit!.salary > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.seller.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.seller.withValues(alpha: 0.18)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Row(children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 13, color: AppColors.seller),
                    SizedBox(width: 6),
                    Text('Session Salary',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.seller)),
                  ]),
                  Text(formatCurrency(remit!.salary),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.seller)),
                ]),
              ),
            ],
          ] else ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
              ),
              child: const Row(children: [
                Icon(Icons.schedule_outlined, size: 13, color: AppColors.info),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Waiting for admin to record remittance',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                )),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   bold;
  const _Stat({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          Text(value,
              style: TextStyle(fontSize: 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ],
      );
}

// ── Day total footer ──────────────────────────────────────────
class _DayTotalFooter extends StatelessWidget {
  final double totalRemitted;
  final double totalSalary;
  final int    totalSold;
  const _DayTotalFooter({
    required this.totalRemitted, required this.totalSalary, required this.totalSold,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.seller, AppColors.seller.withValues(alpha: 0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.seller.withValues(alpha: 0.28),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOTAL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white70, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(formatCurrency(totalRemitted),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('$totalSold pcs sold',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
            if (totalSalary > 0) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text('Salary: ${formatCurrency(totalSalary)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ],
          ])),
        ]),
      );
}

// ── Shared widgets ────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                  color: AppColors.text, letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: AppColors.seller, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.textHint, letterSpacing: 0.8)),
      ]);
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 40, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
        ]),
      );
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(
            color: AppColors.seller, strokeWidth: 2.5)),
      );
}