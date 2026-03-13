import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'core/services/database_service.dart';
import 'core/services/payroll_service.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/view/login_screen.dart';
import 'features/admin/viewmodel/admin_user_viewmodel.dart';
import 'features/admin/viewmodel/admin_product_viewmodel.dart';
import 'features/admin/viewmodel/admin_production_viewmodel.dart';
import 'features/admin/viewmodel/admin_payroll_viewmodel.dart';
import 'features/master_baker/viewmodel/baker_production_viewmodel.dart';
import 'features/master_baker/viewmodel/baker_salary_viewmodel.dart';
import 'features/helper/viewmodel/helper_salary_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fmkjhqgjgpglvagszixr.supabase.co', // ← replace
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZta2pocWdqZ3BnbHZhZ3N6aXhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMzQwMDcsImV4cCI6MjA4ODgxMDAwN30.ZmJpYk0LCX9bDQG1fr0No3vNPB4RwHDJ07Z_1D8PJhQ',                   // ← replace
  );

  runApp(const ChampsBakeshopApp());
}

class ChampsBakeshopApp extends StatelessWidget {
  const ChampsBakeshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supa       = SupabaseService();
    final db         = DatabaseService(supa);
    final payrollSvc = PayrollService(supa);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(db)),
        ChangeNotifierProvider(create: (_) => AdminUserViewModel(db)),
        ChangeNotifierProvider(create: (_) => AdminProductViewModel(db)),
        ChangeNotifierProvider(create: (_) => AdminProductionViewModel(db, payrollSvc)),
        ChangeNotifierProvider(create: (_) => AdminPayrollViewModel(db, payrollSvc)),
        ChangeNotifierProvider(create: (_) => BakerProductionViewModel(db, payrollSvc)),
        ChangeNotifierProvider(create: (_) => BakerSalaryViewModel(db, payrollSvc)),
        // FIX 3: HelperSalaryViewModel expects SupabaseService — pass supa directly
        ChangeNotifierProvider(create: (_) => HelperSalaryViewModel(supa, payrollSvc)),
      ],
      child: MaterialApp(
        title: "Champ's Bakeshop",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFD4813A),
          fontFamily: 'Roboto',
        ),
        home: const LoginScreen(),
      ),
    );
  }
}