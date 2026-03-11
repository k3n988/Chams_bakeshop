import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/baker_production_viewmodel.dart';

class BakerHistoryScreen extends StatelessWidget {
  const BakerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BakerProductionViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'My Productions', subtitle: 'Your production history'),
        if (vm.productions.isEmpty)
          const EmptyState(message: 'No productions yet')
        else
          ...vm.productions.map((prod) {
            final calc = vm.computeDaily(prod);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(prod.date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(formatCurrency(calc.totalValue), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text('Your salary: ${formatCurrency(calc.salaryPerWorker + calc.masterBonus)} (${formatCurrency(calc.salaryPerWorker)} + ${formatCurrency(calc.masterBonus)} bonus)',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: prod.items.map((item) {
                  final p = vm.products.where((x) => x.id == item.productId).firstOrNull;
                  return Chip(label: Text('${item.sacks}x ${p?.name ?? "?"}', style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact);
                }).toList()),
              ])),
            );
          }),
      ]),
    );
  }
}
