import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Feedback', subtitle: 'View customer feedback'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildFeedbackCard(
                  title: 'Total Feedback',
                  icon: Icons.feedback,
                  color: Colors.blue,
                  value: '2,450',
                  subtitle: 'Total submissions',
                ),
                _buildFeedbackCard(
                  title: 'Positive',
                  icon: Icons.thumb_up,
                  color: Colors.green,
                  value: '1,890',
                  subtitle: 'Positive reviews',
                ),
                _buildFeedbackCard(
                  title: 'Negative',
                  icon: Icons.thumb_down,
                  color: Colors.red,
                  value: '245',
                  subtitle: 'Negative reviews',
                ),
                _buildFeedbackCard(
                  title: 'Avg Rating',
                  icon: Icons.star,
                  color: Colors.orange,
                  value: '4.2',
                  subtitle: 'Overall rating',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard({
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
