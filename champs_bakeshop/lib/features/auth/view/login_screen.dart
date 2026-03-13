import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../admin/view/screens/admin_dashboard.dart';
import '../../master_baker/view/screens/master_baker_dashboard.dart';
import '../../helper/view/screens/helper_dashboard.dart';

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
      // ── ADDED AUTO-FILL LOGIC HERE ──
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
    } else if (!mounted) {
      return;
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials or wrong role selected'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF6EC), Color(0xFFF5E6CC), Color(0xFFE8D5B5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      // FIX: withOpacity → withValues()
                      color: AppColors.text.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo ──
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            // FIX: withOpacity → withValues()
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                          child: Text('🧁', style: TextStyle(fontSize: 36))),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CHAMPS BAKESHOP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PAYROLL SYSTEM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Role Dropdown ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _label('SELECT YOUR ROLE'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // FIX: value → initialValue
                      initialValue: _selectedRole.isEmpty ? null : _selectedRole,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline,
                            color: AppColors.textHint, size: 20),
                        filled: true,
                        fillColor: _selectedRole.isNotEmpty
                            // FIX: withOpacity → withValues()
                            ? AppColors.primaryLight.withValues(alpha: 0.15)
                            : AppColors.background,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _selectedRole.isNotEmpty
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      hint: const Text('-- Choose Role --'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin (Owner)')),
                        DropdownMenuItem(
                            value: 'master_baker', child: Text('Master Baker')),
                        DropdownMenuItem(value: 'helper', child: Text('Helper')),
                      ],
                      onChanged: _onRoleChanged,
                    ),
                    const SizedBox(height: 20),

                    // ── Email & Password (animated) ──
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SizeTransition(
                        sizeFactor: _fadeAnim,
                        axisAlignment: -1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('EMAIL ADDRESS'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'you@champs.com',
                                prefixIcon: Icon(Icons.mail_outline,
                                    color: AppColors.textHint, size: 20),
                              ),
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 18),
                            _label('PASSWORD'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppColors.textHint, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textHint,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),

                    // ── Error Message ──
                    if (auth.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          // FIX: withOpacity → withValues()
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Sign In Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign In',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
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
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      );
}