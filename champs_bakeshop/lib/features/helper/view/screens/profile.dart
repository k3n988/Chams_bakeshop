import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/hash_utils.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/product_model.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';

// ─────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────
const _kBonusUnlockedKey = 'bonus_unlocked_';
const _kOrange           = Color(0xFFFF7A00);
const _kDark             = Color(0xFF1A1A1A);

// ─────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userId;
  final Color  accentColor;
  final double grossSalary;
  final double netSalary;
  final int    daysWorked;
  final int    totalRecords;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userId,
    this.accentColor = AppColors.info,
    this.grossSalary = 0,
    this.netSalary   = 0,
    this.daysWorked  = 0,
    this.totalRecords = 0,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _photoPath;
  late String _displayName;
  late AnimationController _avatarAnim;
  late Animation<double>   _avatarScale;
  bool _bonusUnlocked = false;

  static const _photoKey = 'profile_photo_path';
  static const _nameKey  = 'profile_display_name';

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _avatarAnim  = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350));
    _avatarScale =
        CurvedAnimation(parent: _avatarAnim, curve: Curves.elasticOut);
    _avatarAnim.forward();
    _loadSavedData();
  }

  @override
  void dispose() {
    _avatarAnim.dispose();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────
  Future<void> _loadSavedData() async {
    final prefs     = await SharedPreferences.getInstance();
    final photoPath = prefs.getString('${_photoKey}_${widget.userId}');
    final savedName = prefs.getString('${_nameKey}_${widget.userId}');
    final unlocked  =
        prefs.getBool('$_kBonusUnlockedKey${widget.userId}') ?? false;
    if (!mounted) return;
    setState(() {
      _photoPath     = photoPath;
      _bonusUnlocked = unlocked;
      if (savedName != null && savedName.isNotEmpty) {
        _displayName = savedName;
      }
    });
  }

  Future<void> _savePhotoPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('${_photoKey}_${widget.userId}');
    } else {
      await prefs.setString('${_photoKey}_${widget.userId}', path);
    }
  }

  Future<void> _saveDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_nameKey}_${widget.userId}', name);
  }

  Future<void> _saveBonusUnlocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        '$_kBonusUnlockedKey${widget.userId}', value);
  }

  // ── Photo ─────────────────────────────────────────────
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoOptionsSheet(
        hasPhoto:  _photoPath != null,
        onCamera:  () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
        onRemove:  _removePhoto,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final authVm = context.read<AuthViewModel>();
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 85,
          maxWidth: 600, maxHeight: 600);
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _photoPath = picked.path);
      await _savePhotoPath(picked.path);
      await authVm.setLocalPhoto(picked.path);
      _avatarAnim..reset()..forward();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not pick image: $e', isError: true);
    }
  }

  Future<void> _removePhoto() async {
    final authVm = context.read<AuthViewModel>();
    Navigator.pop(context);
    setState(() => _photoPath = null);
    await _savePhotoPath(null);
    if (!mounted) return;
    await authVm.clearLocalPhoto();
    _avatarAnim..reset()..forward();
  }

  // ── Name ──────────────────────────────────────────────
  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding:
            const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined,
                color: _kOrange, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Edit Display Name',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            children: [
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline,
                  color: _kOrange),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: _kOrange, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _kOrange),
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _displayName = name);
              _saveDisplayName(name);
              _showSnack('Name updated!');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── My Vale ───────────────────────────────────────────
  void _showMyVale() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          Provider.value(value: context.read<DatabaseService>()),
        ],
        child: _MyValeSheet(
          userId:   widget.userId,
          userName: _displayName,
        ),
      ),
    );
  }

  // ── Price Rates ───────────────────────────────────────
  void _showPriceRates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          Provider.value(value: context.read<DatabaseService>()),
        ],
        child: _PriceRatesSheet(isMasterBaker: widget.userRole == 'master_baker'),
      ),
    );
  }

  // ── Bonus ─────────────────────────────────────────────
  void _handleBonusButton() {
    if (_bonusUnlocked) {
      _openBonusView();
    } else {
      _showBonusCodeDialog();
    }
  }

  void _showBonusCodeDialog() {
    final ctrl = TextEditingController();
    bool obscure  = true;
    bool checking = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          titlePadding:
              const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding:
              const EdgeInsets.fromLTRB(20, 16, 20, 0),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🎄',
                  style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Christmas Bonus',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              Text('Enter your bonus code',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400)),
            ]),
          ]),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFC62828)
                        .withValues(alpha: 0.15)),
              ),
              child: const Row(children: [
                Icon(Icons.lock_outline,
                    size: 16, color: Color(0xFFC62828)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ask your admin for the bonus code to unlock your holiday bonus summary.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC62828)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              obscureText: obscure,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter bonus code',
                prefixIcon: const Icon(
                    Icons.vpn_key_outlined,
                    color: Color(0xFFC62828)),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () =>
                      setDlg(() => obscure = !obscure),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFC62828), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
          actions: [
            TextButton(
                onPressed: checking ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828)),
              onPressed: checking
                  ? null
                  : () async {
                      setDlg(() => checking = true);
                      final db = context.read<DatabaseService>();
                      // Fetch bonus code from Supabase (fallback to hardcoded)
                      final serverCode = await db
                          .getConfigValue('bonus_code')
                          .catchError((_) => null);
                      final expected =
                          (serverCode ?? 'CHAMPS2026').toUpperCase();
                      if (!ctx.mounted) return;
                      if (ctrl.text.trim().toUpperCase() == expected) {
                  Navigator.pop(ctx);
                  setState(() => _bonusUnlocked = true);
                  _saveBonusUnlocked(true);
                  _openBonusView();
                } else {
                      setDlg(() => checking = false);
                  _showSnack('Incorrect bonus code.',
                      isError: true);
                }
              },
              child: checking
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  void _openBonusView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          Provider.value(value: context.read<DatabaseService>()),
        ],
        child: _BonusViewSheet(
          userId:   widget.userId,
          userName: _displayName,
          role:     widget.userRole,
          onLock: () {
            setState(() => _bonusUnlocked = false);
            _saveBonusUnlocked(false);
            _showSnack('Bonus locked.');
          },
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew     = true;
    bool obscureConfirm = true;
    bool saving         = false;
    String? errorMsg;

    final authVm = context.read<AuthViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline,
                  color: _kOrange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Change Password',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ]),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            if (errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(errorMsg!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            _PasswordField(
              controller: currentCtrl,
              label:      'Current Password',
              obscure:    obscureCurrent,
              onToggle: () => setDlgState(
                  () => obscureCurrent = !obscureCurrent),
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: newCtrl,
              label:      'New Password',
              obscure:    obscureNew,
              onToggle: () =>
                  setDlgState(() => obscureNew = !obscureNew),
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: confirmCtrl,
              label:      'Confirm Password',
              obscure:    obscureConfirm,
              onToggle: () => setDlgState(
                  () => obscureConfirm = !obscureConfirm),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _kOrange),
              onPressed: saving
                  ? null
                  : () async {
                      // ── Validate ──────────────────────
                      final current = currentCtrl.text;
                      final newPw   = newCtrl.text;
                      final confirm = confirmCtrl.text;

                      if (current.isEmpty) {
                        setDlgState(() => errorMsg =
                            'Please enter your current password.');
                        return;
                      }
                      final stored = authVm.currentUser!.password;
                      final inputHash = hashPassword(current);
                      // Support both hashed (migrated) and plaintext (legacy) accounts
                      final passwordMatches = isHashed(stored)
                          ? inputHash == stored
                          : current == stored;
                      if (!passwordMatches) {
                        setDlgState(() => errorMsg =
                            'Current password is incorrect.');
                        return;
                      }
                      if (newPw.length < 3) {
                        setDlgState(() => errorMsg =
                            'New password must be at least 3 characters.');
                        return;
                      }
                      if (newPw != confirm) {
                        setDlgState(() => errorMsg =
                            'Passwords do not match.');
                        return;
                      }
                      if (newPw == current) {
                        setDlgState(() => errorMsg =
                            'New password must differ from current.');
                        return;
                      }

                      // ── Save ──────────────────────────
                      setDlgState(() {
                        saving   = true;
                        errorMsg = null;
                      });
                      final err = await authVm.updateProfile(
                        name:     authVm.currentUser!.name,
                        password: newPw,
                      );
                      if (!ctx.mounted) return;
                      if (err != null) {
                        setDlgState(() {
                          saving   = false;
                          errorMsg = 'Failed to update: $err';
                        });
                      } else {
                        Navigator.pop(ctx);
                        _showSnack('Password updated successfully!');
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [_kOrange, Color(0xFFFFA03A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
                child: Text('🍞',
                    style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 16),
          const Text('Champs Bakeshop',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Version 1.0.0',
              style: TextStyle(color: AppColors.textHint)),
          const SizedBox(height: 8),
          const Text(
            'Production & salary management system.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _kOrange,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout,
                color: _kOrange, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Log Out',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _kOrange),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ✅ White SliverAppBar — no orange flash on scroll
          SliverAppBar(
            expandedHeight:   300,
            pinned:           true,
            elevation:        0,
            backgroundColor:  Colors.white,
            foregroundColor:  _kDark,
            surfaceTintColor: Colors.transparent,
            shadowColor:
                Colors.black.withValues(alpha: 0.08),
            // ✅ Shows name when collapsed
            title: Text(
              _displayName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kDark),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHero(
                displayName: _displayName,
                userRole:    widget.userRole,
                photoPath:   _photoPath,
                avatarScale: _avatarScale,
                initials:    _getInitials(_displayName),
                onPhotoTap:  _showPhotoOptions,
                onNameEdit:  _showEditNameDialog,
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Personal info ──────────────────────
                _ProfileCard(
                  label: 'PERSONAL INFORMATION',
                  children: [
                    _InfoRow(
                        icon:  Icons.person_outline,
                        label: 'Name',
                        value: _displayName),
                    _InfoRow(
                        icon:  Icons.badge_outlined,
                        label: 'Role',
                        value: widget.userRole),
                    _InfoRow(
                        icon:  Icons.fingerprint,
                        label: 'ID',
                        value: widget.userId),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Earnings snapshot ──────────────────
                _EarningsSnapshotCard(
                  grossSalary:  widget.grossSalary,
                  netSalary:    widget.netSalary,
                  daysWorked:   widget.daysWorked,
                  totalRecords: widget.totalRecords,
                ),
                const SizedBox(height: 10),

                // ── Price Rates button ─────────────────
                _PriceRatesButton(onTap: _showPriceRates),
                const SizedBox(height: 10),

                // ── My Vale button ─────────────────────
                _MyValeButton(onTap: _showMyVale),
                const SizedBox(height: 14),

                // ── Actions ────────────────────────────
                _ActionsCard(
                  bonusUnlocked:    _bonusUnlocked,
                  onEditName:       _showEditNameDialog,
                  onEditPhoto:      _showPhotoOptions,
                  onChangePassword: () =>
                      _showChangePasswordDialog(context),
                  onChristmasBonus: _handleBonusButton,
                  onAbout: () => _showAboutAppDialog(context),
                ),
                const SizedBox(height: 20),

                // ── Logout ─────────────────────────────
                _LogoutButton(
                    onLogout: () => _confirmLogout(context)),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PROFILE HERO  — clean white, no accentColor param
// ─────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final String            displayName;
  final String            userRole;
  final String?           photoPath;
  final Animation<double> avatarScale;
  final String            initials;
  final VoidCallback      onPhotoTap;
  final VoidCallback      onNameEdit;

  const _ProfileHero({
    required this.displayName,
    required this.userRole,
    required this.photoPath,
    required this.avatarScale,
    required this.initials,
    required this.onPhotoTap,
    required this.onNameEdit,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Avatar ─────────────────────────────
              ScaleTransition(
                scale: avatarScale,
                child: GestureDetector(
                  onTap: onPhotoTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ✅ 110px orange avatar
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kOrange
                              .withValues(alpha: 0.85),
                          border: Border.all(
                            color: _kOrange
                                .withValues(alpha: 0.15),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          image: photoPath != null
                              ? DecorationImage(
                                  image: FileImage(
                                      File(photoPath!)),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: photoPath == null
                            ? Center(
                                child: Text(initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight:
                                            FontWeight.w900)))
                            : null,
                      ),

                      // ✅ camera badge
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kOrange
                                  .withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: _kOrange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Name ───────────────────────────────
              GestureDetector(
                onTap: onNameEdit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            color: _kDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _kDark.withValues(alpha: 0.05),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: _kDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Role pill ──────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kOrange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(
                      color: _kOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ subtle bottom divider
              Container(
                height: 1,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  EARNINGS SNAPSHOT CARD
// ─────────────────────────────────────────────────────────
class _EarningsSnapshotCard extends StatelessWidget {
  final double grossSalary;
  final double netSalary;
  final int    daysWorked;
  final int    totalRecords;

  const _EarningsSnapshotCard({
    required this.grossSalary,
    required this.netSalary,
    required this.daysWorked,
    required this.totalRecords,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel('YEARLY EARNINGS — ${DateTime.now().year}'),
              const SizedBox(height: 14),

              // Orange gradient take-home box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kOrange, Color(0xFFFFA03A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      const Text('Take-Home Pay',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          formatCurrency(netSalary),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gross: ${formatCurrency(grossSalary)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(
                    child: _SnapTile(
                  icon:  Icons.work_history_outlined,
                  label: 'Days Worked',
                  value: '$daysWorked days',
                  color: AppColors.info,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _SnapTile(
                  icon:  Icons.receipt_long_outlined,
                  label: 'Total Records',
                  value: '$totalRecords',
                  color: AppColors.masterBaker,
                )),
              ]),
            ],
          ),
        ),
      );
}

class _SnapTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _SnapTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint)),
            ]),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  PROFILE CARD
// ─────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String       label;
  final List<Widget> children;
  const _ProfileCard(
      {required this.label, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _CardLabel(label),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );
}

class _CardLabel extends StatelessWidget {
  final String text;
  const _CardLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint,
          letterSpacing: 1.0));
}

// ─────────────────────────────────────────────────────────
//  INFO ROW
// ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: _kOrange),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kDark),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  ACTIONS CARD  — no accentColor param
// ─────────────────────────────────────────────────────────
class _ActionsCard extends StatelessWidget {
  final bool         bonusUnlocked;
  final VoidCallback onEditName;
  final VoidCallback onEditPhoto;
  final VoidCallback onChangePassword;
  final VoidCallback onChristmasBonus;
  final VoidCallback onAbout;

  const _ActionsCard({
    required this.bonusUnlocked,
    required this.onEditName,
    required this.onEditPhoto,
    required this.onChangePassword,
    required this.onChristmasBonus,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          _ActionItem(
            icon:     Icons.person_outline,
            label:    'Edit Display Name',
            subtitle: 'Change how your name appears',
            color:    _kOrange,
            onTap:    onEditName,
          ),
          const _ActionDivider(),
          _ActionItem(
            icon:     Icons.camera_alt_outlined,
            label:    'Edit Profile Photo',
            subtitle: 'Upload or remove your photo',
            color:    const Color(0xFF1976D2),
            onTap:    onEditPhoto,
          ),
          const _ActionDivider(),
          _ActionItem(
            icon:     Icons.lock_outline,
            label:    'Change Password',
            subtitle: 'Update your account password',
            color:    const Color(0xFF5D4037),
            onTap:    onChangePassword,
          ),
          const _ActionDivider(),
          _ActionItem(
            icon:     bonusUnlocked
                ? Icons.card_giftcard
                : Icons.card_giftcard_outlined,
            label:    'Christmas Bonus',
            subtitle: bonusUnlocked
                ? 'View your holiday bonus summary'
                : 'Enter code to unlock your bonus',
            color:    const Color(0xFFC62828),
            trailing: bonusUnlocked
                ? _StatusChip(
                    label: 'Unlocked',
                    color: AppColors.success)
                : _StatusChip(
                    label: 'Locked 🔒',
                    color: const Color(0xFFC62828)),
            onTap: onChristmasBonus,
          ),
          const _ActionDivider(),
          _ActionItem(
            icon:     Icons.info_outline,
            label:    'About',
            subtitle: 'App version & info',
            color:    _kOrange,
            onTap:    onAbout,
            isLast:   true,
          ),
        ]),
      );
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) => const Divider(
      height: 1,
      indent: 56,
      color: Color(0xFFF5F5F5));
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class _ActionItem extends StatelessWidget {
  final IconData     icon;
  final String       label, subtitle;
  final Color        color;
  final VoidCallback onTap;
  final bool         isLast;
  final Widget?      trailing;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast   = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.vertical(
                bottom: Radius.circular(16))
            : BorderRadius.zero,
        child: ListTile(
          shape: isLast
              ? const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16)))
              : null,
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint)),
          trailing: trailing ??
              Icon(Icons.chevron_right,
                  color: AppColors.textHint
                      .withValues(alpha: 0.5),
                  size: 20),
          onTap: onTap,
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity, height: 50,
        child: OutlinedButton.icon(
          onPressed: onLogout,
          icon:  const Icon(Icons.logout, size: 18),
          label: const Text('Log Out',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kOrange,
            side: BorderSide(color: _kOrange.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  PASSWORD FIELD
// ─────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String       label;
  final bool         obscure;
  final VoidCallback onToggle;
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: onToggle,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  PHOTO OPTIONS SHEET
// ─────────────────────────────────────────────────────────
class _PhotoOptionsSheet extends StatelessWidget {
  final bool         hasPhoto;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoOptionsSheet({
    required this.hasPhoto,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Profile Photo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kDark)),
          ),
          const SizedBox(height: 4),
          const Text('Choose how to update your photo',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _OptionTile(
            icon:     Icons.camera_alt_outlined,
            label:    'Take a Photo',
            subtitle: 'Use your camera',
            color:    const Color(0xFF1976D2),
            onTap:    onCamera,
          ),
          const Divider(height: 1, indent: 56),
          _OptionTile(
            icon:     Icons.photo_library_outlined,
            label:    'Choose from Gallery',
            subtitle: 'Pick from your photos',
            color:    AppColors.success,
            onTap:    onGallery,
          ),
          if (hasPhoto) ...[
            const Divider(height: 1, indent: 56),
            _OptionTile(
              icon:     Icons.delete_outline,
              label:    'Remove Photo',
              subtitle: 'Revert to initials',
              color:    AppColors.danger,
              onTap:    onRemove,
            ),
          ],
          SizedBox(
              height: 12 +
                  MediaQuery.of(context).padding.bottom),
        ]),
      );
}

class _OptionTile extends StatelessWidget {
  final IconData     icon;
  final String       label, subtitle;
  final Color        color;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textHint)),
        onTap: onTap,
      );
}

