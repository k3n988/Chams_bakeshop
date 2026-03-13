import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/payroll_model.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

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
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Oven is auto-calculated (₱20/day for helpers).',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              const SizedBox(height: 16),
              TextField(
                  controller: gasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Gas (₱)',
                      prefixIcon: Icon(Icons.local_fire_department_outlined))),
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

  @override
  Widget build(BuildContext context) {
    final payVM = context.watch<AdminPayrollViewModel>();

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel =
        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

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
          ...payVM.entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────────
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Row(children: [
                                  RoleBadge(role: e.role),
                                  const SizedBox(width: 8),
                                  Text('${e.daysWorked} days',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint)),
                                ]),
                              ])),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // FIX: finalSalary = grossSalary - deductions (bonus excluded)
                                Text(formatCurrency(e.finalSalary),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark)),
                                const Text('Final Salary',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint)),
                              ]),
                        ]),

                        const Divider(height: 24),

                        // ── Breakdown ────────────────────────────────────────
                        // FIX: was e.totalSalary (undefined) → e.grossSalary
                        // grossSalary = base + baker incentive (master) or base only (helper)
                        BreakdownRow(
                            label: 'Gross Salary',
                            value: formatCurrency(e.grossSalary),
                            color: AppColors.success),

                        // bonusTotal is shown separately — NOT part of gross or final
                        if (e.bonusTotal > 0)
                          BreakdownRow(
                              label: 'Sack Bonus (separate)',
                              value: formatCurrency(e.bonusTotal),
                              color: AppColors.masterBaker),

                        if (e.ovenDeduction > 0)
                          BreakdownRow(
                              label: 'Oven (₱20/day)',
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

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                              onPressed: () => _showDeductionDialog(e),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit Deductions'),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12))),
                        ),
                      ]),
                ),
              )),

          // ── Total payroll ────────────────────────────────────────────────
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