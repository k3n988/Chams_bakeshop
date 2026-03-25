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

// ── Role dashboards ──
import 'features/admin/view/screens/admin_dashboard.dart';
import 'features/master_baker/view/screens/master_baker_dashboard.dart';
import 'features/helper/view/screens/helper_dashboard.dart';
import 'features/packer/view/screens/packer_dashboard.dart';
import 'features/seller/view/screens/seller_dashboard.dart';

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
        home: const AuthWrapper(),
      ),
    );
  }
}

// ── Checks saved session then routes to correct screen ────────
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final auth = context.read<AuthViewModel>();
    final restored = await auth.tryAutoLogin();
    if (!mounted) return;

    if (!restored) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final user = auth.currentUser!;
    Widget destination;
    if (user.isAdmin) {
      destination = const AdminDashboard();
    } else if (user.isMasterBaker) {
      destination = const MasterBakerDashboard();
    } else if (user.isPacker) {
      destination = const PackerDashboard();
    } else if (user.isSeller) {
      destination = const SellerDashboard();
    } else {
      destination = const HelperDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF8C00),
          ),
        ),
      );
}