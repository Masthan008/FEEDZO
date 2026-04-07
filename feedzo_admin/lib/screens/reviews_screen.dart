import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../widgets/topbar.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';

/// Admin screen to manage all customer reviews across the platform
class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(
          title: 'Reviews Management',
          subtitle: 'Moderate customer reviews across the platform',
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              final reviews = snapshot.data?.docs.map((doc) {
                return ReviewModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                );
              }).toList() ?? [];

              if (reviews.isEmpty) {
                return _buildEmptyState();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Stats Row
                    _buildStatsRow(reviews),
                    const SizedBox(height: 24),

                    // Reviews Table
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _TableHeader(),
                          ...reviews.map((review) => _ReviewRow(
                            review: review,
                            onToggleVisibility: () => _toggleVisibility(context, review),
                            onDelete: () => _deleteReview(context, review),
                          )),
                        ],
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<ReviewModel> reviews) {
    final total = reviews.length;
    final visible = reviews.where((r) => r.isVisible).length;
    final hidden = total - visible;
    final avgRating = total > 0
        ? reviews.fold<double>(0, (sum, r) => sum + r.rating) / total
        : 0.0;

    final restaurantReviews = reviews.where((r) => r.targetType == ReviewTargetType.restaurant).length;
    final driverReviews = reviews.where((r) => r.targetType == ReviewTargetType.driver).length;
    final dishReviews = reviews.where((r) => r.targetType == ReviewTargetType.dish).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        
        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildStatCard('Total Reviews', '$total', Icons.rate_review_rounded, AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Visible', '$visible', Icons.visibility_rounded, AppColors.success)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Hidden', '$hidden', Icons.visibility_off_rounded, AppColors.warning)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Avg Rating', avgRating.toStringAsFixed(1), Icons.star_rounded, const Color(0xFFFFB800))),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total', '$total', Icons.rate_review_rounded, AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Visible', '$visible', Icons.visibility_rounded, AppColors.success)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Hidden', '$hidden', Icons.visibility_off_rounded, AppColors.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Avg Rating', avgRating.toStringAsFixed(1), Icons.star_rounded, const Color(0xFFFFB800))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Restaurants', '$restaurantReviews', Icons.restaurant_rounded, AppColors.info)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Drivers', '$driverReviews', Icons.delivery_dining_rounded, const Color(0xFF7C3AED))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Dishes', '$dishReviews', Icons.restaurant_menu_rounded, const Color(0xFFEC4899))),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVisibility(BuildContext context, ReviewModel review) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(review.id)
          .update({
        'isVisible': !review.isVisible,
        'moderationReason': review.isVisible ? 'Hidden by admin' : null,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(review.isVisible ? 'Review hidden' : 'Review made visible'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(BuildContext context, ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review?'),
        content: Text(
          'This will permanently delete the review from ${review.customerName}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ReviewService().deleteReview(review.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 1, child: Text('Rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 1, child: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _ReviewRow({
    required this.review,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: review.customerAvatarUrl != null
                      ? NetworkImage(review.customerAvatarUrl!)
                      : null,
                  backgroundColor: AppColors.primarySurface,
                  child: review.customerAvatarUrl == null
                      ? Text(
                          review.customerName.isNotEmpty
                              ? review.customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.customerName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Target
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  _getTargetIcon(review.targetType),
                  size: 14,
                  color: _getTargetColor(review.targetType),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    review.targetType.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getTargetColor(review.targetType),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rating
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: const Color(0xFFFFB800),
                ),
                const SizedBox(width: 2),
                Text(
                  review.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Review Text
          Expanded(
            flex: 3,
            child: Text(
              review.reviewText ?? '-',
              style: TextStyle(
                fontSize: 13,
                color: review.reviewText != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Date
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('MMM d').format(review.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: review.isVisible
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.isVisible ? 'Visible' : 'Hidden',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: review.isVisible ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    review.isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18,
                    color: review.isVisible ? AppColors.warning : AppColors.success,
                  ),
                  onPressed: onToggleVisibility,
                  tooltip: review.isVisible ? 'Hide' : 'Show',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTargetIcon(ReviewTargetType type) {
    switch (type) {
      case ReviewTargetType.restaurant:
        return Icons.restaurant_rounded;
      case ReviewTargetType.driver:
        return Icons.delivery_dining_rounded;
      case ReviewTargetType.dish:
        return Icons.restaurant_menu_rounded;
    }
  }

  Color _getTargetColor(ReviewTargetType type) {
    switch (type) {
      case ReviewTargetType.restaurant:
        return AppColors.info;
      case ReviewTargetType.driver:
        return const Color(0xFF7C3AED);
      case ReviewTargetType.dish:
        return const Color(0xFFEC4899);
    }
  }
}
