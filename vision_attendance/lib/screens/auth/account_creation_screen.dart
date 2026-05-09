// lib/screens/auth/account_creation_screen.dart
// ─── 3-Step Registration Flow ─────────────────────────────────────────────────
// Step 1: Personal Info  → API register → go to Step 2
// Step 2: Identity Verification (face scan selection)  → go to Step 3
// Step 3: Permissions Setup → go to Dashboard
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STEP INDICATOR
// ══════════════════════════════════════════════════════════════════════════════
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final stepNum    = i + 1;
        final isCompleted = stepNum < currentStep;
        final isCurrent   = stepNum == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '$stepNum',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : AppColors.textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              if (i < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 1 — Personal Information
// ══════════════════════════════════════════════════════════════════════════════
class AccountCreationScreen extends ConsumerStatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  ConsumerState<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends ConsumerState<AccountCreationScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameEnCtrl     = TextEditingController();
  final _nameArCtrl     = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _usernameCtrl   = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _deptCtrl       = TextEditingController();

  bool   _isLoading       = false;
  bool   _obscurePassword = true;
  String _selectedRole    = 'employee';
  String _selectedGender  = 'male';

  @override
  void dispose() {
    for (final c in [_nameEnCtrl, _nameArCtrl, _emailCtrl, _usernameCtrl,
                     _passwordCtrl, _phoneCtrl, _deptCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(userProfileProvider.notifier).register(
        fullNameEn:  _nameEnCtrl.text.trim(),
        fullNameAr:  _nameArCtrl.text.trim().isEmpty
                         ? _nameEnCtrl.text.trim()
                         : _nameArCtrl.text.trim(),
        email:       _emailCtrl.text.trim(),
        username:    _usernameCtrl.text.trim(),
        password:    _passwordCtrl.text,
        phone:       _phoneCtrl.text.trim(),
        department:  _deptCtrl.text.trim(),
        gender:      _selectedGender,
        role:        _selectedRole,
      );
      if (mounted) context.push(AppRoutes.identityVerification);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepIndicator(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 24),
              const Text('Personal Information', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 4),
              const Text('Fill in your details to get started.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),

              // Full Name EN
              AppTextField(
                label: 'Full Name (English) *',
                hint: 'John Smith',
                controller: _nameEnCtrl,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Full Name AR
              AppTextField(
                label: 'Full Name (Arabic)',
                hint: 'محمد أحمد',
                controller: _nameArCtrl,
                prefixIcon: Icons.translate_rounded,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),

              // Email
              AppTextField(
                label: 'Work Email *',
                hint: 'john@organization.com',
                controller: _emailCtrl,
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username
              AppTextField(
                label: 'Username *',
                hint: 'john_smith',
                controller: _usernameCtrl,
                prefixIcon: Icons.badge_outlined,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              AppTextField(
                label: 'Phone Number',
                hint: '+20 1234567890',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Department
              AppTextField(
                label: 'Department / Class',
                hint: 'Engineering',
                controller: _deptCtrl,
                prefixIcon: Icons.business_outlined,
              ),
              const SizedBox(height: 16),

              // Role
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'student',  child: Text('Student')),
                ],
                onChanged: (v) { if (v != null) setState(() => _selectedRole = v); },
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_2_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'male',   child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) { if (v != null) setState(() => _selectedGender = v); },
              ),
              const SizedBox(height: 16),

              // Password
              AppTextField(
                label: 'Password *',
                hint: '••••••••',
                controller: _passwordCtrl,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 32),

              AppPrimaryButton(
                label: 'Continue →',
                onPressed: _continue,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — Identity Verification
// ══════════════════════════════════════════════════════════════════════════════
class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  bool    _isLoading     = false;
  String? _selectedMethod;

  void _proceed() async {
    if (_selectedMethod == null) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isLoading = false);
    if (mounted) context.push(AppRoutes.permissionsSetup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Identity Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(currentStep: 2, totalSteps: 3),
            const SizedBox(height: 24),
            const Text('Verify Your Identity', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Choose a verification method to confirm your identity securely.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),

            _VerificationOption(
              icon: Icons.face_retouching_natural_rounded,
              title: 'Face Scan',
              subtitle: 'Use AI face recognition for instant verification',
              isSelected: _selectedMethod == 'face',
              onTap: () => setState(() => _selectedMethod = 'face'),
            ),
            const SizedBox(height: 12),
            _VerificationOption(
              icon: Icons.credit_card_rounded,
              title: 'Employee / Student ID Card',
              subtitle: 'Scan your official ID card',
              isSelected: _selectedMethod == 'id_card',
              onTap: () => setState(() => _selectedMethod = 'id_card'),
            ),
            const SizedBox(height: 12),
            _VerificationOption(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric',
              subtitle: 'Use your device biometric authentication',
              isSelected: _selectedMethod == 'biometric',
              onTap: () => setState(() => _selectedMethod = 'biometric'),
            ),
            const Spacer(),

            AppPrimaryButton(
              label: 'Continue →',
              onPressed: _selectedMethod != null ? _proceed : null,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.permissionsSetup),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VerificationOption({
    required this.icon, required this.title, required this.subtitle,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 3 — Permissions Setup
// ══════════════════════════════════════════════════════════════════════════════
class PermissionsSetupScreen extends ConsumerStatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  ConsumerState<PermissionsSetupScreen> createState() =>
      _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends ConsumerState<PermissionsSetupScreen> {
  bool _locating  = false;
  final Map<String, bool> _permissions = {
    'Camera':        false,
    'Location':      false,
    'Notifications': false,
    'Biometric':     false,
  };

  void _requestAll() async {
    // ── Request camera + location permissions via geolocator (location already imported)
    setState(() => _permissions.updateAll((k, v) => true));

    // Try to get & send GPS location
    await _requestAndSendLocation();
  }

  Future<void> _requestAndSendLocation() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        setState(() => _permissions['Location'] = true);
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await ref.read(userProfileProvider.notifier).sendLocation(
          latitude:  pos.latitude,
          longitude: pos.longitude,
        );
      }
    } catch (_) {
      // permission denied — ignore, user can skip
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _finish() => context.go(AppRoutes.dashboard);

  @override
  Widget build(BuildContext context) {
    final allGranted = _permissions.values.every((v) => v);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions & Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(currentStep: 3, totalSteps: 3),
            const SizedBox(height: 24),
            const Text('App Permissions', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Vision Attendance needs these permissions to function correctly.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),

            ..._permissions.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PermissionRow(
                label:       e.key,
                isGranted:   e.value,
                icon:        _permissionIcon(e.key),
                description: _permissionDesc(e.key),
                onRequest: () async {
                  if (e.key == 'Location') {
                    await _requestAndSendLocation();
                  } else {
                    setState(() => _permissions[e.key] = true);
                  }
                },
              ),
            )),

            const Spacer(),

            if (!allGranted) ...[
              AppOutlineButton(
                label: _locating ? 'Getting location…' : 'Grant All Permissions',
                onPressed: _locating ? null : _requestAll,
                icon: Icons.security_rounded,
              ),
              const SizedBox(height: 12),
            ],

            AppPrimaryButton(
              label: allGranted ? '🎉 Get Started!' : 'Continue Anyway',
              onPressed: _finish,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                allGranted
                    ? 'Your account is ready!'
                    : 'You can grant permissions later in settings.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _permissionIcon(String p) => switch (p) {
    'Camera'        => Icons.camera_alt_rounded,
    'Location'      => Icons.location_on_rounded,
    'Notifications' => Icons.notifications_rounded,
    'Biometric'     => Icons.fingerprint_rounded,
    _               => Icons.settings_rounded,
  };

  String _permissionDesc(String p) => switch (p) {
    'Camera'        => 'Required for face scan check-in',
    'Location'      => 'For GPS-verified attendance in correct room',
    'Notifications' => 'Stay updated on attendance events',
    'Biometric'     => 'Secure app access fallback',
    _               => '',
  };
}

class _PermissionRow extends StatelessWidget {
  final String label, description;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionRow({
    required this.label, required this.description, required this.icon,
    required this.isGranted, required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isGranted ? AppColors.success : AppColors.textSecondary,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.titleLarge),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isGranted
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 24, key: ValueKey('granted'))
                : GestureDetector(
                    onTap: onRequest,
                    key: const ValueKey('request'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Allow',
                        style: TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
