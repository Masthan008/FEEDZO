import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class BusinessModelsScreen extends StatefulWidget {
  const BusinessModelsScreen({super.key});

  @override
  State<BusinessModelsScreen> createState() => _BusinessModelsScreenState();
}

class _BusinessModelsScreenState extends State<BusinessModelsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Business Models', subtitle: 'Manage business model configurations'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildModelCard(
                  title: 'Single Restaurant',
                  icon: Icons.store,
                  color: Colors.blue,
                  description: 'Single restaurant business model',
                  isActive: true,
                ),
                _buildModelCard(
                  title: 'Multi-Restaurant',
                  icon: Icons.store_mall_directory,
                  color: Colors.green,
                  description: 'Multi-restaurant marketplace model',
                  isActive: true,
                ),
                _buildModelCard(
                  title: 'Subscription Model',
                  icon: Icons.card_membership,
                  color: Colors.orange,
                  description: 'Subscription-based business model',
                  isActive: false,
                ),
                _buildModelCard(
                  title: 'Commission Model',
                  icon: Icons.percent,
                  color: Colors.purple,
                  description: 'Commission-based business model',
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelCard({
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
            Switch(
              value: isActive,
              onChanged: (v) {},
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
