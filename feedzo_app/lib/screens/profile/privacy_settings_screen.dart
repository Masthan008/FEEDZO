import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  bool _dataSharing = true;
  bool _analytics = true;
  bool _marketingEmails = false;
  bool _pushNotifications = true;
  bool _locationTracking = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    if (_uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('privacy_settings')
        .doc(_uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _dataSharing = data['dataSharing'] ?? true;
        _analytics = data['analytics'] ?? true;
        _marketingEmails = data['marketingEmails'] ?? false;
        _pushNotifications = data['pushNotifications'] ?? true;
        _locationTracking = data['locationTracking'] ?? true;
      });
    } else {
      // Create default settings
      await _savePrivacySettings();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _savePrivacySettings() async {
    if (_uid.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('privacy_settings')
        .doc(_uid)
        .set({
          'dataSharing': _dataSharing,
          'analytics': _analytics,
          'marketingEmails': _marketingEmails,
          'pushNotifications': _pushNotifications,
          'locationTracking': _locationTracking,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Data Collection'),
                  _buildToggle(
                    title: 'Share Data with Partners',
                    subtitle: 'Help improve our services',
                    value: _dataSharing,
                    onChanged: (val) {
                      setState(() => _dataSharing = val);
                      _savePrivacySettings();
                    },
                  ),
                  _buildToggle(
                    title: 'Analytics',
                    subtitle: 'Usage analytics to improve app',
                    value: _analytics,
                    onChanged: (val) {
                      setState(() => _analytics = val);
                      _savePrivacySettings();
                    },
                  ),
                  _buildToggle(
                    title: 'Location Tracking',
                    subtitle: 'Required for delivery services',
                    value: _locationTracking,
                    onChanged: (val) {
                      setState(() => _locationTracking = val);
                      _savePrivacySettings();
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Communication'),
                  _buildToggle(
                    title: 'Marketing Emails',
                    subtitle: 'Promotions and special offers',
                    value: _marketingEmails,
                    onChanged: (val) {
                      setState(() => _marketingEmails = val);
                      _savePrivacySettings();
                    },
                  ),
                  _buildToggle(
                    title: 'Push Notifications',
                    subtitle: 'Order updates and alerts',
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                      _savePrivacySettings();
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Data Rights'),
                  const Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GDPR Compliance',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You have the right to access, delete, or export your data at any time.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Download My Data',
                    onPressed: () => _downloadMyData(),
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Delete My Account',
                    onPressed: () => _confirmDeleteAccount(context),
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _downloadMyData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data export requested. You will receive an email shortly.',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implementation for account deletion would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion initiated.')),
      );
    }
  }
}
