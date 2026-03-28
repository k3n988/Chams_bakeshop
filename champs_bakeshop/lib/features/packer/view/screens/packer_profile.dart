import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodel/packer_salary_viewmodel.dart';
import '../../../auth/view/login_screen.dart';
import 'packer_all_report_screen.dart';

class PackerProfileScreen extends StatefulWidget {
  const PackerProfileScreen({super.key});

  @override
  State<PackerProfileScreen> createState() => _PackerProfileScreenState();
}

class _PackerProfileScreenState extends State<PackerProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving       = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Pick photo ───────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (xfile == null) return;
    if (mounted) await context.read<AuthViewModel>().setLocalPhoto(xfile.path);
  }

  Future<ImageSource?> _showSourceDialog() =>
      showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.packer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.packer),
              ),
              title: const Text('Camera',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.packer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.packer),
              ),
              title: const Text('Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      );

  // ── Open edit bottom sheet ────────────────────────────────
  void _openEditSheet() {
    final user = context.read<AuthViewModel>().currentUser!;
    _nameCtrl.text    = user.name;
    _passCtrl.text    = '';
    _confirmCtrl.text = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditSheet(
        nameCtrl:    _nameCtrl,
        passCtrl:    _passCtrl,
        confirmCtrl: _confirmCtrl,
        accentColor: AppColors.packer,
        onSave:      _save,
        saving:      _saving,
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final conf = _confirmCtrl.text.trim();

    if (name.isEmpty) { _snack('Name cannot be empty'); return; }
    if (pass.isNotEmpty && pass != conf) { _snack('Passwords do not match'); return; }

    setState(() => _saving = true);
    final currentPass = context.read<AuthViewModel>().currentUser!.password;
    final err = await context.read<AuthViewModel>().updateProfile(
      name:     name,
      password: pass.isEmpty ? currentPass : pass,
    );
    setState(() => _saving = false);

    if (err != null) {
      _snack('Error: $err');
    } else {
      if (mounted) Navigator.pop(context);
      _snack('Profile updated');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle),
            child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Sign Out',
              style: TextStyle(fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark)),
        ]),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthViewModel>().logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser!;
    final vm   = context.watch<PackerSalaryViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(children: [
        // ── Profile card ─────────────────────────────────────
        _ProfileCard(
          user:        user,
          photoPath:   auth.localPhotoPath,
          onEditPhoto: _pickPhoto,
          onEdit:      _openEditSheet,
        ),
        const SizedBox(height: 16),

        // ── Annual earnings ───────────────────────────────────
        _EarningsCard(vm: vm),
        const SizedBox(height: 16),

        // ── How it works ─────────────────────────────────────
        const _HowItWorksCard(),
        const SizedBox(height: 16),

        // ── All packers report ────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: const Text('View All Packers Report',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.packer,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PackerAllReportScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Logout ───────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
            label: const Text('Sign Out',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _confirmLogout,
          ),
        ),
      ]),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final dynamic      user;
  final String?      photoPath;
  final VoidCallback onEditPhoto;
  final VoidCallback onEdit;
  const _ProfileCard({
    required this.user,
    required this.photoPath,
    required this.onEditPhoto,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.packer, AppColors.packer.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: AppColors.packer.withValues(alpha: 0.28),
            blurRadius: 16, offset: const Offset(0, 6),
          )],
        ),
        child: Column(children: [
          // ── Avatar with edit overlay ──────────────────────
          Stack(alignment: Alignment.bottomRight, children: [
            GestureDetector(
              onTap: onEditPhoto,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                backgroundImage: photoPath != null
                    ? FileImage(File(photoPath!))
                    : null,
                child: photoPath == null
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      )
                    : null,
              ),
            ),
            GestureDetector(
              onTap: onEditPhoto,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4)],
                ),
                child: const Icon(Icons.camera_alt,
                    size: 14, color: AppColors.packer),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(user.name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(user.email,
              style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 14),
          // ── Edit button ───────────────────────────────────
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('Edit Profile',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
          ),
        ]),
      );
}

// ── Edit bottom sheet ─────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final Color        accentColor;
  final VoidCallback onSave;
  final bool         saving;

  const _EditSheet({
    required this.nameCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.accentColor,
    required this.onSave,
    required this.saving,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  bool _obscurePass = true;
  bool _obscureConf = true;

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: widget.accentColor.withValues(alpha: 0.6), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            const Text('Edit Profile',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 4),
            const Text('Update your name or password',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Name
            const _FieldLabel('Display Name'),
            const SizedBox(height: 6),
            TextField(
              controller: widget.nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco('Your name', Icons.person_outline),
            ),
            const SizedBox(height: 16),

            // New password
            const _FieldLabel('New Password'),
            const SizedBox(height: 6),
            TextField(
              controller: widget.passCtrl,
              obscureText: _obscurePass,
              decoration: _inputDeco(
                      'Leave blank to keep current', Icons.lock_outline)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textHint),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password
            const _FieldLabel('Confirm Password'),
            const SizedBox(height: 6),
            TextField(
              controller: widget.confirmCtrl,
              obscureText: _obscureConf,
              decoration:
                  _inputDeco('Re-enter new password', Icons.lock_outline)
                      .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConf
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textHint),
                  onPressed: () =>
                      setState(() => _obscureConf = !_obscureConf),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: widget.saving ? null : widget.onSave,
                child: widget.saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary));
}

// ── Annual earnings card ──────────────────────────────────────
class _EarningsCard extends StatelessWidget {
  final PackerSalaryViewModel vm;
  const _EarningsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const _SectionLabel('ANNUAL EARNINGS'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.packer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$year',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.packer)),
          ),
        ]),
        const SizedBox(height: 14),

        // Gross + Take-home gradient banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.packer, AppColors.packer.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: AppColors.packer.withValues(alpha: 0.25),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Take-Home Pay',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(formatCurrency(vm.yearlyNet),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Gross: ${formatCurrency(vm.yearlyGross)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Days worked + Bundles row
        Row(children: [
          Expanded(child: _StatTile(
            icon:  Icons.calendar_today_outlined,
            value: '${vm.yearlyDays} days',
            label: 'Days Worked',
            color: AppColors.packer,
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatTile(
            icon:  Icons.inventory_2_outlined,
            value: '${vm.yearlyBundles}',
            label: 'Total Bundles',
            color: const Color(0xFF1976D2),
          )),
        ]),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
      );
}

// ── How it works card ─────────────────────────────────────────
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel('HOW IT WORKS'),
          const SizedBox(height: 14),
          _InfoRow(
            icon:  Icons.inventory_2_outlined,
            color: AppColors.packer,
            title: 'Record Bundles',
            desc:  'Log each batch of packed bundles after every production run.',
          ),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(
            icon:  Icons.calculate_outlined,
            color: const Color(0xFF1976D2),
            title: 'Salary Formula',
            desc:  'Each bundle is worth ₱4.00. Your gross pay = total bundles × ₱4.',
          ),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(
            icon:  Icons.account_balance_wallet_outlined,
            color: AppColors.success,
            title: 'Weekly Payroll',
            desc:  'Salary is computed every week. Vale deductions are applied to get your take-home pay.',
          ),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   desc;
  const _InfoRow({
    required this.icon, required this.color,
    required this.title, required this.desc,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: AppColors.text)),
            const SizedBox(height: 3),
            Text(desc,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ],
      );
}

// ── Shared ────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint,
          letterSpacing: 0.8));
}
