import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _isOnline = false;
  bool _isAvailable = false;
  String _vehicleType = 'motorcycle';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverId = authProvider.driverId;
    if (driverId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _isOnline = data['isOnline'] ?? false;
        _isAvailable = data['isAvailable'] ?? false;
        _vehicleType = data['vehicleType'] ?? 'motorcycle';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToggleCard(
            title: 'Online Status',
            subtitle: 'Toggle to go online/offline',
            icon: Icons.power_settings_new,
            value: _isOnline,
            onChanged: (value) => _updateSetting('isOnline', value),
          ),
          const SizedBox(height: 16),
          _buildToggleCard(
            title: 'Available for Orders',
            subtitle: 'Toggle to accept/reject orders',
            icon: Icons.check_circle,
            value: _isAvailable,
            onChanged: (value) => _updateSetting('isAvailable', value),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Vehicle Type',
            subtitle: _vehicleType,
            icon: Icons.motorcycle,
            onTap: () => _selectVehicleType(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Schedule Management',
            icon: Icons.calendar_today,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverScheduleScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Vehicle Coverage',
            icon: Icons.map,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleCoverageScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Cash Management',
            icon: Icons.account_balance_wallet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashManagementScreen(),
                ),
              );
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
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _selectVehicleType() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: [
          ListTile(
            title: const Text('Motorcycle'),
            onTap: () => Navigator.pop(context, 'motorcycle'),
          ),
          ListTile(
            title: const Text('Bicycle'),
            onTap: () => Navigator.pop(context, 'bicycle'),
          ),
          ListTile(
            title: const Text('Car'),
            onTap: () => Navigator.pop(context, 'car'),
          ),
          ListTile(
            title: const Text('Scooter'),
            onTap: () => Navigator.pop(context, 'scooter'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _vehicleType = selected;
      });
      await _updateSetting('vehicleType', selected);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverId = authProvider.driverId;
    if (driverId == null) return;

    setState(() {
      if (key == 'isOnline') _isOnline = value;
      if (key == 'isAvailable') _isAvailable = value;
      if (key == 'vehicleType') _vehicleType = value;
    });

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
