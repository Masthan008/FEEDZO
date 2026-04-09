import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Inventory Management', subtitle: 'Manage restaurant inventory'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildInventoryCard(
                  title: 'Food Items',
                  icon: Icons.restaurant_menu,
                  color: Colors.blue,
                  value: '1,250',
                  subtitle: 'Total items tracked',
                ),
                _buildInventoryCard(
                  title: 'Low Stock',
                  icon: Icons.warning,
                  color: Colors.orange,
                  value: '23',
                  subtitle: 'Items need reorder',
                ),
                _buildInventoryCard(
                  title: 'Out of Stock',
                  icon: Icons.block,
                  color: Colors.red,
                  value: '5',
                  subtitle: 'Items unavailable',
                ),
                _buildInventoryCard(
                  title: 'Stock Value',
                  icon: Icons.inventory_2,
                  color: Colors.green,
                  value: '₹2.5L',
                  subtitle: 'Total inventory value',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard({
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
