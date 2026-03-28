import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'login_screen.dart';
import '../../admin/view/screens/admin_dashboard.dart';
import '../../master_baker/view/screens/master_baker_dashboard.dart';
import '../../helper/view/screens/helper_dashboard.dart';
import '../../packer/view/screens/packer_dashboard.dart';
import '../../seller/view/screens/seller_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo: zoom + fade in
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoScale;
  late final Animation<double>   _logoFade;

  // Glow pulse ring after logo lands
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowScale;
  late final Animation<double>   _glowOpacity;

  // Text: slide up + fade
  late final AnimationController _textCtrl;
  late final Animation<double>   _textFade;
  late final Animation<Offset>   _textSlide;

  // Divider line grows outward
  late final AnimationController _lineCtrl;
  late final Animation<double>   _lineWidth;

  // Bottom loader fades in last
  late final AnimationController _loaderCtrl;
  late final Animation<double>   _loaderFade;

  @override
  void initState() {
    super.initState();

    // ── Logo zoom (0 → 900 ms): 0 → 1.18 → 0.93 → 1.0 ──────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.93)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
    ]).animate(_logoCtrl);
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // ── Text (starts 400 ms after logo) ───────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );

    // ── Divider (starts 650 ms after logo) ────────────────
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOut),
    );

    // ── Glow pulse ring (fires once after logo lands) ─────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );
    _glowOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeIn),
    );

    // ── Loader dots (starts 950 ms after logo) ────────────
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeIn),
    );

    _runSequence();
    _init();
  }

  Future<void> _runSequence() async {
    await _logoCtrl.forward();
    _glowCtrl.forward(); // fire glow ring as logo finishes landing
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _textCtrl.forward();
    _lineCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _loaderCtrl.forward();
  }

  Future<void> _init() async {
    final results = await Future.wait([
      context.read<AuthViewModel>().tryAutoLogin(),
      Future<void>.delayed(const Duration(milliseconds: 2400)),
    ]);

    if (!mounted) return;

    final restored = results[0] as bool;
    Widget destination;

    if (!restored) {
      destination = const LoginScreen();
    } else {
      final user = context.read<AuthViewModel>().currentUser!;
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
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    _lineCtrl.dispose();
    _loaderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [

            // ── Main centred content ─────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── Logo + glow ring ──────────────────────
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Expanding glow ring
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) => Transform.scale(
                              scale: _glowScale.value,
                              child: Opacity(
                                opacity: _glowOpacity.value,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFF7A00),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Logo
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: Image.asset(
                                'assets/logo.png',
                                width: 150,
                                height: 150,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── App name ──────────────────────────────
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: const Text(
                          'CHAMPS BAKESHOP',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF7A00),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Divider ───────────────────────────────
                    AnimatedBuilder(
                      animation: _lineWidth,
                      builder: (_, __) => Container(
                        height: 1.5,
                        width: 160 * _lineWidth.value,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF7A00),
                              Color(0xFFFFB74D),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Subtitle ──────────────────────────────
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: const Text(
                          'PAYROLL SYSTEM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBCAAA4),
                            letterSpacing: 3.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Loading dots (bottom) ───────────────────────
            Positioned(
              bottom: 52,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _loaderFade,
                child: const Column(
                  children: [
                    _BouncingDots(),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBCAAA4),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOUNCING DOTS
// ─────────────────────────────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final raw       = (_ctrl.value * 3) - i;
            final phase     = (raw % 3).clamp(0.0, 3.0);
            final normalized =
                phase < 1.0 ? phase : (phase < 2.0 ? 2.0 - phase : 0.0);
            final bounce =
                Curves.easeInOut.transform(normalized.clamp(0.0, 1.0));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -8 * bounce),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      const Color(0xFFFFB74D),
                      const Color(0xFFFF7A00),
                      bounce,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
