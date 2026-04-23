import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class BusinessModelsScreen extends StatefulWidget {
  const BusinessModelsScreen({super.key});

  @override
  State<BusinessModelsScreen> createState() => _BusinessModelsScreenState();
}

class _BusinessModelsScreenState extends State<BusinessModelsScreen> {
  final _commissionController = TextEditingController();
  final _subscriptionPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commissionController.dispose();
    _subscriptionPriceController.dispose();
    super.dispose();
  }

  Future<void> _updateModelStatus(String modelId, bool isActive) async {
    await FirebaseFirestore.instance.collection('businessConfigs').doc(modelId).set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$modelId ${isActive ? 'enabled' : 'disabled'}'),
          backgroundColor: isActive ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _showConfigDialog(String modelId, String title, Color color) async {
    final configDoc = await FirebaseFirestore.instance.collection('businessConfigs').doc(modelId).get();
    final data = configDoc.data() as Map<String, dynamic>? ?? {};
    
    _commissionController.text = (data['commissionRate'] ?? 10).toString();
    _subscriptionPriceController.text = (data['subscriptionPrice'] ?? 999).toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Configuration'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (modelId == 'commissionModel') ...[
                TextField(
                  controller: _commissionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Commission Rate (%)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (modelId == 'subscriptionModel') ...[
                TextField(
                  controller: _subscriptionPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (modelId == 'singleRestaurant' || modelId == 'multiRestaurant') ...[
                const Text('No additional configuration required'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updateData = <String, dynamic>{
                'updatedAt': FieldValue.serverTimestamp(),
              };
              
              if (modelId == 'commissionModel') {
                updateData['commissionRate'] = double.tryParse(_commissionController.text) ?? 10;
              }
              if (modelId == 'subscriptionModel') {
                updateData['subscriptionPrice'] = double.tryParse(_subscriptionPriceController.text) ?? 999;
              }

              await FirebaseFirestore.instance.collection('businessConfigs').doc(modelId).set(
                updateData,
                SetOptions(merge: true),
              );
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration saved'),
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
        const TopBar(title: 'Business Models', subtitle: 'Manage business model configurations'),
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('platformSettings').doc('businessModels').snapshots(),
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
                    _buildModelCard(
                      modelId: 'singleRestaurant',
                      title: 'Single Restaurant',
                      icon: Icons.store,
                      color: Colors.blue,
                      description: 'Single restaurant business model',
                      isActive: data['singleRestaurant']?['isActive'] ?? true,
                    ),
                    _buildModelCard(
                      modelId: 'multiRestaurant',
                      title: 'Multi-Restaurant',
                      icon: Icons.store_mall_directory,
                      color: Colors.green,
                      description: 'Multi-restaurant marketplace model',
                      isActive: data['multiRestaurant']?['isActive'] ?? true,
                    ),
                    _buildModelCard(
                      modelId: 'subscriptionModel',
                      title: 'Subscription Model',
                      icon: Icons.card_membership,
                      color: Colors.orange,
                      description: 'Subscription-based business model',
                      isActive: data['subscriptionModel']?['isActive'] ?? false,
                    ),
                    _buildModelCard(
                      modelId: 'commissionModel',
                      title: 'Commission Model',
                      icon: Icons.percent,
                      color: Colors.purple,
                      description: 'Commission-based business model',
                      isActive: data['commissionModel']?['isActive'] ?? true,
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

  Widget _buildModelCard({
    required String modelId,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required bool isActive,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                if (isActive)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
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
                    onPressed: () => _showConfigDialog(modelId, title, color),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Configure'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: isActive,
                  onChanged: (v) => _updateModelStatus(modelId, v),
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
