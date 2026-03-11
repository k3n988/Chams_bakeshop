import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_user_viewmodel.dart';

class ProductionReportsScreen extends StatefulWidget {
  const ProductionReportsScreen({super.key});

  @override
  State<ProductionReportsScreen> createState() =>
      _ProductionReportsScreenState();
}

class _ProductionReportsScreenState extends State<ProductionReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int dir) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + dir,
      );
    });
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
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prodVM = context.watch<AdminProductionViewModel>();
    final productVM = context.watch<AdminProductViewModel>();
    final userVM = context.watch<AdminUserViewModel>();

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel =
        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    // Filter productions by selected month
    final monthStr = _selectedMonth.month.toString().padLeft(2, '0');
    final prefix = '${_selectedMonth.year}-$monthStr';

    final filtered = prodVM.productions
        .where((p) => p.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate month summary
    double monthTotalValue = 0;
    int monthTotalSacks = 0;
    int monthTotalDays = filtered.length;
    for (final prod in filtered) {
      final calc = prodVM.computeDaily(prod, productVM.products);
      monthTotalValue += calc.totalValue;
      monthTotalSacks += calc.totalSacks;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'Production Reports',
            subtitle: 'View daily production history'),

        // ── Month Filter ──
        _buildMonthSelector(monthLabel),
        const SizedBox(height: 14),

        // ── Month Summary ──
        if (filtered.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withOpacity(0.06),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat(
                    'Days', '$monthTotalDays', Icons.calendar_today),
                _miniStat('Sacks', '$monthTotalSacks', Icons.inventory_2),
                _miniStat('Value', formatCurrency(monthTotalValue),
                    Icons.attach_money),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // ── Production List ──
        if (filtered.isEmpty)
          const EmptyState(message: 'No production records for this month')
        else
          ...filtered.map((prod) {
            final calc = prodVM.computeDaily(prod, productVM.products);
            final bakerName = userVM.getUserName(prod.masterBakerId);

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(prod.date,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(formatCurrency(calc.totalValue),
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 20, runSpacing: 6, children: [
                        InfoChip(label: 'Baker', value: bakerName),
                        InfoChip(
                            label: 'Workers', value: '${calc.totalWorkers}'),
                        InfoChip(
                            label: 'Sacks', value: '${calc.totalSacks}'),
                        InfoChip(
                            label: 'Per Worker',
                            value: formatCurrency(calc.salaryPerWorker)),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: prod.items.map((item) {
                          final p = productVM.getById(item.productId);
                          final val = (p?.pricePerSack ?? 0) * item.sacks;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${item.sacks}x ${p?.name ?? "?"} = ${formatCurrency(val)}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ]),
              ),
            );
          }),
      ]),
    );
  }

  Widget _buildMonthSelector(String monthLabel) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
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

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
    ]);
  }
}