// ─────────────────────────────────────────────────────────
//  BONUS VIEW SHEET
// ─────────────────────────────────────────────────────────
class _BonusViewSheet extends StatefulWidget {
  final String       userId;
  final String       userName;
  final String       role;
  final VoidCallback onLock;

  const _BonusViewSheet({
    required this.userId,
    required this.userName,
    required this.role,
    required this.onLock,
  });

  @override
  State<_BonusViewSheet> createState() =>
      _BonusViewSheetState();
}

class _BonusViewSheetState extends State<_BonusViewSheet> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading    = true;
  int  _selectedYear  = DateTime.now().year;
  int  _selectedMonth = DateTime.now().month;

  static const _monthNames = [
    'January',   'February', 'March',    'April',
    'May',       'June',     'July',     'August',
    'September', 'October',  'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final db   = context.read<DatabaseService>();
      final rows = await db.getChristmasBonuses(
          year: _selectedYear);
      _entries = rows
          .where((r) => r['user_id'] == widget.userId)
          .toList()
        ..sort((a, b) =>
            (b['date'] ?? '').compareTo(a['date'] ?? ''));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _monthEntries =>
      _entries.where((e) {
        final d = DateTime.tryParse(
            (e['date'] ?? '').toString().substring(0, 10));
        return d != null &&
            d.month == _selectedMonth &&
            d.year == _selectedYear;
      }).toList();

  double get _monthTotal => _monthEntries.fold(
      0.0, (s, e) => s + (e['amount'] as num).toDouble());

  double get _yearTotal => _entries.fold(
      0.0, (s, e) => s + (e['amount'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🎄',
                    style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                  const Text('My Christmas Bonus',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC62828),
                          letterSpacing: -0.3)),
                  Text(widget.userName,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.lock_outline,
                    size: 20, color: AppColors.textHint),
                tooltip: 'Lock bonus',
                onPressed: () {
                  Navigator.pop(context);
                  widget.onLock();
                },
              ),
            ]),
          ),
          const Divider(height: 20),

          // Year selector
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: Color(0xFFC62828)),
              onPressed: () {
                setState(() {
                  _selectedYear--;
                  _selectedMonth = 1;
                });
                _load();
              },
            ),
            Text('$_selectedYear',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFFC62828))),
            IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: Color(0xFFC62828)),
              onPressed: () {
                setState(() {
                  _selectedYear++;
                  _selectedMonth = 1;
                });
                _load();
              },
            ),
          ]),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFC62828)))
                : ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 32),
                    children: [
                      // Year banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFC62828),
                              Color(0xFFE53935)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC62828)
                                  .withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(children: [
                          const Text('🎁',
                              style:
                                  TextStyle(fontSize: 30)),
                          const SizedBox(height: 8),
                          Text(
                            'TOTAL BONUS $_selectedYear',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Text(
                              formatCurrency(_yearTotal),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight:
                                      FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_entries.length} entr${_entries.length != 1 ? 'ies' : 'y'} total',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Month chips
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 12,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final m   = i + 1;
                            final sel = m == _selectedMonth;
                            final cnt = _entries.where((e) {
                              final d = DateTime.tryParse(
                                  (e['date'] ?? '')
                                      .toString()
                                      .substring(0, 10));
                              return d != null &&
                                  d.month == m &&
                                  d.year == _selectedYear;
                            }).length;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedMonth = m),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(
                                          0xFFC62828)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: sel
                                          ? const Color(
                                                  0xFFC62828)
                                              .withValues(
                                                  alpha: 0.3)
                                          : Colors.black
                                              .withValues(
                                                  alpha:
                                                      0.04),
                                      blurRadius:
                                          sel ? 8 : 6,
                                      offset: const Offset(
                                          0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                  Text(
                                    _monthNames[i]
                                        .substring(0, 3),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: sel
                                            ? Colors.white
                                            : AppColors
                                                .textSecondary),
                                  ),
                                  if (cnt > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .all(3),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? Colors.white
                                                .withValues(
                                                    alpha: 0.3)
                                            : const Color(
                                                    0xFFC62828)
                                                .withValues(
                                                    alpha:
                                                        0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$cnt',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight:
                                                FontWeight.w800,
                                            color: sel
                                                ? Colors.white
                                                : const Color(
                                                    0xFFC62828)),
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Month summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                          Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(
                              '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                  fontWeight:
                                      FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(_monthTotal),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.w900,
                                  color:
                                      Color(0xFFC62828)),
                            ),
                          ]),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828)
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_monthEntries.length} entr${_monthEntries.length != 1 ? 'ies' : 'y'}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Color(0xFFC62828)),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // Daily entries
                      if (_monthEntries.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 36),
                          alignment: Alignment.center,
                          child: Column(children: [
                            Icon(
                                Icons.card_giftcard_outlined,
                                size: 40,
                                color: AppColors.textHint
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 10),
                            Text(
                              'No bonus for ${_monthNames[_selectedMonth - 1]}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textHint,
                                  fontWeight:
                                      FontWeight.w500),
                            ),
                          ]),
                        )
                      else ...[
                        const _BonusLabel('DAILY BREAKDOWN'),
                        const SizedBox(height: 8),
                        ..._monthEntries.map(
                            (e) => _BonusEntryRow(entry: e)),
                      ],
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BONUS ENTRY ROW
// ─────────────────────────────────────────────────────────
class _BonusEntryRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _BonusEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date   =
        (entry['date'] ?? '').toString().substring(0, 10);
    final amount =
        (entry['amount'] as num).toDouble();
    final note   = entry['note'] as String?;
    final isAuto = entry['production_id'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFC62828)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.card_giftcard_outlined,
              color: Color(0xFFC62828), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(date,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.text)),
              if (isAuto) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Production',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info)),
                ),
              ],
            ]),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(note,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic)),
            ],
          ]),
        ),
        Text(
          formatCurrency(amount),
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFFC62828)),
        ),
      ]),
    );
  }
}

