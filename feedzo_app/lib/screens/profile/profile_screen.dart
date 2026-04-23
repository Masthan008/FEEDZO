import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/app_transitions.dart';

import 'address_management_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'loyalty_screen.dart';
import 'privacy_settings_screen.dart';
import 'marketing_preferences_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header with Gradient ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showEditProfile(context, auth),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: AppShape.medium,
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(context, user?.id),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(
                                    user?.avatarUrl != null &&
                                            user!.avatarUrl.isNotEmpty
                                        ? user.avatarUrl
                                        : 'https://i.pravatar.cc/150',
                                  ),
                                  backgroundColor: Colors.white24,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (user?.email != null &&
                                    user!.email.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          user.email,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 2),
                                if (user?.phone != null &&
                                    user!.phone.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        user.phone,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 2),
                                if (user?.dob != null && user!.dob.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.cake_outlined,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        user.dob,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 2),
                                if (user?.gender != null &&
                                    user!.gender.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        user.gender,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Curved overlap
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),

            // ── Saved Addresses ──
            _Section(
              title: 'Saved Addresses',
              icon: Icons.location_on_rounded,
              children: [
                ...(user?.savedAddresses ?? []).map(
                  (addr) => _SettingsItem(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.primary,
                    label: addr.split(' - ')[0],
                    subtitle: addr.split(' - ').length > 1
                        ? addr.split(' - ')[1]
                        : addr,
                    onTap: () {},
                  ),
                ),
                _SettingsItem(
                  icon: Icons.add_location_outlined,
                  iconColor: AppColors.primary,
                  label: 'Add New Address',
                  onTap: () => Navigator.push(
                    context,
                    AppTransitions.fadeSlide(const AddressManagementScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Settings ──
            _Section(
              title: 'Settings',
              icon: Icons.settings_rounded,
              children: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => Navigator.push(
                    context,
                    AppTransitions.fadeSlide(const NotificationsScreen()),
                  ),
                ),
                // Dark mode toggle
                Builder(
                  builder: (ctx) {
                    final theme = ctx.watch<ThemeProvider>();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: AppShape.small,
                            ),
                            child: Icon(
                              theme.isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: theme.isDark,
                            activeColor: AppColors.primary,
                            onChanged: (_) => theme.toggleTheme(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.payment_outlined,
                  label: 'Payment Methods',
                  onTap: () => _showPaymentMethods(context),
                ),
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => Navigator.push(
                    context,
                    AppTransitions.fadeSlide(const HelpSupportScreen()),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => _showPrivacyPolicy(context),
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About BiteGo',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'BiteGo',
                      applicationVersion: '1.0.0',
                      applicationIcon: Image.asset(
                        'assets/logo.png',
                        width: 50,
                      ),
                      children: [
                        const Text(
                          'BiteGo is your smart food delivery companion powered by AI.'
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Account Services (Phase 1 & 2 Features) ──
            _Section(
              title: 'Account Services',
              icon: Icons.account_box_rounded,
              children: [
                _SettingsItem(
                  icon: Icons.star,
                  iconColor: AppColors.warning,
                  label: 'Loyalty Program',
                  subtitle: 'Points, tiers & rewards',
                  onTap: () => Navigator.push(
                    context,
                    AppTransitions.fadeSlide(const LoyaltyScreen()),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip,
                  iconColor: AppColors.primary,
                  label: 'Privacy Settings',
                  subtitle: 'GDPR & data controls',
                  onTap: () => Navigator.push(
                    context,
                    AppTransitions.fadeSlide(const PrivacySettingsScreen()),
                  ),
                ),
      _SettingsItem(
        icon: Icons.notifications_active,
        iconColor: AppColors.primary,
        label: 'Marketing Preferences',
        subtitle: 'Communication controls',
        onTap: () => Navigator.push(
          context,
          AppTransitions.fadeSlide(const MarketingPreferencesScreen()),
        ),
      ),

              ],
            ),
            const SizedBox(height: 12),

            // ── Logout ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppShape.large,
                boxShadow: AppShadows.subtle,
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: AppShape.large),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppShape.small,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await auth.logout();
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Edit Profile Dialog ──
  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final dobCtrl = TextEditingController(text: user.dob);
    final genderCtrl = TextEditingController(text: user.gender);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dobCtrl,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Date of Birth (DD/MM/YYYY)',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: genderCtrl,
              decoration: const InputDecoration(
                labelText: 'Gender (Male / Female / Other)',
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirestoreService.updateUserProfile(user.id, {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'dob': dobCtrl.text.trim(),
                    'gender': genderCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image Picker & Upload ──
  Future<void> _pickAndUploadImage(BuildContext context, String? userId) async {
    if (userId == null) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final url = await CloudinaryService.uploadImage(File(pickedFile.path));

      if (context.mounted) {
        Navigator.pop(context); // close dialog
      }

      if (url != null) {
        await FirestoreService.updateUserProfile(userId, {'avatarUrl': url});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Payment Methods ──
  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _PaymentMethodTile(
              icon: Icons.account_balance_wallet_rounded,
              label: 'UPI Payment',
              subtitle: 'Google Pay, PhonePe, Paytm',
            ),
            _PaymentMethodTile(
              icon: Icons.credit_card_rounded,
              label: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay',
            ),
            _PaymentMethodTile(
              icon: Icons.money_rounded,
              label: 'Cash on Delivery',
              subtitle: 'Pay when you receive',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Privacy Policy ──
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: const [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'At BiteGo, we value your privacy and are committed to protecting your personal data.\n\n'
                '1. Information We Collect\n'
                'We collect information you provide directly: name, email, phone number, delivery addresses, and order history.\n\n'
                '2. How We Use Your Information\n'
                'We use your data to process orders, improve our AI recommendations, send notifications about your orders, and enhance your dining experience.\n\n'
                '3. Data Sharing\n'
                'We share your information with restaurant partners (for order fulfillment) and delivery partners (for delivery). We do not sell your data to third parties.\n\n'
                '4. Data Security\n'
                'We use industry-standard encryption and security measures to protect your data.\n\n'
                '5. Your Rights\n'
                'You can access, modify, or delete your personal data at any time through the app settings.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Widget ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppShape.large,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Settings Item ─────────────────────────────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.textSecondary).withValues(alpha: 0.1),
          borderRadius: AppShape.small,
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatefulWidget {
  final String label;
  final String subtitle;
  final bool value;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
  });

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _value,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        setState(() => _value = v);
      },
      activeThumbColor: AppColors.primary,
      title: Text(
        widget.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        widget.subtitle,
        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary),
      ),
    );
  }
}

// ── Payment Method Tile ───────────────────────────────────────────────────────
class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: AppShape.small,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
    );
  }
}
