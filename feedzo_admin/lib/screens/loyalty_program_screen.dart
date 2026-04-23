import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({super.key});

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Loyalty Program', subtitle: 'Manage customer loyalty program'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _buildTabButton('Overview', 0),
              const SizedBox(width: 8),
              _buildTabButton('Customers', 1),
              const SizedBox(width: 8),
              _buildTabButton('Settings', 2),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == 0
              ? _buildOverview()
              : _selectedTab == 1
                  ? _buildCustomersList()
                  : _buildSettings(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = index),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
        foregroundColor: isSelected ? Colors.white : AppColors.textSecondary,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];
        
        // Calculate loyalty metrics from users data
        int activeMembers = 0;
        int totalPointsIssued = 0;
        int pointsRedeemed = 0;
        int rewardClaims = 0;

        for (var userDoc in users) {
          final data = userDoc.data() as Map<String, dynamic>;
          // Count active members (customers with loyalty points > 0)
          final loyaltyPoints = (data['loyaltyPoints'] as num?)?.toInt() ?? 0;
          if (loyaltyPoints > 0) {
            activeMembers++;
          }
          totalPointsIssued += loyaltyPoints;
          pointsRedeemed += (data['pointsRedeemed'] as num?)?.toInt() ?? 0;
          rewardClaims += (data['rewardClaims'] as num?)?.toInt() ?? 0;
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            children: [
              _buildLoyaltyCard(
                title: 'Active Members',
                icon: Icons.card_membership,
                color: Colors.blue,
                value: activeMembers.toString(),
                subtitle: 'Enrolled customers',
              ),
              _buildLoyaltyCard(
                title: 'Points Issued',
                icon: Icons.stars,
                color: Colors.orange,
                value: _formatNumber(totalPointsIssued),
                subtitle: 'Total points given',
              ),
              _buildLoyaltyCard(
                title: 'Redeemed',
                icon: Icons.redeem,
                color: Colors.green,
                value: _formatNumber(pointsRedeemed),
                subtitle: 'Points redeemed',
              ),
              _buildLoyaltyCard(
                title: 'Reward Claims',
                icon: Icons.card_giftcard,
                color: Colors.purple,
                value: rewardClaims.toString(),
                subtitle: 'Rewards claimed',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('loyalty_points')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final customers = snapshot.data?.docs ?? [];

        if (customers.isEmpty) {
          return const Center(child: Text('No loyalty members yet'));
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final data = customers[index].data() as Map<String, dynamic>;
                final customerId = customers[index].id;
                final points = (data['points'] as num?)?.toInt() ?? 0;
                final tier = data['tier'] as String? ?? 'Bronze';

                return ListTile(
                  title: Text(data['customerName'] ?? 'Customer #$customerId'),
                  subtitle: Text('Tier: $tier • Points: $points'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _adjustPoints(customerId, points, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _adjustPoints(customerId, points, false),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('loyaltySettings').doc('config').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final pointsPerRupee = (data['pointsPerRupee'] as num?)?.toDouble() ?? 1.0;
        final rupeePerPoint = (data['rupeePerPoint'] as num?)?.toDouble() ?? 0.1;
        final bronzeThreshold = (data['bronzeThreshold'] as num?)?.toInt() ?? 0;
        final silverThreshold = (data['silverThreshold'] as num?)?.toInt() ?? 500;
        final goldThreshold = (data['goldThreshold'] as num?)?.toInt() ?? 2000;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Point Conversion Rates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    'Points per ₹1 spent',
                    pointsPerRupee.toString(),
                    () => _editSetting('pointsPerRupee', pointsPerRupee),
                  ),
                  _buildSettingRow(
                    '₹ value per 1 point',
                    rupeePerPoint.toString(),
                    () => _editSetting('rupeePerPoint', rupeePerPoint),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tier Thresholds',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    'Bronze Tier (min points)',
                    bronzeThreshold.toString(),
                    () => _editSetting('bronzeThreshold', bronzeThreshold.toDouble()),
                  ),
                  _buildSettingRow(
                    'Silver Tier (min points)',
                    silverThreshold.toString(),
                    () => _editSetting('silverThreshold', silverThreshold.toDouble()),
                  ),
                  _buildSettingRow(
                    'Gold Tier (min points)',
                    goldThreshold.toString(),
                    () => _editSetting('goldThreshold', goldThreshold.toDouble()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustPoints(String customerId, int currentPoints, bool isAdd) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'Add Points' : 'Deduct Points'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isAdd ? 'Points to add' : 'Points to deduct',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (amount != null) {
      final newPoints = isAdd ? currentPoints + amount : currentPoints - amount;
      await FirebaseFirestore.instance
          .collection('loyalty_points')
          .doc(customerId)
          .update({'points': newPoints < 0 ? 0 : newPoints});
    }
  }

  Future<void> _editSetting(String key, double currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());
    final newValue = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null) {
      await FirebaseFirestore.instance
          .collection('loyaltySettings')
          .doc('config')
          .set({key: newValue}, SetOptions(merge: true));
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  Widget _buildLoyaltyCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
