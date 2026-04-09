import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DeliveryZonesScreen extends StatefulWidget {
  const DeliveryZonesScreen({super.key});

  @override
  State<DeliveryZonesScreen> createState() => _DeliveryZonesScreenState();
}

class _DeliveryZonesScreenState extends State<DeliveryZonesScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Delivery Zones', subtitle: 'Manage delivery zone configurations'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildZoneCard(
                  title: 'Active Zones',
                  icon: Icons.location_city,
                  color: Colors.blue,
                  value: '15',
                  subtitle: 'Delivery zones',
                ),
                _buildZoneCard(
                  title: 'Coverage Area',
                  icon: Icons.map,
                  color: Colors.green,
                  value: '85%',
                  subtitle: 'City covered',
                ),
                _buildZoneCard(
                  title: 'Avg Delivery Time',
                  icon: Icons.timer,
                  color: Colors.orange,
                  value: '25 min',
                  subtitle: 'Per zone',
                ),
                _buildZoneCard(
                  title: 'Delivery Fee',
                  icon: Icons.delivery_dining,
                  color: Colors.purple,
                  value: '₹40',
                  subtitle: 'Average fee',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneCard({
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
