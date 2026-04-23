import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ReferralProgramScreen extends StatefulWidget {
  const ReferralProgramScreen({super.key});

  @override
  State<ReferralProgramScreen> createState() => _ReferralProgramScreenState();
}

class _ReferralProgramScreenState extends State<ReferralProgramScreen> {
  final _referrerRewardController = TextEditingController();
  final _refereeRewardController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _expiryDaysController = TextEditingController(text: '30');
  bool _isActive = true;

  @override
  void dispose() {
    _referrerRewardController.dispose();
    _refereeRewardController.dispose();
    _minOrderController.dispose();
    _expiryDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Referral Program',
          subtitle: 'Manage customer referral program',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showSettingsDialog(),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Metrics cards
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data?.docs ?? [];
            
            int totalReferrals = 0;
            int successfulReferrals = 0;
            int pendingReferrals = 0;
            double totalRewards = 0;

            for (var userDoc in users) {
              final data = userDoc.data() as Map<String, dynamic>;
              final referralsMade = (data['referralsMade'] as num?)?.toInt() ?? 0;
              totalReferrals += referralsMade;
              
              final referralStatus = data['referralStatus'] as String? ?? 'pending';
              if (referralStatus == 'completed') {
                successfulReferrals++;
              } else if (referralStatus == 'pending') {
                pendingReferrals++;
              }
              
              totalRewards += (data['referralReward'] as num?)?.toDouble() ?? 0;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 140,
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildReferralCard(
                      title: 'Total Referrals',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      value: totalReferrals.toString(),
                      subtitle: 'Referrals made',
                    ),
                    _buildReferralCard(
                      title: 'Successful Referrals',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      value: successfulReferrals.toString(),
                      subtitle: 'Converted to customers',
                    ),
                    _buildReferralCard(
                      title: 'Pending Referrals',
                      icon: Icons.pending,
                      color: Colors.orange,
                      value: pendingReferrals.toString(),
                      subtitle: 'Awaiting completion',
                    ),
                    _buildReferralCard(
                      title: 'Rewards Given',
                      icon: Icons.card_giftcard,
                      color: Colors.purple,
                      value: '₹${_formatCurrency(totalRewards)}',
                      subtitle: 'Total rewards value',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Referral list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('referrals')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final referrals = snapshot.data?.docs ?? [];

              if (referrals.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No referrals yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Referrer')),
                    DataColumn(label: Text('Referee')),
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Reward')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: referrals.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final referrerReward = (data['referrerReward'] as num?)?.toDouble() ?? 0;
                    final createdAt = data['createdAt'] as Timestamp?;

                    return DataRow(
                      cells: [
                        DataCell(Text(data['referrerName'] ?? 'N/A')),
                        DataCell(Text(data['refereeName'] ?? 'N/A')),
                        DataCell(
                          Text(
                            data['referralCode'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        DataCell(_buildStatusChip(status)),
                        DataCell(Text('₹${referrerReward.toStringAsFixed(0)}')),
                        DataCell(Text(
                          createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) : 'N/A',
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          Row(
                            children: [
                              if (status == 'pending')
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  onPressed: () => _completeReferral(doc),
                                  tooltip: 'Complete',
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () => _deleteReferral(doc.id),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showSettingsDialog() async {
    final settingsDoc = await FirebaseFirestore.instance
        .collection('referralSettings')
        .doc('config')
        .get();
    
    final data = settingsDoc.data() as Map<String, dynamic>? ?? {};
    _referrerRewardController.text = (data['referrerReward'] ?? 50).toString();
    _refereeRewardController.text = (data['refereeReward'] ?? 25).toString();
    _minOrderController.text = (data['minOrderValue'] ?? 200).toString();
    _expiryDaysController.text = (data['expiryDays'] ?? 30).toString();
    _isActive = data['isActive'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Referral Program Settings'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _referrerRewardController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Referrer Reward (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _refereeRewardController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Referee Reward (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Order Value (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expiryDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Referral program is currently active'),
                    value: _isActive,
                    onChanged: (v) => setDialogState(() => _isActive = v),
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
              onPressed: () => _saveSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final referrerReward = double.tryParse(_referrerRewardController.text) ?? 50;
    final refereeReward = double.tryParse(_refereeRewardController.text) ?? 25;
    final minOrderValue = double.tryParse(_minOrderController.text) ?? 200;
    final expiryDays = int.tryParse(_expiryDaysController.text) ?? 30;

    await FirebaseFirestore.instance.collection('referralSettings').doc('config').set({
      'referrerReward': referrerReward,
      'refereeReward': refereeReward,
      'minOrderValue': minOrderValue,
      'expiryDays': expiryDays,
      'isActive': _isActive,
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
  }

  Future<void> _completeReferral(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final referrerId = data['referrerId'] as String?;
    final refereeId = data['refereeId'] as String?;
    final referrerReward = (data['referrerReward'] as num?)?.toDouble() ?? 0;
    final refereeReward = (data['refereeReward'] as num?)?.toDouble() ?? 0;

    // Update referral status
    await doc.reference.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Credit referrer wallet
    if (referrerId != null) {
      await FirebaseFirestore.instance.collection('customerWallets').doc(referrerId).set({
        'balance': FieldValue.increment(referrerReward),
        'totalReferralRewards': FieldValue.increment(referrerReward),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('customerWallets').doc(referrerId)
          .collection('transactions').add({
        'type': 'referral_reward',
        'amount': referrerReward,
        'description': 'Referral reward for referring a new customer',
        'referralId': doc.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Credit referee wallet
    if (refereeId != null) {
      await FirebaseFirestore.instance.collection('customerWallets').doc(refereeId).set({
        'balance': FieldValue.increment(refereeReward),
        'totalReferralRewards': FieldValue.increment(refereeReward),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('customerWallets').doc(refereeId)
          .collection('transactions').add({
        'type': 'referral_bonus',
        'amount': refereeReward,
        'description': 'Referral bonus for signing up with a referral code',
        'referralId': doc.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral completed and rewards distributed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteReferral(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Referral'),
        content: const Text('Are you sure you want to delete this referral?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('referrals').doc(docId).delete();
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildReferralCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'expired':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
