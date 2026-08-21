import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/seller_remittance_viewmodel.dart';
import 'seller_daily_screen.dart';
import 'seller_monthly_screen.dart';
import 'seller_weekly_screen.dart';

class SellerSalaryScreen extends StatefulWidget {
  const SellerSalaryScreen({super.key});

  @override
  State<SellerSalaryScreen> createState() => _SellerSalaryScreenState();
}

class _SellerSalaryScreenState extends State<SellerSalaryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<SellerRemittanceViewModel>().init(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.seller,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.seller,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                ],
              ),
              Container(height: 1, color: AppColors.border),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              SellerDailyScreen(),
              SellerWeeklyScreen(),
              SellerMonthlyScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
