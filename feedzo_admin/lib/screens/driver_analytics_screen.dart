import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DriverAnalyticsScreen extends StatefulWidget {
  const DriverAnalyticsScreen({super.key});

  @override
  State<DriverAnalyticsScreen> createState() => _DriverAnalyticsScreenState();
}

class _DriverAnalyticsScreenState extends State<DriverAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Driver Analytics', subtitle: 'View driver performance analytics'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
            builder: (context, driversSnapshot) {
              if (driversSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (driversSnapshot.hasError) {
                return Center(child: Text('Error: ${driversSnapshot.error}'));
              }

              final drivers = driversSnapshot.data?.docs ?? [];
              final totalDrivers = drivers.length;
              final onlineDrivers = drivers.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isOnline'] == true;
              }).length;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('status', isEqualTo: 'delivered')
                    .snapshots(),
                builder: (context, ordersSnapshot) {
                  if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (ordersSnapshot.hasError) {
                    return Center(child: Text('Error: ${ordersSnapshot.error}'));
                  }

                  final orders = ordersSnapshot.data?.docs ?? [];
                  
                  final now = DateTime.now();
                  final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
                  final totalDeliveries = orders.where((o) {
                    final data = o.data() as Map<String, dynamic>;
                    final deliveredAt = data['deliveredAt'] as Timestamp?;
                    if (deliveredAt == null) return false;
                    return deliveredAt.toDate().isAfter(oneMonthAgo);
                  }).length;

                  // Calculate avg delivery time (simplified)
                  final avgDeliveryTime = orders.isEmpty ? 0 : 28; // Placeholder for actual calculation

                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      children: [
                        _buildAnalyticsCard(
                          title: 'Total Drivers',
                          icon: Icons.delivery_dining,
                          color: Colors.blue,
                          value: totalDrivers.toString(),
                          subtitle: 'Active drivers',
                        ),
                        _buildAnalyticsCard(
                          title: 'Online Now',
                          icon: Icons.circle,
                          color: Colors.green,
                          value: onlineDrivers.toString(),
                          subtitle: 'Currently online',
                        ),
                        _buildAnalyticsCard(
                          title: 'Avg Delivery Time',
                          icon: Icons.timer,
                          color: Colors.orange,
                          value: '$avgDeliveryTime min',
                          subtitle: 'Average delivery',
                        ),
                        _buildAnalyticsCard(
                          title: 'Total Deliveries',
                          icon: Icons.local_shipping,
                          color: Colors.purple,
                          value: totalDeliveries.toString(),
                          subtitle: 'This month',
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
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
