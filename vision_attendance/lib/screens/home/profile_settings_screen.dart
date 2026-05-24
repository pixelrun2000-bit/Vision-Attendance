// lib/screens/home/profile_settings_screen.dart
// ─── Premium Profile Page ─────────────────────────────────────────────────────
// Modern card-based design with:
//   • Gradient hero header with avatar, name, role badge
//   • Real attendance stats from API (present / late / total)
//   • Inline editable fields (tap pencil to edit)
//   • Security settings with nice toggles
//   • Clean section cards (not flat bottom-border tiles)
//   • Animated sign-out button
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';
import '../../state/theme_state.dart';
import '../../services/api_service.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {

  // ── toggles ─────────────────────────────────────────────────────────────────
  bool _faceIdEnabled    = true;
  bool _notificationsEnabled = true;
  bool _locationEnabled  = true;

  // ── edit mode ───────────────────────────────────────────────────────────────
  bool _editMode = false;
  bool _saving   = false;
  bool _loggingOut = false;
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _phoneCtrl;

  // ── stats from API ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _summary;
  bool _statsLoading = true;

  // ── animation ────────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ApiService — built with token after first frame
  late ApiService _api;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).user;
    _nameArCtrl = TextEditingController(text: profile?.fullNameAr ?? '');
    _nameEnCtrl = TextEditingController(text: profile?.fullNameEn ?? '');
    _phoneCtrl  = TextEditingController(text: profile?.phoneE164  ?? '');

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Build ApiService with real token after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tok = ref.read(userProfileProvider).user?.token ?? '';
      _api = ApiService(token: tok);
      _loadStats();
      _sendGps();
    });
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── data ─────────────────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    try {
      final res = await _api.getMyLogs();
      if (mounted) setState(() { _summary = res['summary']; _statsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _sendGps() async {
    if (!_locationEnabled) return;
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      await ref.read(userProfileProvider.notifier).sendLocation(
        latitude: pos.latitude, longitude: pos.longitude,
      );
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
        fullNameAr: _nameArCtrl.text.trim(),
        fullNameEn: _nameEnCtrl.text.trim(),
        phone:      _phoneCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _editMode = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickPhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Take a photo', style: AppTextStyles.titleLarge),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose from gallery', style: AppTextStyles.titleLarge),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 75);
    if (file == null) return;
    
    await ref.read(userProfileProvider.notifier).uploadProfileImage(file.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile photo updated'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final profile   = ref.watch(userProfileProvider).user;
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final name      = profile?.fullNameEn ?? 'Your Name';
    final role      = profile?.role ?? 'employee';
    final username  = profile?.username ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [

            // ══════════════════════════════════════════════
            // HERO HEADER
            // ══════════════════════════════════════════════
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
              actions: [
                IconButton(
                  icon: Icon(_editMode ? Icons.close_rounded : Icons.edit_rounded,
                      color: Colors.white),
                  onPressed: () => setState(() => _editMode = !_editMode),
                  tooltip: _editMode ? 'Cancel edit' : 'Edit profile',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),

                        // ── Avatar ─────────────────────────────────────────
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ]),
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                                ),
                                child: ClipOval(
                                  child: (profile?.photoUrl != null && profile?.photoUrl != '')
                                      ? Image.network(profile?.photoUrl ?? '', fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _avatarFallback(name))
                                      : _avatarFallback(name),
                                ),
                              ),
                              Positioned(
                                bottom: 2, right: 2,
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      color: AppColors.primary, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Name ───────────────────────────────────────────
                        Text(name, style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
                        )),
                        const SizedBox(height: 4),
                        if (username.isNotEmpty)
                          Text('@$username', style: const TextStyle(
                            color: Colors.white70, fontSize: 13,
                          )),
                        const SizedBox(height: 8),

                        // ── Role badge ─────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ══════════════════════════════════════════════
                  // ATTENDANCE STATS CARDS
                  // ══════════════════════════════════════════════
                  _statsLoading
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                      : Row(children: [
                          _StatCard(
                            label: 'Present',
                            value: '${_summary?['present'] ?? 0}',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Late',
                            value: '${_summary?['late'] ?? 0}',
                            icon: Icons.access_time_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Sessions',
                            value: '${_summary?['total_days'] ?? 0}',
                            icon: Icons.calendar_today_rounded,
                            color: AppColors.primary,
                          ),
                        ]),
                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════
                  // PERSONAL INFORMATION CARD
                  // ══════════════════════════════════════════════
                  _SectionCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    trailing: _editMode
                        ? TextButton.icon(
                            onPressed: _saving ? null : _saveProfile,
                            icon: _saving
                                ? const SizedBox(width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_rounded, size: 16),
                            label: Text(_saving ? 'Saving…' : 'Save'),
                          )
                        : null,
                    children: _editMode
                        ? [
                            _EditField(label: 'Full Name (EN)', ctrl: _nameEnCtrl,
                                icon: Icons.person_rounded),
                            const SizedBox(height: 12),
                            _EditField(label: 'Full Name (AR)', ctrl: _nameArCtrl,
                                icon: Icons.translate_rounded, rtl: true),
                            const SizedBox(height: 12),
                            _EditField(label: 'Phone', ctrl: _phoneCtrl,
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone),
                          ]
                        : [
                            _InfoRow(icon: Icons.person_rounded,        label: 'Name (EN)',   value: profile?.fullNameEn ?? '—'),
                            _InfoRow(icon: Icons.translate_rounded,     label: 'Name (AR)',   value: profile?.fullNameAr ?? '—'),
                            _InfoRow(icon: Icons.alternate_email_rounded,label: 'Username',   value: '@${profile?.username ?? '—'}'),
                            _InfoRow(icon: Icons.phone_rounded,          label: 'Phone',      value: profile?.phoneE164 ?? '—'),
                            _InfoRow(icon: Icons.wc_rounded,             label: 'Gender',
                                value: profile?.gender == Gender.female ? 'Female' : 'Male'),
                            _InfoRow(icon: Icons.credit_card_rounded,    label: 'National ID',value: profile?.nationalId ?? '—'),
                          ],
                  ),
                  const SizedBox(height: 16),

                  // ══════════════════════════════════════════════
                  // FACE & BIOMETRICS CARD
                  // ══════════════════════════════════════════════
                  _SectionCard(
                    title: 'Face & Biometrics',
                    icon: Icons.face_retouching_natural_rounded,
                    children: [
                      _ToggleRow(
                        icon: Icons.face_retouching_natural_rounded,
                        label: 'Face ID Check-In',
                        subtitle: 'AI face recognition for attendance',
                        value: _faceIdEnabled,
                        onChanged: (v) => setState(() => _faceIdEnabled = v),
                      ),
                      const Divider(height: 1, indent: 52),
                      _TileRow(
                        icon: Icons.refresh_rounded,
                        label: 'Re-enroll Face',
                        subtitle: 'Update your biometric profile',
                        onTap: () => context.push(AppRoutes.identityVerification),
                      ),
                      const Divider(height: 1, indent: 52),
                      _TileRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Biometric Backup',
                        subtitle: 'Configure backup authentication',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ══════════════════════════════════════════════
                  // APP SETTINGS CARD
                  // ══════════════════════════════════════════════
                  _SectionCard(
                    title: 'App Settings',
                    icon: Icons.settings_rounded,
                    children: [
                      _ToggleRow(
                        icon: Icons.notifications_rounded,
                        label: 'Push Notifications',
                        subtitle: 'Attendance reminders and alerts',
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                      ),
                      const Divider(height: 1, indent: 52),
                      _ToggleRow(
                        icon: Icons.location_on_rounded,
                        label: 'Location Services',
                        subtitle: 'Required for room GPS verification',
                        value: _locationEnabled,
                        onChanged: (v) => setState(() => _locationEnabled = v),
                      ),
                      const Divider(height: 1, indent: 52),
                      _ToggleRow(
                        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        label: 'Dark Mode',
                        subtitle: 'Switch app appearance',
                        value: isDark,
                        onChanged: (v) =>
                            ref.read(themeModeProvider.notifier).setDarkMode(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ══════════════════════════════════════════════
                  // SUPPORT CARD
                  // ══════════════════════════════════════════════
                  _SectionCard(
                    title: 'Support',
                    icon: Icons.help_outline_rounded,
                    children: [
                      _TileRow(icon: Icons.help_outline_rounded,  label: 'Help Center',
                          subtitle: 'FAQs and user guides',         onTap: () {}),
                      const Divider(height: 1, indent: 52),
                      _TileRow(icon: Icons.bug_report_outlined,   label: 'Report an Issue',
                          subtitle: 'Send feedback to our team',    onTap: () {}),
                      const Divider(height: 1, indent: 52),
                      _TileRow(icon: Icons.privacy_tip_outlined,  label: 'Privacy Policy',
                          subtitle: 'How we handle your data',      onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════
                  // SIGN OUT BUTTON
                  // ══════════════════════════════════════════════
                  _SignOutButton(onTap: _performSignOut),
                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Vision Attendance v1.0.0',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _avatarFallback(String name) => Container(
    color: AppColors.primary.withOpacity(0.3),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Future<void> _performSignOut() async {
    setState(() => _loggingOut = true);
    try {
      // Clear state and storage
      await ref.read(userProfileProvider.notifier).signOut();
      
      // Force navigate to login immediately
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    // Deprecated in favor of direct logout
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: color,
          )),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.icon,
      required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 17),
                ),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700)),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
              const SizedBox(height: 1),
              Text(value, style: AppTextStyles.titleLarge),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final bool rtl;
  final TextInputType keyboardType;

  const _EditField({
    required this.label, required this.ctrl, required this.icon,
    this.rtl = false, this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.label,
      required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: value ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: value ? AppColors.primary : AppColors.textSecondary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.titleLarge),
            Text(subtitle, style: AppTextStyles.bodyMedium),
          ])),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  const _TileRow({required this.icon, required this.label,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.titleLarge),
              Text(subtitle, style: AppTextStyles.bodyMedium),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.4)),
          color: AppColors.error.withOpacity(0.05),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Text('Sign Out', style: TextStyle(
            color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15,
          )),
        ]),
      ),
    );
  }
}
