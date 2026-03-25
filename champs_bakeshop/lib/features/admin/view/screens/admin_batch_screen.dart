// lib/features/admin/view/screens/admin_batch_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../viewmodel/admin_batch_viewmodel.dart';

class AdminBatchScreen extends StatelessWidget {
  const AdminBatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminBatchViewModel(ctx.read())..init(),
      child: const _AdminBatchBody(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────
class _AdminBatchBody extends StatefulWidget {
  const _AdminBatchBody();

  @override
  State<_AdminBatchBody> createState() => _AdminBatchBodyState();
}

class _AdminBatchBodyState extends State<_AdminBatchBody>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.helper,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.helper,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [_DailyTab(), _WeeklyTab()],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DAILY TAB
// ═══════════════════════════════════════════════════════════
class _DailyTab extends StatelessWidget {
  const _DailyTab();

  Future<void> _pickDate(
      BuildContext context, AdminBatchViewModel vm) async {
    final today = vm.today;
    final picked = await showDatePicker(
      context: context,
      // Opens at the currently selected date, but today is always
      // highlighted with the accent dot.
      initialDate:   vm.selectedDate,
      currentDate:   today,          // ← always marks today
      firstDate:     DateTime(2024),
      lastDate:      today,          // ← cannot pick future dates
    );
    if (picked != null) vm.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminBatchViewModel>();

    return Column(
      children: [
        // ── Date picker button ─────────────────────────────
        _DateHeader(
          label:   vm.formattedSelectedDate,
          isToday: vm.selectedDate == vm.today,
          onTap:   () => _pickDate(context, vm),
        ),

        // ── Content ───────────────────────────────────────
        Expanded(
          child: vm.isLoadingLookup || vm.isLoadingDaily
              ? const _Loader()
              : vm.dailyBatches.isEmpty
                  ? const _EmptyState(
                      message: 'No batches recorded for this date.')
                  : _BatchList(batches: vm.dailyBatches, vm: vm),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  WEEKLY TAB
// ═══════════════════════════════════════════════════════════
class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminBatchViewModel>();

    return Column(
      children: [
        // ── Week navigation ────────────────────────────────
        _WeekHeader(
          label:        vm.formattedWeekRange,
          isCurrentWeek: vm.isCurrentWeek,
          onPrev:       vm.isLoadingWeekly ? null : vm.prevWeek,
          // disable next when already on the current week
          onNext:       (vm.isLoadingWeekly || vm.isCurrentWeek)
                            ? null
                            : vm.nextWeek,
        ),

        // ── Summary chips ──────────────────────────────────
        if (!vm.isLoadingWeekly && vm.weeklyBatches.isNotEmpty)
          _WeeklySummary(vm: vm),

        // ── Content ───────────────────────────────────────
        Expanded(
          child: vm.isLoadingLookup || vm.isLoadingWeekly
              ? const _Loader()
              : vm.weeklyBatches.isEmpty
                  ? const _EmptyState(
                      message: 'No batches recorded for this week.')
                  : _BatchList(batches: vm.weeklyBatches, vm: vm),
        ),
      ],
    );
  }
}

// ── Weekly summary card ───────────────────────────────────────
class _WeeklySummary extends StatelessWidget {
  final AdminBatchViewModel vm;
  const _WeeklySummary({required this.vm});

  @override
  Widget build(BuildContext context) {
    // Build per-day sack totals for the week
    final dayTotals = <String, int>{};
    for (final b in vm.weeklyBatches) {
      final date = (b['date'] ?? '').toString();
      dayTotals[date] = (dayTotals[date] ?? 0) + ((b['saka'] as int?) ?? 0);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Total chips row
          Row(
            children: [
              _SummaryChip(
                icon:  Icons.layers_outlined,
                color: AppColors.helper,
                label: '${vm.weeklyTotalBatches}',
                sub:   'Batches',
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                icon:  Icons.inventory_2_outlined,
                color: AppColors.primary,
                label: '${vm.weeklyTotalSacks}',
                sub:   'Total Sacks',
              ),
            ],
          ),
          if (dayTotals.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Day-by-day bar
            _DayBar(
              weekStart: vm.weekStart,
              dayTotals: dayTotals,
              today:     vm.today,
            ),
          ],
          const SizedBox(height: 4),
          Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   sub;
  const _SummaryChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint)),
              ],
            ),
          ]),
        ),
      );
}

// ── Day-by-day bar (Mon–Sun) ──────────────────────────────────
class _DayBar extends StatelessWidget {
  final DateTime         weekStart;
  final Map<String, int> dayTotals;
  final DateTime         today;

