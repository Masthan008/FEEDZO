import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../restaurant/restaurant_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RestaurantProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),

            // Sticky Search Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchDelegate(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SearchScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: AppConstants.animPageTransition,
                  ),
                ),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(child: _buildFilterChips(rp)),

            // Categories
            SliverToBoxAdapter(child: _buildCategories()),

            // Promotional Banner
            SliverToBoxAdapter(child: _buildPromoBanner()),

            if (rp.isLoading) ...[
              SliverToBoxAdapter(child: _sectionTitle('Trending near you')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const RestaurantCardSkeleton(),
                    childCount: 3,
                  ),
                ),
              ),
            ] else ...[
              // Trending
              if (rp.trending.isNotEmpty) ...[
                SliverToBoxAdapter(child: _sectionTitle('🔥 Trending near you')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => RestaurantCard(
                        restaurant: rp.trending[i],
                        isTrending: true,
                        onTap: () =>
                            _openRestaurant(context, rp.trending[i].id),
                      ),
                      childCount: rp.trending.length,
                    ),
                  ),
                ),
              ],

              // AI Recommended
              SliverToBoxAdapter(child: _buildAISection(context, rp)),

              // All Restaurants
              SliverToBoxAdapter(child: _sectionTitle('All Restaurants')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => RestaurantCard(
                      restaurant: rp.restaurants[i],
                      onTap: () =>
                          _openRestaurant(context, rp.restaurants[i].id),
                    ),
                    childCount: rp.restaurants.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: cart.itemCount > 0
          ? _CartFAB(
              cart: cart,
              onTap: () => Navigator.pushNamed(context, '/cart'),
            )
          : null,
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Delivering to',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    SizedBox(width: 30),
                    Text(
                      AppConstants.defaultLocation,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppShape.medium,
              boxShadow: AppShadows.subtle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ────────────────────────────────────────────────────────────
  Widget _buildFilterChips(RestaurantProvider rp) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChipItem(
            label: 'Veg Only',
            icon: Icons.eco_rounded,
            selected: rp.vegOnly,
            onTap: () => rp.setVegOnly(!rp.vegOnly),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: '4.0+ Rating',
            icon: Icons.star_rounded,
            selected: rp.minRating >= 4.0,
            onTap: () => rp.setMinRating(rp.minRating >= 4.0 ? 0 : 4.0),
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: 'Fast Delivery',
            icon: Icons.bolt_rounded,
            selected: false,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: 'Offers',
            icon: Icons.local_offer_rounded,
            selected: false,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _FilterChipItem(
            label: 'Free Delivery',
            icon: Icons.delivery_dining_rounded,
            selected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ── Categories ──────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    final categories = [
      {'name': 'Burgers', 'icon': Icons.lunch_dining_rounded, 'color': const Color(0xFFFEF3C7)},
      {'name': 'Pizza', 'icon': Icons.local_pizza_rounded, 'color': const Color(0xFFFEE2E2)},
      {'name': 'Sushi', 'icon': Icons.set_meal_rounded, 'color': const Color(0xFFDBEAFE)},
      {'name': 'Desserts', 'icon': Icons.icecream_rounded, 'color': const Color(0xFFFCE7F3)},
      {'name': 'Healthy', 'icon': Icons.eco_rounded, 'color': const Color(0xFFD1FAE5)},
      {'name': 'Drinks', 'icon': Icons.local_cafe_rounded, 'color': const Color(0xFFE0E7FF)},
      {'name': 'Biryani', 'icon': Icons.rice_bowl_rounded, 'color': const Color(0xFFFEF9C3)},
    ];
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => HapticFeedback.selectionClick(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: AppColors.textPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Promo Banner ────────────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    final promos = [
      {
        'title': '50% OFF',
        'subtitle': 'on your first order',
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        'icon': Icons.celebration_rounded,
      },
      {
        'title': 'FREE DELIVERY',
        'subtitle': 'on orders above ₹299',
        'gradient': [AppColors.gradientStart, AppColors.gradientEnd],
        'icon': Icons.delivery_dining_rounded,
      },
      {
        'title': '₹100 CASHBACK',
        'subtitle': 'on UPI payments',
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFF97316)],
        'icon': Icons.account_balance_wallet_rounded,
      },
    ];

    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: promos.length,
        itemBuilder: (_, i) {
          final promo = promos[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: promo['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppShape.xl,
              boxShadow: [
                BoxShadow(
                  color: (promo['gradient'] as List<Color>)[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppShape.round,
                        ),
                        child: Text(
                          'ORDER NOW',
                          style: TextStyle(
                            color: (promo['gradient'] as List<Color>)[0],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  promo['icon'] as IconData,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 72,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── AI Section ──────────────────────────────────────────────────────────────
  Widget _buildAISection(BuildContext context, RestaurantProvider rp) {
    if (rp.aiRecommended.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientAccent],
                  ),
                  borderRadius: AppShape.small,
                  boxShadow: AppShadows.primaryGlow(0.2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'AI Recommended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: AppConstants.aiCardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rp.aiRecommended.length,
            itemBuilder: (_, i) {
              final r = rp.aiRecommended[i];
              return GestureDetector(
                onTap: () => _openRestaurant(context, r.id),
                child: Container(
                  width: AppConstants.aiCardWidth,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppShape.large,
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppShape.radiusLarge),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: r.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 120,
                            color: AppColors.surfaceVariant,
                          ),
                          errorWidget: (_, __, ___) =>
                              Container(height: 120, color: AppColors.surfaceVariant),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.cuisine,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.white, size: 10),
                                      const SizedBox(width: 1),
                                      Text(
                                        '${r.rating}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.access_time_rounded,
                                    color: AppColors.textSecondary, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '${r.deliveryTime}m',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Section Title ───────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  void _openRestaurant(BuildContext context, String id) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RestaurantScreen(restaurantId: id),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: AppConstants.animPageTransition,
      ),
    );
  }
}

// ── Sticky Search Delegate ────────────────────────────────────────────────────
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onTap;

  _StickySearchDelegate({required this.onTap});

  @override
  double get maxExtent => 64;
  @override
  double get minExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final elevation = shrinkOffset > 0;
    return AnimatedContainer(
      duration: AppConstants.animFast,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: elevation ? AppShadows.subtle : [],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShape.medium,
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
              SizedBox(width: 12),
              Text(
                'Search restaurants, cuisines...',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
              Spacer(),
              Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppConstants.animNormal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AppShape.round,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected ? AppShadows.primaryGlow(0.15) : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cart FAB ──────────────────────────────────────────────────────────────────
class _CartFAB extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onTap;

  const _CartFAB({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: AppShape.large,
          boxShadow: AppShadows.primaryGlow(0.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${cart.itemCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
