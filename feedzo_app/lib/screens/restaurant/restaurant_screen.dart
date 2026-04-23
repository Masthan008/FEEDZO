import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/models/restaurant_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_transitions.dart';
import '../../widgets/quantity_control.dart';
import '../cart/cart_screen.dart';

class RestaurantScreen extends StatefulWidget {
  final String restaurantId;
  const RestaurantScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final rp = context.read<RestaurantProvider>();
    final restaurant = rp.getById(widget.restaurantId);
    final cart = context.watch<CartProvider>();

    if (restaurant == null) {
      return const Scaffold(body: Center(child: Text('Restaurant not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<MenuItem>>(
        stream: FirestoreService.watchRestaurantMenu(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary));
          }
          final menu = snapshot.data ?? [];
          final categories = ['All', ...{...menu.map((m) => m.category)}];
          final filtered = _selectedCategory == 'All'
              ? menu
              : menu.where((m) => m.category == _selectedCategory).toList();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context, restaurant),
                  SliverToBoxAdapter(child: _buildInfo(restaurant)),
                  SliverToBoxAdapter(child: _buildCategoryTabs(categories)),
                  if (filtered.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No items in this category',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _MenuItemCard(
                            item: filtered[i],
                            restaurant: restaurant,
                            cart: cart,
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              if (cart.itemCount > 0 && cart.restaurantId == restaurant.id)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 16,
                  right: 16,
                  child: _CartBar(
                      cart: cart,
                      onTap: () => Navigator.push(
                        context,
                        AppTransitions.fadeSlide(const CartScreen()),
                      ),
                    ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Restaurant r) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppShape.medium,
            boxShadow: AppShadows.subtle,
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppShape.medium,
            boxShadow: AppShadows.subtle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share_outlined,
                color: AppColors.textPrimary, size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'restaurant_image_${r.id}',
          child: CachedNetworkImage(
            imageUrl: r.firstImage,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.surfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(Restaurant r) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!r.isOpen)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Closed',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            r.cuisine,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          // Info pills
          Row(
            children: [
              _InfoPill(
                icon: Icons.star_rounded,
                label: '${r.rating}',
                color: r.rating >= 4.0 ? AppColors.success : AppColors.warning,
                filled: true,
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon: Icons.access_time_rounded,
                label: '${r.deliveryTime} min',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon: Icons.delivery_dining_rounded,
                label: r.deliveryFee == 0
                    ? 'Free delivery'
                    : '₹${r.deliveryFee.toInt()} delivery',
                color: r.deliveryFee == 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Min order: ₹${r.minOrder.toInt()}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: 8),
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: AppConstants.animNormal,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: AppShape.round,
                boxShadow: selected ? AppShadows.primaryGlow(0.15) : [],
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Info Pill ──────────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: AppShape.round,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: filled ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Item Card ────────────────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Restaurant restaurant;
  final CartProvider cart;

  const _MenuItemCard({
    required this.item,
    required this.restaurant,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final qty = cart.quantityOf(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.medium,
        boxShadow: AppShadows.subtle,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 12,
                            color: item.isVeg
                                ? AppColors.success
                                : AppColors.error),
                        const SizedBox(width: 6),
                        if (item.isBestseller)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '★ Bestseller',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (item.discount > 0 && !item.isBestseller)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.discount.toInt()}% OFF',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.discount > 0) ...[
                          Text(
                            '₹${item.price.toInt()}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '₹${item.discountedPrice.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: AppShape.medium,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        height: 90,
                        width: 90,
                        child: const Icon(Icons.fastfood_rounded,
                            color: AppColors.textHint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.isAvailable)
                    QuantityControl(
                      quantity: qty,
                      onAdd: () {
                        if (cart.wouldSwitchRestaurant(restaurant.id)) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Replace cart items?'),
                              content: Text(
                                'Your cart has items from ${cart.restaurantName}. '
                                'Adding this item will clear your cart.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    cart.addItem(
                                      item,
                                      restaurant.id,
                                      restaurant.name,
                                      restaurant.firstImage,
                                      restaurant.deliveryFee,
                                      forceSwitch: true,
                                    );
                                  },
                                  child: const Text('Yes, start fresh'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          HapticFeedback.lightImpact();
                          cart.addItem(
                            item,
                            restaurant.id,
                            restaurant.name,
                            restaurant.firstImage,
                            restaurant.deliveryFee,
                            forceSwitch: true,
                          );
                        }
                      },
                      onRemove: () => cart.removeItem(item.id),
                    )
                  else
                    const Text(
                      'Not Available',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (!item.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: AppShape.medium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Cart Bar ──────────────────────────────────────────────────────────────────
class _CartBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onTap;

  const _CartBar({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: AppShape.large,
          boxShadow: AppShadows.primaryGlow(0.4),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${cart.itemCount}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'View Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '₹${cart.total.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
