import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final reviews = snapshot.data?.docs ?? [];
              final totalFeedback = reviews.length;
              final positiveReviews = reviews.where((r) {
                final data = r.data() as Map<String, dynamic>;
                return (data['rating'] as num?) != null && data['rating'] >= 4;
              }).length;
              final negativeReviews = reviews.where((r) {
                final data = r.data() as Map<String, dynamic>;
                return (data['rating'] as num?) != null && data['rating'] <= 2;
              }).length;
              final avgRating = reviews.isEmpty
                  ? 0.0
                  : reviews.fold<double>(0, (sum, r) {
                      final data = r.data() as Map<String, dynamic>;
                      return sum + ((data['rating'] as num?) ?? 0).toDouble();
                    }) / reviews.length;

              return Padding(
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
                      value: totalFeedback.toString(),
                      subtitle: 'Total submissions',
                    ),
                    _buildFeedbackCard(
                      title: 'Positive',
                      icon: Icons.thumb_up,
                      color: Colors.green,
                      value: positiveReviews.toString(),
                      subtitle: 'Positive reviews',
                    ),
                    _buildFeedbackCard(
                      title: 'Negative',
                      icon: Icons.thumb_down,
                      color: Colors.red,
                      value: negativeReviews.toString(),
                      subtitle: 'Negative reviews',
                    ),
                    _buildFeedbackCard(
                      title: 'Avg Rating',
                      icon: Icons.star,
                      color: Colors.orange,
                      value: avgRating.toStringAsFixed(1),
                      subtitle: 'Overall rating',
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
