import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../viewmodel/admin_user_viewmodel.dart';
import '../../viewmodel/admin_product_viewmodel.dart';
import '../../viewmodel/admin_production_viewmodel.dart';
import '../../viewmodel/admin_payroll_viewmodel.dart';

class AdminHomeScreen extends StatelessWidget {
  final void Function(int) onNavigate;
  const AdminHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<AdminUserViewModel>();
    final productVM = context.watch<AdminProductViewModel>();
    final prodVM = context.watch<AdminProductionViewModel>();
    final payrollVM = context.watch<AdminPayrollViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Manage your bakeshop operations',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Stats Grid ──
          const Text('OVERVIEW',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                  icon: Icons.people,
                  label: 'Total Staff',
                  value: '${userVM.nonAdminUsers.length}',
                  color: AppColors.masterBaker),
              StatCard(
                  icon: Icons.inventory_2,
                  label: 'Products',
                  value: '${productVM.products.length}',
                  color: AppColors.info),
              StatCard(
                  icon: Icons.bar_chart,
                  label: 'Productions',
                  value: '${prodVM.productions.length}',
                  color: AppColors.primary),
              StatCard(
                  icon: Icons.payments,
                  label: 'Total Payroll',
                  value: formatCurrency(payrollVM.totalPayroll),
                  color: const Color(0xFF388E3C)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Staff Summary ──
          const Text('STAFF BREAKDOWN',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                _staffRow('Master Bakers', '${userVM.masterBakers.length}',
                    AppColors.masterBaker),
                const Divider(height: 16),
                _staffRow(
                    'Helpers',
                    '${userVM.nonAdminUsers.length - userVM.masterBakers.length}',
                    AppColors.info),
                const Divider(height: 16),
                _staffRow('Total', '${userVM.nonAdminUsers.length}',
                    AppColors.primaryDark),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick Actions ──
          const Text('QUICK ACTIONS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),

          ...[
            _action(Icons.people, 'Manage Staff',
                'Add, edit, or remove employees', () => onNavigate(1)),
            _action(Icons.inventory_2, 'Products',
                'Manage bakery products & pricing', () => onNavigate(2)),
            _action(Icons.bar_chart, 'Production Reports',
                'View daily production history', () => onNavigate(3)),
            _action(Icons.payments, 'Weekly Payroll',
                'Generate & manage payroll', () => onNavigate(4)),
          ],
        ],
      ),
    );
  }

  Widget _staffRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ]),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _action(
      IconData icon, String title, String desc, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                    ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ]),
          ),
        ),
      ),
    );
  }
}