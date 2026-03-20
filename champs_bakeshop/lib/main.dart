import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Core Services ──
import 'core/services/supabase_service.dart';
import 'core/services/database_service.dart';
import 'core/services/payroll_service.dart';

// ── Auth ──
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/view/login_screen.dart';

// ── Admin ──
import 'features/admin/viewmodel/admin_user_viewmodel.dart';
import 'features/admin/viewmodel/admin_product_viewmodel.dart';
import 'features/admin/viewmodel/admin_production_viewmodel.dart';
import 'features/admin/viewmodel/admin_payroll_viewmodel.dart';

// ── Master Baker ──
import 'features/master_baker/viewmodel/baker_production_viewmodel.dart';
import 'features/master_baker/viewmodel/baker_salary_viewmodel.dart';

// ── Helper ──
import 'features/helper/viewmodel/helper_salary_viewmodel.dart';

// ── Packer ──
import 'features/packer/viewmodel/packer_production_viewmodel.dart';
import 'features/packer/viewmodel/packer_salary_viewmodel.dart';

// ── Seller ──
import 'features/seller/viewmodel/seller_session_viewmodel.dart';
import 'features/seller/viewmodel/seller_remittance_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fmkjhqgjgpglvagszixr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZta2pocWdqZ3BnbHZhZ3N6aXhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMzQwMDcsImV4cCI6MjA4ODgxMDAwN30.ZmJpYk0LCX9bDQG1fr0No3vNPB4RwHDJ07Z_1D8PJhQ',
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
        // ── Services ──────────────────────────────────────────
        Provider<SupabaseService>(create: (_) => supa),
        Provider<DatabaseService>(create: (_) => db),
        Provider<PayrollService>(create:  (_) => payrollSvc),

        // ── Auth ──────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AuthViewModel(db)),

        // ── Admin ─────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AdminUserViewModel(db)),
        ChangeNotifierProvider(create: (_) => AdminProductViewModel(db)),
        ChangeNotifierProvider(create: (_) => AdminProductionViewModel(db, payrollSvc)),
        ChangeNotifierProvider(create: (_) => AdminPayrollViewModel(db, payrollSvc)),

        // ── Master Baker ──────────────────────────────────────
        ChangeNotifierProvider(create: (_) => BakerProductionViewModel(db, payrollSvc)),
        ChangeNotifierProvider(create: (_) => BakerSalaryViewModel(db, payrollSvc)),

        // ── Helper ────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => HelperSalaryViewModel(supa, payrollSvc)),

        // ── Packer ────────────────────────────────────────────
        // PackerProductionViewModel needs DatabaseService to fetch admin products
        ChangeNotifierProxyProvider<DatabaseService, PackerProductionViewModel>(
          create: (ctx) => PackerProductionViewModel(ctx.read<DatabaseService>()),
          update: (ctx, db, prev) => prev ?? PackerProductionViewModel(db),
        ),
        ChangeNotifierProvider(create: (_) => PackerSalaryViewModel()),

        // ── Seller ────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => SellerSessionViewModel()),
        ChangeNotifierProvider(create: (_) => SellerRemittanceViewModel()),
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