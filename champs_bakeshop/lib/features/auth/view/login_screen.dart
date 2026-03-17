import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../admin/view/screens/admin_dashboard.dart';
import '../../master_baker/view/screens/master_baker_dashboard.dart';
import '../../helper/view/screens/helper_dashboard.dart';

class LoginColors {
  static const gradientStart = Color(0xFFFF7A00);
  static const gradientEnd = Color(0xFFFFA03A);
  static const background = Colors.white;
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF795548);
  static const textLight = Color(0xFFA1887F);
  static const inputFill = Color(0xFFFAF6F0);
  static const border = Color(0xFFEFEBE6);
  static const error = Color(0xFFD32F2F);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String _selectedRole = '';
  bool _obscure = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(String? role) {
    if (role == null) return;

    setState(() => _selectedRole = role);
    context.read<AuthViewModel>().clearError();

    if (role.isNotEmpty) {
      _animCtrl.forward();

      if (role == 'admin') {
        _emailCtrl.text = 'admin@champs.com';
        _passCtrl.text = 'admin123';
      } else if (role == 'master_baker') {
        _emailCtrl.text = 'mica@baker.com';
        _passCtrl.text = 'mica123';
      } else if (role == 'helper') {
        _emailCtrl.text = 'kenjeternal@helper.com';
        _passCtrl.text = 'ken123';
      }
    } else {
      _animCtrl.reverse();
      _emailCtrl.clear();
      _passCtrl.clear();
    }
  }

  Future<void> _handleLogin() async {
    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role first')),
      );
      return;
    }

    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    final auth = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await auth.login(
      _emailCtrl.text.trim().toLowerCase(),
      _passCtrl.text,
      _selectedRole,
    );

    if (success && mounted) {
      final user = auth.currentUser!;

      Widget destination;

      if (user.isAdmin) {
        destination = const AdminDashboard();
      } else if (user.isMasterBaker) {
        destination = const MasterBakerDashboard();
      } else {
        destination = const HelperDashboard();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials or wrong role selected'),
          backgroundColor: LoginColors.error,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: LoginColors.textLight),
      prefixIcon: Icon(icon, color: LoginColors.textLight),
      filled: true,
      fillColor: LoginColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LoginColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: LoginColors.gradientStart,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: LoginColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: BoxDecoration(
                color: LoginColors.cardBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// LOGO
               /// LOGO
Image.asset(
  'assets/logo.png',
  width: double.infinity,  // fills available width
  height: 150,             // control height only
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    return const Icon(
      Icons.bakery_dining,
      size: 80,
      color: LoginColors.gradientStart,
    );
  },
),

                  const SizedBox(height: 20),

                  const Text(
                    'CHAMPS BAKESHOP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: LoginColors.gradientStart,
                      letterSpacing: 0.6,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'PAYROLL SYSTEM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: LoginColors.textLight,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 36),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: _label('SELECT YOUR ROLE'),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: _selectedRole.isEmpty ? null : _selectedRole,
                    decoration:
                        _inputDecoration('-- Choose Role --', Icons.badge_outlined),
                    items: const [
                      DropdownMenuItem(
                          value: 'admin', child: Text('Admin (Owner)')),
                      DropdownMenuItem(
                          value: 'master_baker', child: Text('Master Baker')),
                      DropdownMenuItem(value: 'helper', child: Text('Helper')),
                    ],
                    onChanged: _onRoleChanged,
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SizeTransition(
                      sizeFactor: _fadeAnim,
                      axisAlignment: -1,
                      child: Column(
                        children: [

                          TextField(
                            controller: _emailCtrl,
                            decoration: _inputDecoration(
                                'you@champs.com', Icons.mail_outline),
                          ),

                          const SizedBox(height: 18),

                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: _inputDecoration(
                                    'Enter password', Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),

                          const SizedBox(height: 26),
                        ],
                      ),
                    ),
                  ),

                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(
                          color: LoginColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  /// LOGIN BUTTON
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          LoginColors.gradientStart,
                          LoginColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: LoginColors.gradientStart.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: LoginColors.textLight,
          letterSpacing: 1,
        ),
      );
}