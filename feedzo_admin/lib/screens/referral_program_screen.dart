import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ReferralProgramScreen extends StatefulWidget {
  const ReferralProgramScreen({super.key});

  @override
  State<ReferralProgramScreen> createState() => _ReferralProgramScreenState();
}

class _ReferralProgramScreenState extends State<ReferralProgramScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Referral Program', subtitle: 'Manage customer referral program'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildReferralCard(
                  title: 'Total Referrals',
                  icon: Icons.people_outline,
                  color: Colors.blue,
                  value: '1,250',
                  subtitle: 'Referrals made',
                ),
                _buildReferralCard(
                  title: 'Successful Referrals',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  value: '845',
                  subtitle: 'Converted to customers',
                ),
                _buildReferralCard(
                  title: 'Pending Referrals',
                  icon: Icons.pending,
                  color: Colors.orange,
                  value: '405',
                  subtitle: 'Awaiting completion',
                ),
                _buildReferralCard(
                  title: 'Rewards Given',
                  icon: Icons.card_giftcard,
                  color: Colors.purple,
                  value: '₹25K',
                  subtitle: 'Total rewards value',
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
