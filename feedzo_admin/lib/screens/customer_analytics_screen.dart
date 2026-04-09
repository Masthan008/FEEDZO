import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() => _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Customer Analytics', subtitle: 'View customer behavior analytics'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (usersSnapshot.hasError) {
                return Center(child: Text('Error: ${usersSnapshot.error}'));
              }

              final users = usersSnapshot.data?.docs ?? [];
              final totalCustomers = users.length;
              
              final now = DateTime.now();
              final thirtyDaysAgo = now.subtract(const Duration(days: 30));
              final activeCustomers = users.where((u) {
                final data = u.data() as Map<String, dynamic>;
                final lastActive = data['lastActiveAt'] as Timestamp?;
                if (lastActive == null) return false;
                return lastActive.toDate().isAfter(thirtyDaysAgo);
              }).length;

              final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
              final newSignups = users.where((u) {
                final data = u.data() as Map<String, dynamic>;
                final createdAt = data['createdAt'] as Timestamp?;
                if (createdAt == null) return false;
                return createdAt.toDate().isAfter(oneMonthAgo);
              }).length;

              // Calculate retention rate (simplified)
              final retentionRate = totalCustomers > 0 
                  ? ((activeCustomers / totalCustomers) * 100).toStringAsFixed(0) 
                  : '0';

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: [
                    _buildAnalyticsCard(
                      title: 'Total Customers',
                      icon: Icons.people,
                      color: Colors.blue,
                      value: totalCustomers.toString(),
                      subtitle: 'Registered users',
                    ),
                    _buildAnalyticsCard(
                      title: 'Active Customers',
                      icon: Icons.person_pin,
                      color: Colors.green,
                      value: activeCustomers.toString(),
                      subtitle: 'Active in last 30 days',
                    ),
                    _buildAnalyticsCard(
                      title: 'New Signups',
                      icon: Icons.person_add,
                      color: Colors.orange,
                      value: '+$newSignups',
                      subtitle: 'This month',
                    ),
                    _buildAnalyticsCard(
                      title: 'Retention Rate',
                      icon: Icons.sync,
                      color: Colors.purple,
                      value: '$retentionRate%',
                      subtitle: '30-day retention',
                    ),
                  ],
                ),
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
