import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../providers/auth_provider.dart';

class RateOrderScreen extends StatefulWidget {
  final String orderId;
  final String restaurantId;
  final String restaurantName;
  final String? driverId;
  final String? driverName;
  final List<OrderItemRating> items;

  const RateOrderScreen({
    super.key,
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
    this.driverId,
    this.driverName,
    this.items = const [],
  });

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  final _reviewService = ReviewService();
  bool _isSubmitting = false;

  // Restaurant rating
  double _restaurantRating = 0;
  final _restaurantReviewCtrl = TextEditingController();
  final List<String> _selectedRestaurantTags = [];

  // Driver rating
  double _driverRating = 0;
  final _driverReviewCtrl = TextEditingController();
  final List<String> _selectedDriverTags = [];

  // Dish ratings
  final Map<String, double> _dishRatings = {};
  final Map<String, TextEditingController> _dishReviewCtrls = {};

  @override
  void initState() {
    super.initState();
    // Initialize dish controllers
    for (final item in widget.items) {
      _dishReviewCtrls[item.dishId] = TextEditingController();
      _dishRatings[item.dishId] = 0;
    }
  }

  @override
  void dispose() {
    _restaurantReviewCtrl.dispose();
    _driverReviewCtrl.dispose();
    for (final ctrl in _dishReviewCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_restaurantRating == 0) {
      _showError('Please rate the restaurant');
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare dish reviews
      final dishReviews = <DishReviewData>[];
      for (final item in widget.items) {
        final rating = _dishRatings[item.dishId] ?? 0;
        if (rating > 0) {
          dishReviews.add(DishReviewData(
            dishId: item.dishId,
            dishName: item.dishName,
            rating: rating,
            review: _dishReviewCtrls[item.dishId]?.text,
          ));
        }
      }

      await _reviewService.submitOrderReviews(
        orderId: widget.orderId,
        customerId: user.id,
        customerName: user.name,
        customerAvatarUrl: user.avatarUrl,
        restaurantId: widget.restaurantId,
        restaurantRating: _restaurantRating,
        restaurantReview: _restaurantReviewCtrl.text.isNotEmpty
            ? _restaurantReviewCtrl.text
            : null,
        restaurantTags: _selectedRestaurantTags,
        driverId: widget.driverId,
        driverRating: widget.driverId != null && _driverRating > 0
            ? _driverRating
            : null,
        driverReview: _driverReviewCtrl.text.isNotEmpty
            ? _driverReviewCtrl.text
            : null,
        driverTags: _selectedDriverTags,
        dishReviews: dishReviews,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to submit review: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rate Your Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Restaurant Rating
            _buildRestaurantSection(),
            const SizedBox(height: 24),

            // Driver Rating (if available)
            if (widget.driverId != null) ...[
              _buildDriverSection(),
              const SizedBox(height: 24),
            ],

            // Dish Ratings (if any items)
            if (widget.items.isNotEmpty) ...[
              _buildDishesSection(),
              const SizedBox(height: 24),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your experience?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your feedback helps us improve our service',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildRestaurantSection() {
    return _buildRatingCard(
      title: widget.restaurantName,
      subtitle: 'Restaurant',
      icon: Icons.restaurant_rounded,
      rating: _restaurantRating,
      onRatingChanged: (rating) {
        setState(() => _restaurantRating = rating);
        HapticFeedback.lightImpact();
      },
      reviewCtrl: _restaurantReviewCtrl,
      hintText: 'Share your experience with the food, packaging, etc.',
      selectedTags: _selectedRestaurantTags,
      availableTags: ReviewTags.all,
    );
  }

  Widget _buildDriverSection() {
    return _buildRatingCard(
      title: widget.driverName ?? 'Delivery Partner',
      subtitle: 'Delivery Partner',
      icon: Icons.delivery_dining_rounded,
      rating: _driverRating,
      onRatingChanged: (rating) {
        setState(() => _driverRating = rating);
        HapticFeedback.lightImpact();
      },
      reviewCtrl: _driverReviewCtrl,
      hintText: 'How was the delivery experience?',
      selectedTags: _selectedDriverTags,
      availableTags: const [
        'Fast Delivery',
        'Polite Driver',
        'Good Packaging',
        'Late Delivery',
        'Rude Behavior',
        'Professional',
      ],
    );
  }

  Widget _buildDishesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Rate Individual Dishes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildDishRatingTile(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDishRatingTile(OrderItemRating item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.dishName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStarRating(
                rating: _dishRatings[item.dishId] ?? 0,
                size: 24,
                onRatingChanged: (rating) {
                  setState(() => _dishRatings[item.dishId] = rating);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
          if ((_dishRatings[item.dishId] ?? 0) > 0) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _dishReviewCtrls[item.dishId],
              decoration: InputDecoration(
                hintText: 'Thoughts on ${item.dishName}?',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required double rating,
    required ValueChanged<double> onRatingChanged,
    required TextEditingController reviewCtrl,
    required String hintText,
    required List<String> selectedTags,
    required List<String> availableTags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Star Rating
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStarRating(
                  rating: rating,
                  size: 40,
                  onRatingChanged: onRatingChanged,
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(rating),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rating > 0 ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // Review Text Field
          if (rating > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: reviewCtrl,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickTags(
                selectedTags: selectedTags,
                availableTags: availableTags,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating({
    required double rating,
    required double size,
    required ValueChanged<double> onRatingChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;
        final isHalf = rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTap: () {
            onRatingChanged(starValue.toDouble());
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isFilled
                  ? Icons.star_rounded
                  : isHalf
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: size,
              color: isFilled || isHalf
                  ? const Color(0xFFFFB800)
                  : AppColors.border,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickTags({
    required List<String> selectedTags,
    required List<String> availableTags,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        final isPositive = ReviewTags.positive.contains(tag);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedTags.remove(tag);
              } else {
                selectedTags.add(tag);
              }
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isPositive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1))
                  : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isPositive ? AppColors.success : AppColors.error)
                    : AppColors.border,
              ),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isPositive ? AppColors.success : AppColors.error)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent!';
  }
}

/// Data class for order items to rate
class OrderItemRating {
  final String dishId;
  final String dishName;
  final int quantity;

  OrderItemRating({
    required this.dishId,
    required this.dishName,
    required this.quantity,
  });
}
