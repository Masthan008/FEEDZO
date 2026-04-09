import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Schedule Management', subtitle: 'Manage restaurant and driver schedules'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildScheduleCard(
                  title: 'Restaurant Schedules',
                  icon: Icons.store,
                  color: Colors.blue,
                  value: '245',
                  subtitle: 'Restaurants scheduled',
                ),
                _buildScheduleCard(
                  title: 'Driver Shifts',
                  icon: Icons.access_time,
                  color: Colors.green,
                  value: '185',
                  subtitle: 'Driver schedules',
                ),
                _buildScheduleCard(
                  title: 'Active Now',
                  icon: Icons.play_circle,
                  color: Colors.orange,
                  value: '127',
                  subtitle: 'Currently active',
                ),
                _buildScheduleCard(
                  title: 'Upcoming',
                  icon: Icons.upcoming,
                  color: Colors.purple,
                  value: '45',
                  subtitle: 'Starting soon',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard({
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