  const _DayBar({
    required this.weekStart,
    required this.dayTotals,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxSacks = dayTotals.values.fold(0, (a, b) => a > b ? a : b);

    return Row(
      children: List.generate(7, (i) {
        final day   = weekStart.add(Duration(days: i));
        final key   = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final sacks = dayTotals[key] ?? 0;
        final isToday = day.year  == today.year &&
                        day.month == today.month &&
                        day.day   == today.day;
        final frac  = maxSacks > 0 ? sacks / maxSacks : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                // Bar
                Container(
                  height: 36,
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: frac > 0 ? frac.clamp(0.15, 1.0) : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.helper
                            : AppColors.helper.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Day label
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: isToday
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: isToday
                            ? AppColors.helper
                            : AppColors.textHint)),
                // Sack count
                Text(sacks > 0 ? '$sacks' : '',
                    style: const TextStyle(
                        fontSize: 8, color: AppColors.textHint)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHARED BATCH LIST
// ═══════════════════════════════════════════════════════════
class _BatchList extends StatelessWidget {
  final List<Map<String, dynamic>> batches;
  final AdminBatchViewModel vm;

  const _BatchList({required this.batches, required this.vm});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final b in batches) {
      final date = (b['date'] ?? '').toString();
      grouped.putIfAbsent(date, () => []).add(b);
    }
    final dates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: dates.length,
      itemBuilder: (context, i) {
        final date  = dates[i];
        final items = grouped[date]!;
        return _DateGroup(date: date, items: items, vm: vm);
      },
    );
  }
}

// ── Date group ────────────────────────────────────────────────
class _DateGroup extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> items;
  final AdminBatchViewModel vm;

  const _DateGroup({
    required this.date,
    required this.items,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(children: [
            Container(
              width: 3, height: 13,
              decoration: BoxDecoration(
                  color: AppColors.helper,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(date,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                    letterSpacing: 0.8)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.helper.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  '${items.length} batch${items.length == 1 ? '' : 'es'}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.helper)),
            ),
          ]),
        ),
        ...items.map((b) => _BatchCard(batch: b, vm: vm)),
      ],
    );
  }
}

// ── Batch card ────────────────────────────────────────────────
class _BatchCard extends StatelessWidget {
  final Map<String, dynamic> batch;
  final AdminBatchViewModel  vm;

  const _BatchCard({required this.batch, required this.vm});

  @override
  Widget build(BuildContext context) {
    final helperName  = vm.helperName(batch['helper_id']      ?? '');
    final bakerName   = vm.bakerName(batch['master_baker_id'] ?? '');
    final productName = vm.productName(batch['product_id']    ?? '');
    final categories  = vm.categorySummary(batch);
    final sacks       = (batch['saka'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product + sacks
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.helper.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.helper),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(productName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.helper.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                  '$sacks sack${sacks == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.helper)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          // Helper + baker
          Row(children: [
            _InfoChip(
              icon: Icons.person_outline,
              color: AppColors.masterBaker,
              label: helperName,
              sublabel: 'Helper',
            ),
            const SizedBox(width: 10),
            _InfoChip(
              icon: Icons.soup_kitchen_outlined,
              color: AppColors.primary,
              label: bakerName,
              sublabel: 'Baker',
            ),
          ]),
          // Categories
          if (categories != '—') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(categories,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   sublabel;
  const _InfoChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sublabel,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ],
            ),
          ),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════
//  HEADERS
// ═══════════════════════════════════════════════════════════

class _DateHeader extends StatelessWidget {
  final String       label;
  final bool         isToday;
  final VoidCallback onTap;

  const _DateHeader({
    required this.label,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.helper.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.helper.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.helper),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.helper)),
              const SizedBox(width: 6),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.helper,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Today',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              const Spacer(),
              const Icon(Icons.edit_outlined,
                  size: 14, color: AppColors.textHint),
            ]),
          ),
        ),
      );
}

class _WeekHeader extends StatelessWidget {
  final String        label;
  final bool          isCurrentWeek;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _WeekHeader({
    required this.label,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            color: onPrev != null
                ? AppColors.helper
                : AppColors.textHint,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.helper.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.helper.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range_outlined,
                      size: 16, color: AppColors.helper),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.helper)),
                  if (isCurrentWeek) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.helper,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('This Week',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: onNext != null
                ? AppColors.helper
                : AppColors.textHint,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════
//  UTILS
// ═══════════════════════════════════════════════════════════
class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Center(
      child: CircularProgressIndicator(color: AppColors.helper));
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint)),
          ],
        ),
      );
}
