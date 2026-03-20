import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/baker_salary_viewmodel.dart';

part 'baker_salary_daily_screen.dart';
part 'baker_salary_weekly_screen.dart';
part 'baker_salary_monthly_screen.dart';

// ── Internal date helper ──────────────────────────────────────
String _monthLabel(String dateStr) {
  if (dateStr.isEmpty) return '—';
  try {
    final d = DateTime.parse(dateStr);
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${names[d.month - 1]} ${d.year}';
  } catch (_) {
    return '—';
  }
}

// ─────────────────────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────────────────────
class BakerSalaryScreen extends StatefulWidget {
  const BakerSalaryScreen({super.key});

  @override
  State<BakerSalaryScreen> createState() => _BakerSalaryScreenState();
}

class _BakerSalaryScreenState extends State<BakerSalaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _userId =>
      context.read<AuthViewModel>().currentUser!.id;

  Future<void> _init() async =>
      context.read<BakerSalaryViewModel>().init(_userId);

  Future<void> _changeWeek(int dir) async =>
      context.read<BakerSalaryViewModel>().changeWeek(dir, _userId);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Tab bar ──────────────────────────────────────────────
      Container(
        color: Colors.white,
        child: Column(
          children: [
            TabBar(
              controller: _tab,
              labelColor: AppColors.masterBaker,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.masterBaker,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
            Container(height: 1, color: AppColors.border),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: [
            _DailyTab(userId: _userId),
            _WeeklyTab(onChangeWeek: _changeWeek),
            _MonthlyTab(),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader(
      {required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ],
      );
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _WhiteCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _MonthBar extends StatelessWidget {
  final String dateStr;
  const _MonthBar({required this.dateStr});

  @override
  Widget build(BuildContext context) => _WhiteCard(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 4),
        child: Row(children: [
          const Icon(Icons.chevron_left,
              color: AppColors.textHint),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 15, color: AppColors.masterBaker),
                const SizedBox(width: 8),
                Text(
                  _monthLabel(dateStr),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryDark),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    size: 18,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textHint),
        ]),
      );
}

class _WeekNav extends StatelessWidget {
  final String weekStart;
  final String weekEnd;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _WeekNav({
    required this.weekStart,
    required this.weekEnd,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        weekStart.isEmpty ? '—' : '$weekStart — $weekEnd';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.masterBaker.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                AppColors.masterBaker.withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: AppColors.masterBaker,
          iconSize: 20,
          onPressed: onPrev,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.date_range_outlined,
                  size: 15,
                  color: AppColors.masterBaker
                      .withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primaryDark)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: AppColors.masterBaker,
          iconSize: 20,
          onPressed: onNext,
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.masterBaker,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
      ]);
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard(
      {required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 14)),
        ]),
      );
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.masterBaker,
              strokeWidth: 2.5),
        ),
      );
}

class _ErrCard extends StatelessWidget {
  final String message;
  const _ErrCard(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined,
              size: 36, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13)),
        ]),
      );
}