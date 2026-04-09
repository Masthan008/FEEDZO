import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({super.key});

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Loyalty Program', subtitle: 'Manage customer loyalty program'),
        Expanded(
          child: Padding(
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
                  value: '3,450',
                  subtitle: 'Enrolled customers',
                ),
                _buildLoyaltyCard(
                  title: 'Points Issued',
                  icon: Icons.stars,
                  color: Colors.orange,
                  value: '125K',
                  subtitle: 'Total points given',
                ),
                _buildLoyaltyCard(
                  title: 'Redeemed',
                  icon: Icons.redeem,
                  color: Colors.green,
                  value: '85K',
                  subtitle: 'Points redeemed',
                ),
                _buildLoyaltyCard(
                  title: 'Reward Claims',
                  icon: Icons.card_giftcard,
                  color: Colors.purple,
                  value: '1,250',
                  subtitle: 'Rewards claimed',
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
