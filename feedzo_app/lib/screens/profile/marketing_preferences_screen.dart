import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class MarketingPreferencesScreen extends StatefulWidget {
  const MarketingPreferencesScreen({super.key});

  @override
  State<MarketingPreferencesScreen> createState() =>
      _MarketingPreferencesScreenState();
}

class _MarketingPreferencesScreenState
    extends State<MarketingPreferencesScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  bool _emailSubscribed = true;
  bool _pushSubscribed = true;
  bool _smsSubscribed = false;
  String _promoFrequency = 'weekly';
  List<String> _preferredCategories = [];

  final List<String> _availableCategories = [
    'Indian',
    'Chinese',
    'Italian',
    'Biryani',
    'Pizza',
    'Burger',
    'Thali',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _loadMarketingPreferences();
  }

  Future<void> _loadMarketingPreferences() async {
    if (_uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('marketing_preferences')
        .doc(_uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _emailSubscribed = data['emailSubscribed'] ?? true;
        _pushSubscribed = data['pushSubscribed'] ?? true;
        _smsSubscribed = data['smsSubscribed'] ?? false;
        _promoFrequency = data['promoFrequency'] ?? 'weekly';
        _preferredCategories = List<String>.from(
          data['preferredCategories'] ?? [],
        );
      });
    } else {
      // Create default preferences
      await _saveMarketingPreferences();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveMarketingPreferences() async {
    if (_uid.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('marketing_preferences')
        .doc(_uid)
        .set({
          'emailSubscribed': _emailSubscribed,
          'pushSubscribed': _pushSubscribed,
          'smsSubscribed': _smsSubscribed,
          'promoFrequency': _promoFrequency,
          'preferredCategories': _preferredCategories,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketing Preferences'),
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
                  _buildSectionTitle('Communication Channels'),
                  _buildToggle(
                    title: 'Email Notifications',
                    subtitle: 'Order updates and promotions',
                    value: _emailSubscribed,
                    onChanged: (val) {
                      setState(() => _emailSubscribed = val);
                      _saveMarketingPreferences();
                    },
                  ),
                  _buildToggle(
                    title: 'Push Notifications',
                    subtitle: 'Order status and special offers',
                    value: _pushSubscribed,
                    onChanged: (val) {
                      setState(() => _pushSubscribed = val);
                      _saveMarketingPreferences();
                    },
                  ),
                  _buildToggle(
                    title: 'SMS Messages',
                    subtitle: 'Order confirmations via SMS',
                    value: _smsSubscribed,
                    onChanged: (val) {
                      setState(() => _smsSubscribed = val);
                      _saveMarketingPreferences();
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Promotion Preferences'),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How often do you want to hear from us?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _buildRadioOption('Daily', 'daily'),
                          _buildRadioOption('Weekly', 'weekly'),
                          _buildRadioOption('Monthly', 'monthly'),
                          _buildRadioOption('Never', 'never'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Favorite Food Categories'),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'We\'ll personalize your experience based on your preferences',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableCategories.map((category) {
                              return FilterChip(
                                label: Text(category),
                                selected: _preferredCategories.contains(
                                  category,
                                ),
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                checkmarkColor: AppColors.primary,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _preferredCategories.add(category);
                                    } else {
                                      _preferredCategories.remove(category);
                                    }
                                    _saveMarketingPreferences();
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildRadioOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _promoFrequency,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        if (val != null) {
          setState(() => _promoFrequency = val);
          _saveMarketingPreferences();
        }
      },
    );
  }
}
