import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import 'core/utils/constants.dart';
import 'core/services/supabase_service.dart';
import 'core/services/payroll_service.dart';

// Auth Feature
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/view/login_screen.dart';

// Admin Feature
import 'features/admin/viewmodel/admin_user_viewmodel.dart';
import 'features/admin/viewmodel/admin_product_viewmodel.dart';
import 'features/admin/viewmodel/admin_production_viewmodel.dart';
import 'features/admin/viewmodel/admin_payroll_viewmodel.dart';

// Master Baker Feature
import 'features/master_baker/viewmodel/baker_production_viewmodel.dart';
import 'features/master_baker/viewmodel/baker_salary_viewmodel.dart';

// Helper Feature
import 'features/helper/viewmodel/helper_salary_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     'https://fmkjhqgjgpglvagszixr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
             '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZta2pocWdqZ3BnbHZhZ3N6aXhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMzQwMDcsImV4cCI6MjA4ODgxMDAwN30'
             '.ZmJpYk0LCX9bDQG1fr0No3vNPB4RwHDJ07Z_1D8PJhQ',
  );

  runApp(const ChampsBakeshopApp());
}

class ChampsBakeshopApp extends StatelessWidget {
  const ChampsBakeshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService      = SupabaseService();
    final payrollService = PayrollService(dbService);

    return MultiProvider(
      providers: [
        // ── Core services (accessible anywhere via context.read) ──
        Provider<SupabaseService>.value(value: dbService),
        Provider<PayrollService>.value(value: payrollService),

        // ── Auth ──
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(dbService),
        ),

        // ── Admin ──
        ChangeNotifierProvider(
          create: (_) => AdminUserViewModel(dbService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProductViewModel(dbService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProductionViewModel(dbService, payrollService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminPayrollViewModel(dbService, payrollService),
        ),

        // ── Master Baker ──
        ChangeNotifierProvider(
          create: (_) => BakerProductionViewModel(dbService, payrollService),
        ),
        ChangeNotifierProvider(
          create: (_) => BakerSalaryViewModel(dbService, payrollService),
        ),

        // ── Helper ──
        ChangeNotifierProvider(
          create: (_) => HelperSalaryViewModel(dbService, payrollService),
        ),
      ],
      child: MaterialApp(
        title:                      'Champs Bakeshop Payroll',
        debugShowCheckedModeBanner: false,
        theme:                      AppTheme.theme,
        home:                       const LoginScreen(),
      ),
    );
  }
}