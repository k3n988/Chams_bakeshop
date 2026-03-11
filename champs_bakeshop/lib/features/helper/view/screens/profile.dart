import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';

// ─────────────────────────────────────────────────────────
//  PROFILE SCREEN  (StatefulWidget — owns photo + name state)
// ─────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userId;
  final Color accentColor;
  final double grossSalary;
  final double netSalary;
  final int daysWorked;
  final int totalRecords;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userId,
    this.accentColor = AppColors.info,
    this.grossSalary = 0,
    this.netSalary = 0,
    this.daysWorked = 0,
    this.totalRecords = 0,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────
  String? _photoPath;          // local file path saved in SharedPreferences
  late String _displayName;    // editable display name
  late AnimationController _avatarAnim;
  late Animation<double> _avatarScale;

  static const _photoKey = 'profile_photo_path';
  static const _nameKey  = 'profile_display_name';

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _avatarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _avatarScale = CurvedAnimation(parent: _avatarAnim, curve: Curves.elasticOut);
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
    final prefs = await SharedPreferences.getInstance();
    // Key is scoped to userId so different users don't share photos
    final photoPath = prefs.getString('${_photoKey}_${widget.userId}');
    final savedName = prefs.getString('${_nameKey}_${widget.userId}');
    if (!mounted) return;
    setState(() {
      _photoPath = photoPath;
      if (savedName != null && savedName.isNotEmpty) _displayName = savedName;
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

  // ── Photo Actions ─────────────────────────────────────
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoOptionsSheet(
        hasPhoto: _photoPath != null,
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
        onRemove: _removePhoto,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked == null) return;
      setState(() => _photoPath = picked.path);
      await _savePhotoPath(picked.path);
      _avatarAnim
        ..reset()
        ..forward();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not pick image: $e', isError: true);
    }
  }

  void _removePhoto() {
    Navigator.pop(context);
    setState(() => _photoPath = null);
    _savePhotoPath(null);
    _avatarAnim
      ..reset()
      ..forward();
  }

  // ── Name Editing ──────────────────────────────────────
  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.edit_outlined,
                color: widget.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Edit Display Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon:
                  Icon(Icons.person_outline, color: widget.accentColor),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: widget.accentColor, width: 1.5),
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
                backgroundColor: widget.accentColor),
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

  // ── UI Helpers ────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: CustomScrollView(
        slivers: [
          // ── Sticky Header ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: widget.accentColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(
                displayName: _displayName,
                userRole: widget.userRole,
                photoPath: _photoPath,
                accentColor: widget.accentColor,
                avatarScale: _avatarScale,
                initials: _getInitials(_displayName),
                onPhotoTap: _showPhotoOptions,
                onNameEdit: _showEditNameDialog,
              ),
            ),
          ),

          // ── Body Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Personal Info
                _ProfileCard(
                  label: 'PERSONAL INFORMATION',
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: _displayName,
                        accentColor: widget.accentColor),
                    _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: widget.userRole,
                        accentColor: widget.accentColor),
                    _InfoRow(
                        icon: Icons.fingerprint,
                        label: 'ID',
                        value: widget.userId,
                        accentColor: widget.accentColor),
                  ],
                ),
                const SizedBox(height: 12),

                // Earnings
                _ProfileCard(
                  label: 'EARNINGS SNAPSHOT',
                  children: [
                    _EarningRow(
                      label: 'Total Gross',
                      value: formatCurrency(widget.grossSalary),
                      color: widget.accentColor,
                    ),
                    _EarningRow(
                      label: 'Take-Home Pay',
                      value: formatCurrency(widget.netSalary),
                      color: const Color(0xFF388E3C),
                    ),
                    const Divider(height: 20),
                    _EarningRow(
                      label: 'Days Worked (Week)',
                      value: '${widget.daysWorked} days',
                      color: const Color(0xFF1976D2),
                    ),
                    _EarningRow(
                      label: 'Total Records',
                      value: '${widget.totalRecords}',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Actions
                _ActionsCard(
                  accentColor: widget.accentColor,
                  onEditName: _showEditNameDialog,
                  onEditPhoto: _showPhotoOptions,
                  onChangePassword: () => _showChangePasswordDialog(context),
                  onChristmasBonus: () => _showChristmasBonusDialog(context),
                  onAbout: () => _showAboutAppDialog(context),
                ),
                const SizedBox(height: 20),

                // Logout
                _LogoutButton(onLogout: () => _confirmLogout(context)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────
  void _showChristmasBonusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.card_giftcard,
                color: Color(0xFFC62828), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Christmas Bonus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFC62828), Color(0xFFE53935)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(children: [
              Text('🎄', style: TextStyle(fontSize: 34)),
              SizedBox(height: 8),
              Text('BONUS STATUS',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              SizedBox(height: 4),
              Text('Pending',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 16),
          _BonusRow('Eligibility', 'Tenure & performance'),
          _BonusRow('Payout', 'December payroll'),
          _BonusRow('Status', 'Awaiting admin approval'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Computed and approved by admin. Contact your manager for details.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ]),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Bonus request sent! Admin will review it.');
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Request'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_outline,
                  color: widget.accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Change Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _PasswordField(
              controller: currentCtrl,
              label: 'Current Password',
              obscure: obscureCurrent,
              onToggle: () =>
                  setDlgState(() => obscureCurrent = !obscureCurrent),
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: newCtrl,
              label: 'New Password',
              obscure: obscureNew,
              onToggle: () => setDlgState(() => obscureNew = !obscureNew),
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: confirmCtrl,
              label: 'Confirm Password',
              obscure: obscureConfirm,
              onToggle: () =>
                  setDlgState(() => obscureConfirm = !obscureConfirm),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor),
              onPressed: () {
                if (newCtrl.text.length < 6) {
                  _showSnack('Password must be at least 6 characters',
                      isError: true);
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  _showSnack('Passwords do not match', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                _showSnack('Password updated successfully!');
              },
              child: const Text('Update'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.7)],
              ),
            ),
            child: const Center(
                child: Text('🍞', style: TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 14),
          const Text('Champs Bakeshop',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Version 1.0.0',
              style: TextStyle(color: AppColors.textHint)),
          const SizedBox(height: 8),
          const Text('Production & salary management system.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                backgroundColor: AppColors.danger),
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
}

// ─────────────────────────────────────────────────────────
//  PROFILE HERO  (SliverAppBar background)
// ─────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final String displayName;
  final String userRole;
  final String? photoPath;
  final Color accentColor;
  final Animation<double> avatarScale;
  final String initials;
  final VoidCallback onPhotoTap;
  final VoidCallback onNameEdit;

  const _ProfileHero({
    required this.displayName,
    required this.userRole,
    required this.photoPath,
    required this.accentColor,
    required this.avatarScale,
    required this.initials,
    required this.onPhotoTap,
    required this.onNameEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromColor(accentColor)
                .withLightness(
                    (HSLColor.fromColor(accentColor).lightness - 0.12)
                        .clamp(0.0, 1.0))
                .toColor(),
            accentColor,
            HSLColor.fromColor(accentColor)
                .withLightness(
                    (HSLColor.fromColor(accentColor).lightness + 0.08)
                        .clamp(0.0, 1.0))
                .toColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // Avatar with edit badge
            ScaleTransition(
              scale: avatarScale,
              child: GestureDetector(
                onTap: onPhotoTap,
                child: Stack(
                  children: [
                    // Photo / initials circle
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        image: photoPath != null
                            ? DecorationImage(
                                image: FileImage(File(photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoPath == null
                          ? Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                          : null,
                    ),

                    // Camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name + edit icon
            GestureDetector(
              onTap: onNameEdit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit, size: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Role pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                userRole.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PHOTO OPTIONS BOTTOM SHEET
// ─────────────────────────────────────────────────────────
class _PhotoOptionsSheet extends StatelessWidget {
  final bool hasPhoto;
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Profile Photo',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose how to update your photo',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),

        _OptionTile(
          icon: Icons.camera_alt_outlined,
          label: 'Take a Photo',
          subtitle: 'Use your camera',
          color: const Color(0xFF1976D2),
          onTap: onCamera,
        ),
        const Divider(height: 1, indent: 56),
        _OptionTile(
          icon: Icons.photo_library_outlined,
          label: 'Choose from Gallery',
          subtitle: 'Pick from your photos',
          color: const Color(0xFF388E3C),
          onTap: onGallery,
        ),
        if (hasPhoto) ...[
          const Divider(height: 1, indent: 56),
          _OptionTile(
            icon: Icons.delete_outline,
            label: 'Remove Photo',
            subtitle: 'Revert to initials',
            color: AppColors.danger,
            onTap: onRemove,
          ),
        ],
        SizedBox(
            height: 12 + MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
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
}

// ─────────────────────────────────────────────────────────
//  REUSABLE CARD
// ─────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _ProfileCard({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  INFO ROW
// ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: accentColor),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textHint),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1A1A1A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EARNING ROW
// ─────────────────────────────────────────────────────────
class _EarningRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EarningRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ACTIONS CARD
// ─────────────────────────────────────────────────────────
class _ActionsCard extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onEditName;
  final VoidCallback onEditPhoto;
  final VoidCallback onChangePassword;
  final VoidCallback onChristmasBonus;
  final VoidCallback onAbout;

  const _ActionsCard({
    required this.accentColor,
    required this.onEditName,
    required this.onEditPhoto,
    required this.onChangePassword,
    required this.onChristmasBonus,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        _ActionItem(
          icon: Icons.person_outline,
          label: 'Edit Display Name',
          subtitle: 'Change how your name appears',
          color: accentColor,
          onTap: onEditName,
        ),
        const Divider(height: 1, indent: 56),
        _ActionItem(
          icon: Icons.camera_alt_outlined,
          label: 'Edit Profile Photo',
          subtitle: 'Upload or remove your photo',
          color: const Color(0xFF1976D2),
          onTap: onEditPhoto,
        ),
        const Divider(height: 1, indent: 56),
        _ActionItem(
          icon: Icons.lock_outline,
          label: 'Change Password',
          subtitle: 'Update your account password',
          color: const Color(0xFF5D4037),
          onTap: onChangePassword,
        ),
        const Divider(height: 1, indent: 56),
        _ActionItem(
          icon: Icons.card_giftcard_outlined,
          label: 'Christmas Bonus',
          subtitle: 'View or request your holiday bonus',
          color: const Color(0xFFC62828),
          onTap: onChristmasBonus,
        ),
        const Divider(height: 1, indent: 56),
        _ActionItem(
          icon: Icons.info_outline,
          label: 'About',
          subtitle: 'App version & info',
          color: accentColor,
          onTap: onAbout,
          isLast: true,
        ),
      ]),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: ListTile(
        shape: isLast
            ? const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)))
            : null,
        leading: Container(
          width: 38,
          height: 38,
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
                fontSize: 12, color: AppColors.textHint)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textHint, size: 20),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BONUS INFO ROW
// ─────────────────────────────────────────────────────────
class _BonusRow extends StatelessWidget {
  final String label;
  final String value;
  const _BonusRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PASSWORD FIELD WIDGET
// ─────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon:
              Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }
}