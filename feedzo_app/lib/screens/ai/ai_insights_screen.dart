import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_insights_service.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, dynamic> _spendingInsights = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    final insights = await AIInsightsService.getCustomerInsights();
    final recommendations = await AIInsightsService.getFoodRecommendations();
    final spendingInsights = await AIInsightsService.getSpendingInsights();

    if (mounted) {
      setState(() {
        _insights = insights;
        _recommendations = recommendations;
        _spendingInsights = spendingInsights;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('AI Insights'),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('AI Insights'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryBanner(),
            const SizedBox(height: 24),
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            const Text(
              'Personalized Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecommendations(),
            const SizedBox(height: 24),
            const Text(
              'Spending Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpendingInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    final totalOrders = _insights['totalOrders'] ?? 0;
    final favoriteCuisine = _insights['favoriteCuisine'] ?? 'Indian';
    final loyaltyTier = _insights['loyaltyTier'] ?? 'Bronze';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Summary',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve placed $totalOrders orders and your favorite cuisine is $favoriteCuisine. You\'re a $loyaltyTier member!',
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBadge(label: 'Orders', value: '$totalOrders', positive: true),
              const SizedBox(width: 12),
              _StatBadge(label: 'Tier', value: loyaltyTier, positive: true),
              const SizedBox(width: 12),
              _StatBadge(label: 'Cuisine', value: favoriteCuisine, positive: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalSpent = _insights['totalSpent'] ?? 0.0;
    final avgOrderValue = _insights['avgOrderValue'] ?? 0.0;
    final loyaltyPoints = _insights['loyaltyPoints'] ?? 0;

    return Column(
      children: [
        _StatCard(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Total Spent',
          value: '₹${totalSpent.toStringAsFixed(0)}',
          color: 0xFF16A34A,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.receipt_long_rounded,
          label: 'Avg Order Value',
          value: '₹${avgOrderValue.toStringAsFixed(0)}',
          color: 0xFF3B82F6,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.stars_rounded,
          label: 'Loyalty Points',
          value: '$loyaltyPoints pts',
          color: 0xFFF59E0B,
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Text('Order more to get personalized recommendations!'),
      );
    }

    return Column(
      children: _recommendations
          .map(
            (rec) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    rec['icon'] as IconData,
                    size: 28,
                    color: Color(rec['color'] as int),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['reason'] as String,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSpendingInsights() {
    final recentSpent = _spendingInsights['recentSpent'] ?? 0.0;
    final spendingChange = _spendingInsights['spendingChange'] ?? 0.0;
    final isPositive = spendingChange >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 30 Days',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${recentSpent.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                "${spendingChange.abs().toStringAsFixed(1)}% ${isPositive ? 'more' : 'less'} than previous 30 days",
                style: TextStyle(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Color(color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: positive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
