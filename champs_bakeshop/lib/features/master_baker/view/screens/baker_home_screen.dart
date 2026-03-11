import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_production_viewmodel.dart';

class BakerHomeScreen extends StatelessWidget {
  const BakerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;
    final vm = context.watch<BakerProductionViewModel>();

    double totalEarned = 0;
    for (final prod in vm.productions) {
      final calc = vm.computeDaily(prod);
      totalEarned += calc.salaryPerWorker + calc.masterBonus;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Dashboard', subtitle: 'Master Baker — ${user.name}'),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: [
            StatCard(icon: Icons.bar_chart, label: 'Productions', value: '${vm.productions.length}', color: AppColors.primary),
            StatCard(icon: Icons.payments, label: 'Total Earned', value: formatCurrency(totalEarned), color: AppColors.masterBaker),
          ],
        ),
      ]),
    );
  }
}
