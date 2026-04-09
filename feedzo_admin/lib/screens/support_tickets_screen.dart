import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Support Tickets', subtitle: 'Manage customer support tickets'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildTicketCard(
                  title: 'Open Tickets',
                  icon: Icons.mail,
                  color: Colors.blue,
                  value: '45',
                  subtitle: 'Awaiting response',
                ),
                _buildTicketCard(
                  title: 'In Progress',
                  icon: Icons.pending,
                  color: Colors.orange,
                  value: '23',
                  subtitle: 'Being handled',
                ),
                _buildTicketCard(
                  title: 'Resolved Today',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  value: '12',
                  subtitle: 'Closed today',
                ),
                _buildTicketCard(
                  title: 'Avg Response Time',
                  icon: Icons.timer,
                  color: Colors.purple,
                  value: '2h',
                  subtitle: 'Response time',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard({
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