class _BonusLabel extends StatelessWidget {
  final String text;
  const _BonusLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(2)),
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

// ─────────────────────────────────────────────────────────
//  PRICE RATES BUTTON
// ─────────────────────────────────────────────────────────
class _PriceRatesButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PriceRatesButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _kOrange.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.price_change_outlined,
                    color: _kOrange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('View Price Rates',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kDark)),
                    SizedBox(height: 2),
                    Text('Product prices set by admin',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                  size: 20),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  PRICE RATES SHEET
// ─────────────────────────────────────────────────────────
class _PriceRatesSheet extends StatefulWidget {
  final bool isMasterBaker;
  const _PriceRatesSheet({required this.isMasterBaker});

  @override
  State<_PriceRatesSheet> createState() => _PriceRatesSheetState();
}

class _PriceRatesSheetState extends State<_PriceRatesSheet> {
  List<ProductModel> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = context.read<DatabaseService>();
      final list = await db.getAllProducts();
      if (mounted) setState(() { _products = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.price_change_outlined,
                    color: _kOrange, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price Rates',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                            letterSpacing: -0.3)),
                    Text('Set by admin · read only',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
              ),
            ]),
          ),

          const Divider(height: 24, color: AppColors.border),

          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(children: [
              const Expanded(
                child: Text('PRODUCT',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHint,
                        letterSpacing: 0.8)),
              ),
              SizedBox(
                width: widget.isMasterBaker ? 90 : 80,
                child: Text('PRICE/SACK',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHint,
                        letterSpacing: 0.8)),
              ),
              if (widget.isMasterBaker) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 82,
                  child: Text('BONUS/SACK',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHint,
                          letterSpacing: 0.8)),
                ),
              ],
            ]),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _kOrange, strokeWidth: 2.5))
                : _products.isEmpty
                    ? const Center(
                        child: Text('No products found',
                            style: TextStyle(color: AppColors.textHint)))
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ProductRateRow(
                          product:       _products[i],
                          isMasterBaker: widget.isMasterBaker,
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PRODUCT RATE ROW
// ─────────────────────────────────────────────────────────
class _ProductRateRow extends StatelessWidget {
  final ProductModel product;
  final bool         isMasterBaker;
  const _ProductRateRow({
    required this.product,
    required this.isMasterBaker,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bakery_dining_outlined,
                color: _kOrange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kDark),
            ),
          ),
          // Price per sack
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formatCurrency(product.pricePerSack),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kOrange),
            ),
          ),
          // Bonus per sack — master baker only
          if (isMasterBaker) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formatCurrency(product.bonusPerSack),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF388E3C)),
              ),
            ),
          ],
        ]),
      );
}

