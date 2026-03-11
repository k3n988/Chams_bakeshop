import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_salary_viewmodel.dart';

class BakerSalaryScreen extends StatefulWidget {
  const BakerSalaryScreen({super.key});
  @override
  State<BakerSalaryScreen> createState() => _BakerSalaryScreenState();
}

class _BakerSalaryScreenState extends State<BakerSalaryScreen> {
  int _tabIndex = 1; // 0=Daily, 1=Weekly, 2=Monthly
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        final vm = context.read<BakerSalaryViewModel>();
        vm.loadDailyRecords(user.id);
        vm.loadWeeklySalary(user.id);
      }
    });
  }

  void _changeWeek(int dir) {
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      context.read<BakerSalaryViewModel>().changeWeek(dir, user.id);
    }
  }

  void _changeMonth(int dir) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + dir,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.masterBaker));
    }

    final vm = context.watch<BakerSalaryViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'My Salary', subtitle: 'Track your earnings'),

        // ── Tab Selector ──
        _buildTabSelector(),
        const SizedBox(height: 16),

        // ── Tab Content ──
        if (_tabIndex == 0) _buildDailyView(vm),
        if (_tabIndex == 1) _buildWeeklyView(vm),
        if (_tabIndex == 2) _buildMonthlyView(vm),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB SELECTOR
  // ═══════════════════════════════════════════

  Widget _buildTabSelector() {
    const tabs = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.masterBaker.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.masterBaker : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  DAILY VIEW
  // ═══════════════════════════════════════════

  Widget _buildDailyView(BakerSalaryViewModel vm) {
    // Filter records by selected month
    final monthStr = _selectedMonth.month.toString().padLeft(2, '0');
    final prefix = '${_selectedMonth.year}-$monthStr';

    final filtered = vm.dailyRecords
        .where((r) => r.date.startsWith(prefix))
        .toList();

    double monthTotal = 0;
    int monthSacks = 0;
    for (final r in filtered) {
      monthTotal += r.salary;
      monthSacks += r.totalSacks;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Month picker
      _buildMonthSelector(),
      const SizedBox(height: 14),

      // Summary bar
      if (filtered.isNotEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.masterBaker.withOpacity(0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Days', '${filtered.length}', Icons.work_history),
              _miniStat('Sacks', '$monthSacks', Icons.inventory_2),
              _miniStat('Total', formatCurrency(monthTotal), Icons.payments),
            ],
          ),
        ),
      const SizedBox(height: 14),

      // Daily records list
      if (filtered.isEmpty)
        _emptyCard('No salary records for this month.')
      else
        ...filtered.map((rec) => Card(
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
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${rec.totalWorkers} workers • ${rec.totalSacks} sacks',
                    style: const TextStyle(fontSize: 12)),
                trailing: Text(formatCurrency(rec.salary),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        fontSize: 15)),
              ),
            )),
    ]);
  }

  // ═══════════════════════════════════════════
  //  WEEKLY VIEW
  // ═══════════════════════════════════════════

  Widget _buildWeeklyView(BakerSalaryViewModel vm) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WeekSelector(
        weekStart: vm.weekStart,
        weekEnd: vm.weekEnd,
        onPrev: () => _changeWeek(-1),
        onNext: () => _changeWeek(1),
      ),
      const SizedBox(height: 16),

      // Stats - use childAspectRatio that avoids overflow
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          StatCard(
              icon: Icons.calendar_today,
              label: 'Days Worked',
              value: '${vm.daysWorked}',
              color: AppColors.info),
          StatCard(
              icon: Icons.account_balance_wallet,
              label: 'Weekly Gross',
              value: formatCurrency(vm.grossSalary),
              color: AppColors.masterBaker),
          StatCard(
              icon: Icons.money_off,
              label: 'Deductions',
              value: formatCurrency(vm.grossSalary - vm.finalSalary),
              color: Colors.red.shade400),
          StatCard(
              icon: Icons.price_check,
              label: 'Take-Home Pay',
              value: formatCurrency(vm.finalSalary),
              color: Colors.green.shade600),
        ],
      ),
      const SizedBox(height: 24),

      const Text('DAILY BREAKDOWN',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.8)),
      const SizedBox(height: 10),

      if (vm.dailyEntries.isEmpty)
        _emptyCard('No salary records for this week.')
      else
        ...vm.dailyEntries.map((d) {
          final dailyTotal = d.baseSalary + d.bonus;
          return Card(
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
              title: Text(d.date,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  'Base: ${formatCurrency(d.baseSalary)}  •  Bonus: ${formatCurrency(d.bonus)}',
                  style: const TextStyle(fontSize: 12)),
              trailing: Text(formatCurrency(dailyTotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      fontSize: 15)),
            ),
          );
        }),
    ]);
  }

  // ═══════════════════════════════════════════
  //  MONTHLY VIEW
  // ═══════════════════════════════════════════

  Widget _buildMonthlyView(BakerSalaryViewModel vm) {
    final monthStr = _selectedMonth.month.toString().padLeft(2, '0');
    final prefix = '${_selectedMonth.year}-$monthStr';

    final filtered = vm.dailyRecords
        .where((r) => r.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Split into weeks
    double monthGross = 0;
    int monthDays = filtered.length;
    int monthSacks = 0;
    for (final r in filtered) {
      monthGross += r.salary;
      monthSacks += r.totalSacks;
    }

    // Group by week number within the month
    final Map<int, List<BakerDashboardRecord>> weekGroups = {};
    for (final r in filtered) {
      final day = int.tryParse(r.date.split('-').last) ?? 1;
      final weekNum = ((day - 1) ~/ 7) + 1;
      weekGroups.putIfAbsent(weekNum, () => []).add(r);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildMonthSelector(),
      const SizedBox(height: 16),

      // Monthly totals card
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
        child: Column(children: [
          const Text('TOTAL MONTHLY EARNINGS',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(formatCurrency(monthGross),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _chipWhite(Icons.work_history, '$monthDays days'),
            const SizedBox(width: 16),
            _chipWhite(Icons.inventory_2, '$monthSacks sacks'),
          ]),
        ]),
      ),
      const SizedBox(height: 18),

      // Stats row
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: [
          _statTile('Gross Salary', formatCurrency(monthGross),
              Icons.payments, AppColors.masterBaker),
          _statTile(
              'Avg / Week',
              formatCurrency(
                  weekGroups.isNotEmpty ? monthGross / weekGroups.length : 0),
              Icons.trending_up,
              AppColors.info),
        ],
      ),
      const SizedBox(height: 18),

      // Weekly breakdown
      const Text('WEEKLY BREAKDOWN',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.8)),
      const SizedBox(height: 10),

      if (weekGroups.isEmpty)
        _emptyCard('No data for this month.')
      else
        ...weekGroups.entries.map((entry) {
          final weekNum = entry.key;
          final records = entry.value;
          double weekTotal = 0;
          int weekSacks = 0;
          for (final r in records) {
            weekTotal += r.salary;
            weekSacks += r.totalSacks;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.masterBaker.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('W$weekNum',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.masterBaker,
                            fontSize: 14)),
                  ),
                ),
                title: Text('Week $weekNum',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                    '${records.length} days • $weekSacks sacks',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
                trailing: Text(formatCurrency(weekTotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.masterBaker)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        const Divider(),
                        ...records.map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.date,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                  Text(formatCurrency(r.salary),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
    ]);
  }

  // ═══════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════

  Widget _buildMonthSelector() {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final label =
        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.masterBaker.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(
            icon:
                const Icon(Icons.chevron_left, color: AppColors.masterBaker),
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month,
                    size: 18, color: AppColors.masterBaker),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.masterBaker)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: AppColors.masterBaker),
            onPressed: () => _changeMonth(1),
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, size: 18, color: AppColors.masterBaker),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
    ]);
  }

  Widget _chipWhite(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.white70),
      const SizedBox(width: 4),
      Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
            child:
                Text(message, style: const TextStyle(color: AppColors.textHint))),
      ),
    );
  }
}