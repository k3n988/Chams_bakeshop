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

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});
  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final payVM = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    final ws = payVM.weekStart.isEmpty
        ? getWeekStart(DateTime.now())
        : payVM.weekStart;
    payVM.loadWeeklyPayroll(
        ws, prodVM.products, userVM.userNameMap, userVM.userRoleMap);
  }

  void _changeWeek(int dir) {
    final payVM = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    payVM.changeWeek(
        dir, prodVM.products, userVM.userNameMap, userVM.userRoleMap);
  }

  void _changeMonth(int dir) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + dir,
      );
    });
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monday = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final ws = monday.toString().split(' ')[0];
    final payVM = context.read<AdminPayrollViewModel>();
    final prodVM = context.read<AdminProductViewModel>();
    final userVM = context.read<AdminUserViewModel>();
    payVM.loadWeeklyPayroll(
        ws, prodVM.products, userVM.userNameMap, userVM.userRoleMap);
  }

  void _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'SELECT MONTH',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _changeMonth(0);
    }
  }

  void _showDeductionDialog(PayrollEntry entry) {
    final isHelper = entry.role != 'master_baker';
    final autoOven = isHelper ? entry.daysWorked * 20.0 : 0.0;

    final ovenCtrl = TextEditingController(
        text: entry.ovenDeduction.toStringAsFixed(0));
    final gasCtrl =
        TextEditingController(text: entry.gasDeduction.toStringAsFixed(0));
    final valeCtrl =
        TextEditingController(text: entry.valeDeduction.toStringAsFixed(0));
    final wifiCtrl =
        TextEditingController(text: entry.wifiDeduction.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deductions — ${entry.name}',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Oven ──────────────────────────────────────
                Row(children: [
                  const Icon(Icons.microwave_outlined,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isHelper
                          ? 'Oven auto: ₱${autoOven.toStringAsFixed(0)} (₱20 × ${entry.daysWorked} days). Override below.'
                          : 'Master Baker — no oven deduction.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: ovenCtrl,
                  keyboardType: TextInputType.number,
                  enabled: isHelper,
                  decoration: InputDecoration(
                    labelText: 'Oven (₱)',
                    hintText: autoOven.toStringAsFixed(0),
                    prefixIcon:
                        const Icon(Icons.microwave_outlined),
                    helperText: isHelper
                        ? 'Leave 0 to use auto-calculated amount'
                        : 'N/A for master baker',
                  ),
                ),
                const Divider(height: 24),
                // ── Other deductions ─────────────────────────
                TextField(
                    controller: gasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Gas (₱)',
                        prefixIcon:
                            Icon(Icons.local_fire_department_outlined))),
                const SizedBox(height: 12),
                TextField(
                    controller: valeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Vale (₱)',
                        prefixIcon: Icon(Icons.money_outlined))),
                const SizedBox(height: 12),
                TextField(
                    controller: wifiCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Wifi (₱)',
                        prefixIcon: Icon(Icons.wifi))),
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final payVM = context.read<AdminPayrollViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              await payVM.saveDeduction(
                userId: entry.userId,
                weekStart: payVM.weekStart,
                oven: double.tryParse(ovenCtrl.text) ?? 0,
                gas: double.tryParse(gasCtrl.text) ?? 0,
                vale: double.tryParse(valeCtrl.text) ?? 0,
                wifi: double.tryParse(wifiCtrl.text) ?? 0,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
              if (mounted) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Deductions saved!'),
                    backgroundColor: AppColors.success));
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
        title: const Text('Confirm Payment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Mark ${entry.name} as paid?'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Final Salary',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(formatCurrency(entry.finalSalary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          fontSize: 16)),
                ]),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Confirm Paid'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final payVM = context.read<AdminPayrollViewModel>();
              final messenger = ScaffoldMessenger.of(context);
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
        title: const Text('Pay All',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Mark all ${unpaid.length} unpaid employees as paid this week?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Pay All'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final payVM = context.read<AdminPayrollViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final ok = await payVM.markAllAsPaid(paidBy: adminId);
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'All employees marked as paid!'
                      : 'Error saving payments.'),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.danger,
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

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel =
        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    final unpaidEntries =
        payVM.entries.where((e) => !e.isPaid).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'Weekly Payroll',
            subtitle: 'Automated salary computation with deductions'),
        _buildMonthSelector(monthLabel),
        const SizedBox(height: 10),
        WeekSelector(
            weekStart: payVM.weekStart,
            weekEnd: payVM.weekEnd,
            onPrev: () => _changeWeek(-1),
            onNext: () => _changeWeek(1)),
        const SizedBox(height: 16),

        if (payVM.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (payVM.entries.isEmpty)
          const EmptyState(message: 'No production data for this week')
        else ...[

          // ── Pay All banner ───────────────────────────────────
          if (unpaidEntries.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.payments_outlined,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${unpaidEntries.length} employee${unpaidEntries.length > 1 ? 's' : ''} unpaid this week',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                ElevatedButton(
                  onPressed: payVM.isPaying
                      ? null
                      : () => _confirmMarkAllPaid(unpaidEntries),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    elevation: 0,
                  ),
                  child: const Text('Pay All'),
                ),
              ]),
            ),

          // ── Employee cards ───────────────────────────────────
          ...payVM.entries.map((e) => _EmployeeCard(
                entry: e,
                onEditDeductions: () => _showDeductionDialog(e),
                onMarkPaid: () => _confirmMarkPaid(e),
                isPaying: payVM.isPaying,
              )),

          // ── Total payroll ────────────────────────────────────
          Card(
            color: AppColors.primaryDark,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL PAYROLL',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 13)),
                    Text(formatCurrency(payVM.totalPayroll),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22)),
                  ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildMonthSelector(String monthLabel) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(monthLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () => _changeMonth(1),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EMPLOYEE CARD WIDGET
// ─────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final PayrollEntry entry;
  final VoidCallback onEditDeductions;
  final VoidCallback onMarkPaid;
  final bool isPaying;

  const _EmployeeCard({
    required this.entry,
    required this.onEditDeductions,
    required this.onMarkPaid,
    required this.isPaying,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // ✅ Green border when paid
        side: e.isPaid
            ? BorderSide(
                color: AppColors.success.withValues(alpha: 0.4),
                width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ────────────────────────────────────────────
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: e.role == 'master_baker'
                  ? AppColors.masterBaker.withValues(alpha: 0.12)
                  : AppColors.helper.withValues(alpha: 0.12),
              child: Text(e.name[0],
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: e.role == 'master_baker'
                          ? AppColors.masterBaker
                          : AppColors.helper)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(e.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Row(children: [
                    RoleBadge(role: e.role),
                    const SizedBox(width: 8),
                    Text('${e.daysWorked} days',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ]),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatCurrency(e.finalSalary),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark)),
              const Text('Final Salary',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textHint)),
            ]),
          ]),

          const Divider(height: 24),

          // ── Breakdown ──────────────────────────────────────────
          BreakdownRow(
              label: 'Gross Salary',
              value: formatCurrency(e.grossSalary),
              color: AppColors.success),
          if (e.bonusTotal > 0)
            BreakdownRow(
                label: 'Sack Bonus (separate)',
                value: formatCurrency(e.bonusTotal),
                color: AppColors.masterBaker),
          if (e.ovenDeduction > 0)
            BreakdownRow(
                label: 'Oven (₱15/day)',
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

          const SizedBox(height: 12),

          // ── Action Buttons ─────────────────────────────────────
          Row(children: [
            // Edit Deductions
            Expanded(
              child: OutlinedButton.icon(
                  onPressed: onEditDeductions,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Deductions'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12))),
            ),
            const SizedBox(width: 8),
            // ✅ Paid Button
            e.isPaid
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Paid',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success)),
                        ]),
                  )
                : ElevatedButton.icon(
                    onPressed: isPaying ? null : onMarkPaid,
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Mark Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      elevation: 0,
                    ),
                  ),
          ]),
        ]),
      ),
    );
  }
}