// ─────────────────────────────────────────────────────────
//  MY VALE BUTTON
// ─────────────────────────────────────────────────────────
class _MyValeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MyValeButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Vale',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kDark)),
                    SizedBox(height: 2),
                    Text('View your borrowed items from the store',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                  size: 20),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  MY VALE SHEET
// ─────────────────────────────────────────────────────────
class _MyValeSheet extends StatefulWidget {
  final String userId;
  final String userName;
  const _MyValeSheet({required this.userId, required this.userName});

  @override
  State<_MyValeSheet> createState() => _MyValeSheetState();
}

class _MyValeSheetState extends State<_MyValeSheet> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final db   = context.read<DatabaseService>();
      final rows = await db.getValeEntriesByUser(widget.userId);
      // Show only unsettled
      if (mounted) {
        setState(() {
          _entries = rows
              .where((r) => !(r['is_settled'] as bool? ?? false))
              .toList()
            ..sort((a, b) =>
                (b['date'] ?? '').compareTo(a['date'] ?? ''));
        });
      }
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _total =>
      _entries.fold(0.0, (s, e) => s + (e['price'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Vale',
                        style: TextStyle(
                            fontSize:     17,
                            fontWeight:   FontWeight.w800,
                            color:        _kDark,
                            letterSpacing: -0.3)),
                    Text(widget.userName,
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColors.textHint)),
                  ],
                ),
              ),
              // Total chip
              if (!_loading)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _total > 0
                        ? AppColors.danger.withValues(alpha: 0.08)
                        : AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _total > 0
                          ? AppColors.danger.withValues(alpha: 0.25)
                          : AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    formatCurrency(_total),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize:   15,
                        color: _total > 0
                            ? AppColors.danger
                            : AppColors.success),
                  ),
                ),
            ]),
          ),

          const Divider(height: 20, color: AppColors.border),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.danger, strokeWidth: 2.5))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.07),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.check_circle_outline,
                                  size: 40,
                                  color: AppColors.success),
                            ),
                            const SizedBox(height: 14),
                            const Text('No outstanding vale',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize:   15,
                                    color:      _kDark)),
                            const SizedBox(height: 4),
                            const Text(
                                'You have no borrowed items from the store.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:    AppColors.textHint)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: _entries.length + 1,
                        itemBuilder: (_, i) {
                          // Total banner at the bottom
                          if (i == _entries.length) {
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kOrange, Color(0xFFFFA03A)],
                                  begin: Alignment.topLeft,
                                  end:   Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kOrange.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('TOTAL VALE',
                                          style: TextStyle(
                                              fontSize:      10,
                                              fontWeight:    FontWeight.w700,
                                              color:         Colors.white70,
                                              letterSpacing: 0.8)),
                                      SizedBox(height: 2),
                                      Text('Amount to settle',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:    Colors.white60)),
                                    ],
                                  ),
                                  Text(
                                    formatCurrency(_total),
                                    style: const TextStyle(
                                        fontSize:     22,
                                        fontWeight:   FontWeight.w900,
                                        color:        Colors.white,
                                        letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                            );
                          }

                          final e       = _entries[i];
                          final name    = e['product_name'] as String? ?? '—';
                          final price   = (e['price'] as num).toDouble();
                          final date    = (e['date'] ?? '') as String;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color:        Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.black
                                      .withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset:     const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(children: [
                                // Item icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppColors.danger,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                // Name + date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize:   14,
                                              color:      _kDark)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 11,
                                            color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(date,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textHint)),
                                      ]),
                                    ],
                                  ),
                                ),
                                // Price
                                Text(
                                  formatCurrency(price),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize:   15,
                                      color:      AppColors.danger),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
