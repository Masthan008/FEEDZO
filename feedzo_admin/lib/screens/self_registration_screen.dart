import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SelfRegistrationScreen extends StatefulWidget {
  const SelfRegistrationScreen({super.key});

  @override
  State<SelfRegistrationScreen> createState() => _SelfRegistrationScreenState();
}

class _SelfRegistrationScreenState extends State<SelfRegistrationScreen> {
  final _driverApprovalController = TextEditingController(text: 'true');
  final _restaurantApprovalController = TextEditingController(text: 'true');
  final _driverRequiredDocsController = TextEditingController();
  final _restaurantRequiredDocsController = TextEditingController();

  @override
  void dispose() {
    _driverApprovalController.dispose();
    _restaurantApprovalController.dispose();
    _driverRequiredDocsController.dispose();
    _restaurantRequiredDocsController.dispose();
    super.dispose();
  }

  Future<void> _updateRegistrationSetting(String type, bool isEnabled) async {
    await FirebaseFirestore.instance.collection('selfRegistrationSettings').doc('config').set({
      '${type}SelfReg': isEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.capitalize()} self-registration ${isEnabled ? 'enabled' : 'disabled'}'),
          backgroundColor: isEnabled ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _showAdvancedSettings(String type, Color color) async {
    final settingsDoc = await FirebaseFirestore.instance
        .collection('selfRegistrationSettings')
        .doc('config')
        .get();
    final data = settingsDoc.data() as Map<String, dynamic>? ?? {};

    final prefix = type == 'driver' ? 'driver' : 'restaurant';
    _driverApprovalController.text = data['${prefix}RequiresApproval']?.toString() ?? 'true';
    _driverRequiredDocsController.text = (data['${prefix}RequiredDocs'] as List<dynamic>?)?.join(', ') ?? '';

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type.capitalize()} Registration Settings'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Requires Admin Approval'),
                  subtitle: const Text('New registrations must be approved by admin'),
                  value: data['${prefix}RequiresApproval'] ?? true,
                  onChanged: (v) {},
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: type == 'driver' ? _driverRequiredDocsController : _restaurantRequiredDocsController,
                  decoration: const InputDecoration(
                    labelText: 'Required Documents (comma separated)',
                    hintText: 'License, Insurance, ID Proof',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Minimum Age',
                    border: const OutlineInputBorder(),
                    suffixText: type == 'driver' ? (data['driverMinAge']?.toString() ?? '18') : (data['restaurantMinAge']?.toString() ?? '18'),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final docsText = type == 'driver' 
                  ? _driverRequiredDocsController.text 
                  : _restaurantRequiredDocsController.text;
              final docs = docsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

              await FirebaseFirestore.instance.collection('selfRegistrationSettings').doc('config').set({
                '${prefix}RequiredDocs': docs,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Self-Registration', subtitle: 'Manage self-registration settings'),
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('selfRegistrationSettings').doc('config').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: [
                    _buildRegCard(
                      title: 'Driver Self-Registration',
                      icon: Icons.delivery_dining,
                      color: Colors.blue,
                      description: 'Allow drivers to register themselves',
                      isEnabled: data['driverSelfReg'] ?? false,
                      onToggle: (v) => _updateRegistrationSetting('driver', v),
                      onAdvanced: () => _showAdvancedSettings('driver', Colors.blue),
                    ),
                    _buildRegCard(
                      title: 'Restaurant Self-Registration',
                      icon: Icons.restaurant,
                      color: Colors.orange,
                      description: 'Allow restaurants to register themselves',
                      isEnabled: data['restaurantSelfReg'] ?? false,
                      onToggle: (v) => _updateRegistrationSetting('restaurant', v),
                      onAdvanced: () => _showAdvancedSettings('restaurant', Colors.orange),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onAdvanced,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAdvanced,
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
