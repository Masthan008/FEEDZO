import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Promotions', subtitle: 'Manage promotional campaigns'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildPromoCard(
                  title: 'Active Promotions',
                  icon: Icons.campaign,
                  color: Colors.blue,
                  value: '8',
                  subtitle: 'Currently running',
                ),
                _buildPromoCard(
                  title: 'Coupon Usage',
                  icon: Icons.local_offer,
                  color: Colors.green,
                  value: '2,450',
                  subtitle: 'Coupons used',
                ),
                _buildPromoCard(
                  title: 'Discount Value',
                  icon: Icons.discount,
                  color: Colors.orange,
                  value: '₹45K',
                  subtitle: 'Total discounts',
                ),
                _buildPromoCard(
                  title: 'Conversion Rate',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                  value: '12%',
                  subtitle: 'Promo conversion',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard({
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
