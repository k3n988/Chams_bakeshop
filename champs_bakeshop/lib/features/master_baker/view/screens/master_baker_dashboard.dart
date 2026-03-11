import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
import '../../viewmodel/baker_production_viewmodel.dart';
import '../../viewmodel/baker_salary_viewmodel.dart';
import '../../../helper/view/screens/profile.dart';
import 'baker_production_input_screen.dart';
import 'baker_history_screen.dart';
import 'baker_salary_screen.dart';

class MasterBakerDashboard extends StatefulWidget {
  const MasterBakerDashboard({super.key});
  @override
  State<MasterBakerDashboard> createState() => _MasterBakerDashboardState();
}

class _MasterBakerDashboardState extends State<MasterBakerDashboard> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<BakerProductionViewModel>().loadData(user.id);
        final salaryVm = context.read<BakerSalaryViewModel>();
        salaryVm.loadDailyRecords(user.id);
        salaryVm.loadWeeklySalary(user.id);
      }
    });
  }

  void _logout() {
    context.read<AuthViewModel>().logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _goToProduce() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.masterBaker)),
      );
    }

    final salaryVm = context.watch<BakerSalaryViewModel>();

    final pages = [
      _buildDashboardHome(salaryVm, user),
      const BakerProductionInputScreen(),
      const BakerHistoryScreen(),
      const BakerSalaryScreen(),
      ProfileScreen(
        userName: user.name,
        userRole: user.role,
        userId: user.id,
        accentColor: AppColors.masterBaker,
        grossSalary: salaryVm.grossSalary,
        netSalary: salaryVm.finalSalary,
        daysWorked: salaryVm.daysWorked,
        totalRecords: salaryVm.dailyRecords.length,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      appBar: _index == 4
          ? null
          : AppBar(
              title: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [AppColors.masterBaker, Color(0xFF7DB87C)]),
                  ),
                  child: const Center(
                      child: Text('👨‍🍳', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Text('Hi, ${user.name}'),
              ]),
              actions: [
                // ── ADD PRODUCTION BUTTON ──
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.add, color: Colors.white, size: 22),
                    tooltip: 'Add Production',
                    onPressed: _goToProduce,
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.border),
              ),
            ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.masterBaker.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.masterBaker),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon:
                Icon(Icons.add_circle, color: AppColors.masterBaker),
            label: 'Produce',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.masterBaker),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments, color: AppColors.masterBaker),
            label: 'Salary',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.masterBaker),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ── Dashboard Home Tab ──
  Widget _buildDashboardHome(BakerSalaryViewModel vm, dynamic user) {
    String todayEarnings = '₱0.00';
    if (vm.dailyRecords.isNotEmpty) {
      final todayDate = DateTime.now().toString().split(' ')[0];
      if (vm.dailyRecords.first.date == todayDate) {
        todayEarnings = formatCurrency(vm.dailyRecords.first.salary);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Welcome Card + Add Production CTA ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.masterBaker, Color(0xFF7DB87C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, ${user.name}!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Here\'s your earnings overview',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToProduce,
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text('Add Production Batch',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.masterBaker,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('QUICK OVERVIEW',
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
            _quickCard(
                icon: Icons.payments_outlined,
                label: 'Today\'s Earnings',
                value: todayEarnings,
                color: const Color(0xFFD48135)),
            _quickCard(
                icon: Icons.work_history_outlined,
                label: 'Days Worked',
                value: '${vm.daysWorked}',
                color: const Color(0xFF5D4037)),
            _quickCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Weekly Gross',
                value: formatCurrency(vm.grossSalary),
                color: const Color(0xFF1976D2)),
            _quickCard(
                icon: Icons.price_check,
                label: 'Take-Home Pay',
                value: formatCurrency(vm.finalSalary),
                color: const Color(0xFF388E3C)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Today's Production Summary ──
        const Text('TODAY\'S PRODUCTION',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),

        _buildTodayProduction(vm),
        const SizedBox(height: 20),

        const Text('RECENT DAILY RECORDS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),

        if (vm.dailyRecords.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('No records yet',
                      style: TextStyle(color: AppColors.textHint))),
            ),
          )
        else
          ...vm.dailyRecords.take(5).map((rec) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.masterBaker.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.masterBaker, size: 20),
                  ),
                  title: Text(rec.date,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${rec.totalWorkers} workers • ${rec.totalSacks} sacks',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Text(formatCurrency(rec.salary),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
              )),
      ]),
    );
  }

  Widget _buildTodayProduction(BakerSalaryViewModel vm) {
    final todayDate = DateTime.now().toString().split(' ')[0];
    final todayRecords =
        vm.dailyRecords.where((r) => r.date == todayDate).toList();

    if (todayRecords.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: _goToProduce,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Row(children: [
              Icon(Icons.add_circle_outline,
                  color: AppColors.masterBaker, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No production yet today',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Tap to start your first batch',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                    ]),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint),
            ]),
          ),
        ),
      );
    }

    int totalSacks = 0;
    double totalEarnings = 0;
    for (final r in todayRecords) {
      totalSacks += r.totalSacks;
      totalEarnings += r.salary;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _todayStat('Batches', '${todayRecords.length}',
                Icons.bakery_dining, AppColors.masterBaker),
            _todayStat('Sacks', '$totalSacks', Icons.inventory_2,
                const Color(0xFF1976D2)),
            _todayStat('Earnings', formatCurrency(totalEarnings),
                Icons.payments, const Color(0xFF388E3C)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _goToProduce,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Another Batch',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.masterBaker,
                side: const BorderSide(color: AppColors.masterBaker),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _todayStat(
      String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: color)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
    ]);
  }

  Widget _quickCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}