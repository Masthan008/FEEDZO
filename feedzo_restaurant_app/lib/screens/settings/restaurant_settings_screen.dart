import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  bool _isOpen = true;
  bool _autoOpenClose = false;
  bool _acceptingOrders = true;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantId = authProvider.restaurantId;
    if (restaurantId == null) return;

    final doc = await _db.collection('restaurants').doc(restaurantId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _isOpen = data['isOpen'] ?? true;
        _autoOpenClose = data['autoOpenClose'] ?? false;
        _acceptingOrders = data['acceptingOrders'] ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToggleCard(
            title: 'Restaurant is Open',
            subtitle: 'Toggle to open/close your restaurant',
            icon: Icons.store,
            value: _isOpen,
            onChanged: (value) => _updateSetting('isOpen', value),
          ),
          const SizedBox(height: 16),
          _buildToggleCard(
            title: 'Auto Open/Close',
            subtitle: 'Automatically open/close based on schedule',
            icon: Icons.schedule,
            value: _autoOpenClose,
            onChanged: (value) => _updateSetting('autoOpenClose', value),
          ),
          const SizedBox(height: 16),
          _buildToggleCard(
            title: 'Accepting Orders',
            subtitle: 'Toggle to accept/reject new orders',
            icon: Icons.shopping_cart,
            value: _acceptingOrders,
            onChanged: (value) => _updateSetting('acceptingOrders', value),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Business Configuration',
            icon: Icons.business,
            onTap: () {
              // Navigate to business config screen
            },
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Delivery Settings',
            icon: Icons.delivery_dining,
            onTap: () {
              // Navigate to delivery settings screen
            },
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Schedule Management',
            icon: Icons.calendar_today,
            onTap: () {
              // Navigate to schedule screen
            },
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Vehicle Coverage',
            icon: Icons.map,
            onTap: () {
              // Navigate to vehicle coverage screen
            },
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Commission Settings',
            icon: Icons.percent,
            onTap: () {
              // Navigate to commission screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _updateSetting(String key, bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantId = authProvider.restaurantId;
    if (restaurantId == null) return;

    setState(() {
      if (key == 'isOpen') _isOpen = value;
      if (key == 'autoOpenClose') _autoOpenClose = value;
      if (key == 'acceptingOrders') _acceptingOrders = value;
    });

    await _db.collection('restaurants').doc(restaurantId).update({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
