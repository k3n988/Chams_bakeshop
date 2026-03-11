import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/helper_salary_viewmodel.dart';

class HelperWeeklyScreen extends StatefulWidget {
  const HelperWeeklyScreen({super.key});

  @override
  State<HelperWeeklyScreen> createState() => _HelperWeeklyScreenState();
}

class _HelperWeeklyScreenState extends State<HelperWeeklyScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  String get _userId => context.read<AuthViewModel>().currentUser!.id;

  void _loadForMonth() {
    context.read<HelperSalaryViewModel>().loadWeeklySalaryForMonth(
          _userId,
          _selectedMonth.year,
          _selectedMonth.month,
        );
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + direction);
    });
    _loadForMonth();
  }

  Future<void> _pickMonth() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:          context,
      initialDate:      _selectedMonth,
      firstDate:        DateTime(now.year - 3),
      lastDate:         DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText:         'SELECT MONTH',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.info),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    _loadForMonth();
  }

  void _changeWeek(int dir) {
    context.read<HelperSalaryViewModel>().changeWeek(dir, _userId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForMonth());
  }

  @override
  Widget build(BuildContext context) {
    final vm         = context.watch<HelperSalaryViewModel>();
    final monthLabel =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return RefreshIndicator(
      color:     AppColors.info,
      onRefresh: () async => _loadForMonth(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title:    'Weekly Salary',
              subtitle: 'Summary for your selected week',
            ),

            // ── Month selector ──
            _MonthSelector(
              label:  monthLabel,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTap:  _pickMonth,
            ),
            const SizedBox(height: 10),

            // ── Week navigator ──
            WeekSelector(
              weekStart: vm.weekStart,
              weekEnd:   vm.weekEnd,
              onPrev:    () => _changeWeek(-1),
              onNext:    () => _changeWeek(1),
            ),
            const SizedBox(height: 14),

            // ── Loading / Error ──
            if (vm.isLoading)
              const _LoadingCard()
            else if (vm.error != null)
              _ErrorCard(message: vm.error!, onRetry: _loadForMonth)
            else ...[
              // ── Stats row ──
              Row(children: [
                Expanded(
                    child: _StatTile(
                  icon:  Icons.payments_outlined,
                  label: 'Gross',
                  value: formatCurrency(vm.grossSalary),
                  color: AppColors.masterBaker,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatTile(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Days',
                  value: '${vm.daysWorked}',
                  color: AppColors.info,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatTile(
                  icon:  Icons.account_balance_wallet_outlined,
                  label: 'Net',
                  value: formatCurrency(vm.finalSalary),
                  color: AppColors.primary,
                )),
              ]),
              const SizedBox(height: 14),

              // ── Deductions card ──
              _DeductionsCard(vm: vm),
              const SizedBox(height: 14),

              // ── Daily breakdown ──
              if (vm.weeklyDaily.isNotEmpty) ...[
                _SectionLabel('DAILY BREAKDOWN'),
                const SizedBox(height: 8),
                ...vm.weeklyDaily.map((d) => _DailyBreakdownTile(
                      date:   d.key,
                      salary: d.value,
                    )),
              ] else
                EmptyState(
                  icon:    Icons.today_outlined,
                  message: 'No records for this week',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAT TILE  (3-column row)
// ─────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color:      color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset:     const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize:   16,
                    color:      color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DEDUCTIONS CARD
// ─────────────────────────────────────────────────────────────
class _DeductionsCard extends StatelessWidget {
  final HelperSalaryViewModel vm;
  const _DeductionsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset:     const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('DEDUCTIONS BREAKDOWN'),
          const SizedBox(height: 14),
          _DedRow(label: 'Oven  (₱${AppConstants.helperOvenDeductionPerDay.toStringAsFixed(0)}/day × ${vm.daysWorked}d)',
              value: vm.ovenDeduction),
          _DedRow(label: 'Gas',   value: vm.gasDeduction),
          _DedRow(label: 'Vale',  value: vm.valeDeduction),
          _DedRow(label: 'Wifi',  value: vm.wifiDeduction),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TAKE-HOME PAY',
                    style: TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w800,
                        color:      AppColors.textHint,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(vm.finalSalary),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize:   26,
                      color:      AppColors.primaryDark),
                ),
              ]),
              // Gross → net visual
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _NetChip(
                    label: 'Gross',
                    value: formatCurrency(vm.grossSalary),
                    color: AppColors.masterBaker),
                const SizedBox(height: 4),
                _NetChip(
                    label: 'Deductions',
                    value: '-${formatCurrency(vm.totalDeductions)}',
                    color: AppColors.danger),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _DedRow extends StatelessWidget {
  final String label;
  final double value;
  const _DedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(
            value > 0 ? '-${formatCurrency(value)}' : '—',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    value > 0 ? AppColors.danger : AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _NetChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _NetChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Roboto'),
          children: [
            TextSpan(
                text: '$label: ',
                style: TextStyle(fontSize: 11, color: color)),
            TextSpan(
                text:  value,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w800,
                    color:      color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DAILY BREAKDOWN TILE
// ─────────────────────────────────────────────────────────────
class _DailyBreakdownTile extends StatelessWidget {
  final String date;
  final double salary;
  const _DailyBreakdownTile({required this.date, required this.salary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color:        AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.today_outlined,
              color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(date,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        Text(formatCurrency(salary),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize:   15,
                color:      AppColors.primary)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED HELPERS (duplicated from daily for self-containment)
// ─────────────────────────────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final String       label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;

  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        IconButton(
            icon:      const Icon(Icons.chevron_left),
            color:     AppColors.info,
            onPressed: onPrev),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   15,
                        color:      AppColors.info)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    size: 18, color: AppColors.info),
              ],
            ),
          ),
        ),
        IconButton(
            icon:      const Icon(Icons.chevron_right),
            color:     AppColors.info,
            onPressed: onNext),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.w800,
            color:         AppColors.textHint,
            letterSpacing: 0.8));
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child:   Center(
          child: CircularProgressIndicator(
              color: AppColors.info, strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        const Icon(Icons.cloud_off_outlined,
            size: 36, color: AppColors.danger),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon:      const Icon(Icons.refresh, size: 18),
          label:     const Text('Retry'),
          style:     OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side:            const BorderSide(color: AppColors.danger),
          ),
        ),
      ]),
    );
  }
}