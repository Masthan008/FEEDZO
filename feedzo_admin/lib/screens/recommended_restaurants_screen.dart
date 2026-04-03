import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';

/// Admin screen to mark restaurants as "recommended" for the customer app.
/// Recommended restaurants appear in a special section on the customer home.
class RecommendedRestaurantsScreen extends StatefulWidget {
  const RecommendedRestaurantsScreen({super.key});
  @override
  State<RecommendedRestaurantsScreen> createState() =>
      _RecommendedRestaurantsScreenState();
}

class _RecommendedRestaurantsScreenState
    extends State<RecommendedRestaurantsScreen> {
  final _db = FirebaseFirestore.instance.collection('restaurants');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.thumb_up_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Recommended Restaurants',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .where('isRecommended', isEqualTo: true)
                      .snapshots(),
                  builder: (_, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return Text(
                      '$count recommended',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Toggle restaurants to show them in the "Recommended" section on the customer app.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Restaurant list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _db.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No restaurants found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['name'] ?? 'Unknown';
                    final image = d['image'] ?? '';
                    final cuisine = d['cuisine'] ?? '';
                    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
                    final isRecommended = d['isRecommended'] == true;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isRecommended
                            ? AppColors.primary.withValues(alpha: 0.04)
                            : AppColors.surface,
                      ),
                      child: Row(
                        children: [
                          // Restaurant image
                          ClipRRect(
                            borderRadius: AppShape.small,
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholder(),
                                  )
                                : _placeholder(),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  cuisine,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Recommend toggle
                          Switch(
                            value: isRecommended,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              doc.reference
                                  .update({'isRecommended': val});
                            },
                          ),

                          // Badge
                          if (isRecommended)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '★ FEATURED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800),
                              ),
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
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppShape.small,
        ),
        child: const Icon(Icons.restaurant, color: AppColors.textHint),
      );
}
