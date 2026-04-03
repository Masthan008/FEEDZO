import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  int _totalPoints = 0;
  String _currentTier = 'Bronze';
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    if (_uid.isEmpty) return;

    // Load loyalty points
    final pointsDoc = await FirebaseFirestore.instance
        .collection('loyalty_points')
        .doc(_uid)
        .get();

    if (pointsDoc.exists) {
      final data = pointsDoc.data()!;
      setState(() {
        _totalPoints = data['totalPoints'] ?? 0;
        _currentTier = data['currentTier'] ?? 'Bronze';
      });
    } else {
      // Create initial loyalty document if doesn't exist
      await FirebaseFirestore.instance
          .collection('loyalty_points')
          .doc(_uid)
          .set({
            'totalPoints': 0,
            'currentTier': 'Bronze',
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
    }

    // Load recent transactions
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('point_transactions')
        .where('userId', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    setState(() {
      _recentTransactions = transactionsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Loyalty Points'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLoyaltyData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTierCard(),
              const SizedBox(height: 24),
              _buildPointsCard(),
              const SizedBox(height: 24),
              _buildRecentTransactions(),
              const SizedBox(height: 24),
              _buildRewardsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppShape.large,
        boxShadow: AppShadows.primaryGlow(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTier.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppShape.round,
                ),
                child: Text(
                  '${_getTierProgress()}% to next tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getTierBenefits(_currentTier),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: AppShape.round,
            child: LinearProgressIndicator(
              value: _getTierProgress() / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Points',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_totalPoints',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPointsMetric('Lifetime', '$_totalPoints'),
              _buildPointsMetric("This Month", '+${_getMonthlyPoints()}'),
              _buildPointsMetric('Expires', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty && !_isLoading)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppShape.large,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No transactions yet\nPlace an order to earn points!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTransactions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final tx = _recentTransactions[index];
              return _buildTransactionItem(tx);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final type = tx['type'] as String? ?? 'earned';
    final amount = tx['amount'] as int? ?? 0;
    final description = tx['description'] as String? ?? '';
    final timestamp = tx['timestamp'] as Timestamp?;
    final formattedDate = timestamp?.toDate().toString().split(' ')[0] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: type == 'earned'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'earned' ? Icons.add : Icons.remove,
              color: type == 'earned' ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            type == 'earned' ? '+$amount' : '-$amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: type == 'earned' ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Rewards',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rewards')
              .where('isActive', isEqualTo: true)
              .orderBy('pointsRequired')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppShape.large,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No rewards available yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            final rewards = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                final data = reward.data() as Map<String, dynamic>;
                final pointsRequired = data['pointsRequired'] as int;
                final isAffordable = _totalPoints >= pointsRequired;
                return _buildRewardItem(data, isAffordable, reward.id);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRewardItem(
    Map<String, dynamic> data,
    bool isAffordable,
    String rewardId,
  ) {
    final name = data['name'] as String;
    final description = data['description'] as String;
    final pointsRequired = data['pointsRequired'] as int;
    final isActive = data['isActive'] as bool? ?? false;

    if (!isActive) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(
          color: isAffordable ? AppColors.primary : AppColors.border,
          width: isAffordable ? 2 : 1,
        ),
        boxShadow: isAffordable
            ? AppShadows.primaryGlow(0.1)
            : AppShadows.subtle,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pointsRequired Points',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAffordable
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: isAffordable
                  ? () => _redeemReward(rewardId, pointsRequired)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAffordable
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                foregroundColor: isAffordable
                    ? Colors.white
                    : AppColors.textHint,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: AppShape.round),
              ),
              child: Text(isAffordable ? 'Redeem' : '$pointsRequired pts'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(String rewardId, int pointsRequired) async {
    try {
      // Call Cloud Function to process redemption
      final response = await Supabase.instance.client.functions.invoke(
        'loyalty-redeem',
        body: {'rewardId': rewardId, 'userId': _uid},
      );

      final data = response.data as Map<String, dynamic>;

      if (response.status == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reward redeemed! ${data['message']}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadLoyaltyData(); // Refresh data
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redemption failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Helper methods
  int _getTierProgress() {
    final points = _totalPoints;
    if (points < 1000) return ((points / 1000) * 100).toInt();
    if (points < 3000) return (((points - 1000) / 2000) * 100).toInt();
    if (points < 10000) return (((points - 3000) / 7000) * 100).toInt();
    return 100;
  }

  String _getTierBenefits(String tier) {
    const benefits = {
      'Bronze': 'Earn 1 point per ₹1 spent',
      'Silver': '5% bonus points on all orders',
      'Gold': '10% bonus points + priority support',
      'Platinum': '15% bonus + free delivery on eligible orders',
    };
    return benefits[tier] ?? 'Keep ordering to earn more points!';
  }

  int _getMonthlyPoints() {
    // This would filter by current month from transactions
    // For demo, returning 10% of total
    return (_totalPoints * 0.1).toInt();
  }
}
