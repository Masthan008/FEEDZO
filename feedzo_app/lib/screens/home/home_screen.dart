import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/location_provider.dart';
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
  }

  // ── Header (Green Theme + Search + Veg Toggle) ────────────────────────
  Widget _buildTopHeader(BuildContext context, RestaurantProvider rp) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Location + Profile
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Location Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          user != null ? 'Hello, ${user.name.split(' ').first}' : 'Home',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Consumer<LocationProvider>(
                      builder: (_, loc, __) {
                        return Text(
                          loc.currentAddress,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Clean Profile Avatar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar + Veg Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Search "comfort food"', style: TextStyle(color: AppColors.textHint, fontSize: 15)),
                        Spacer(),
                        Icon(Icons.mic, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text('VEG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: rp.vegOnly,
                      onChanged: (v) => rp.setVegOnly(v),
                      activeColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── High Impact Promo Banner ──────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1000'),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('PLAY & WIN BIG', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            Text('Order now and earn rewards', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Categories (Image + Text) ──────────────────────────────────────────────
  Widget _buildCategories() {
    final categories = [
      {'name': 'Biryani', 'img': 'https://images.unsplash.com/photo-1589302168068-964664d93cb0?w=200&q=80'},
      {'name': 'Thali', 'img': 'https://images.unsplash.com/photo-1626776876729-abdf9b02ff60?w=200&q=80'},
      {'name': 'Chicken', 'img': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=200&q=80'},
      {'name': 'Pizza', 'img': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200&q=80'},
      {'name': 'Burger', 'img': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&q=80'},
      {'name': 'Chinese', 'img': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=200&q=80'},
      {'name': 'Dessert', 'img': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=200&q=80'},
      {'name': 'Healthy', 'img': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200&q=80'},
    ];
    
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // 'Meals under 250' specialized card
              Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('MEALS UNDER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                    Text('₹250', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue)),
                    SizedBox(height: 4),
                    Text('Explore >', style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                  ],
                ),
              ),
              // Category Items
              ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(c['img']!),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Text(c['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              )),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ],
    );
  }

  // ── Filter Row (Clean Chips) ────────────────────────────────────────────────
  Widget _buildFilterRow(RestaurantProvider rp) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterPill(Icons.tune, 'Filters', false),
          _buildFilterPill(Icons.bolt, 'Near & Fast', false),
          _buildFilterPill(Icons.calendar_today, 'Schedule', false),
          _buildFilterPill(Icons.star, 'Great Offers', rp.minRating > 0, onTap: () => rp.setMinRating(rp.minRating > 0 ? 0 : 4.0)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(IconData icon, String label, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.primary : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  // ── Main Build Method Overhaul ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RestaurantProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context, rp),
            _buildPromoBanner(),
            _buildCategories(),
            _buildFilterRow(rp),
            
            const SizedBox(height: 24),
            // Replace Emoji text with a rich text row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_alt_rounded, color: Colors.blueGrey, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'RECOMMENDED FOR YOU',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (rp.isLoading) 
              _buildLoadingSkeletons()
            else if (rp.error != null)
              _buildErrorView(rp)
            else if (rp.restaurants.isEmpty)
              _buildEmptyView()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rp.restaurants.length,
                  itemBuilder: (_, i) => RestaurantCard(
                    restaurant: rp.restaurants[i],
                    onTap: () => _openRestaurant(context, rp.restaurants[i].id),
                  ),
                ),
              ),
              
            const SizedBox(height: 100),
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

  Widget _buildLoadingSkeletons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(3, (index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: RestaurantCardSkeleton(),
        )),
      ),
    );
  }

  Widget _buildErrorView(RestaurantProvider rp) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Network Error', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: rp.loadRestaurants, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('No restaurants available in this area.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  void _openRestaurant(BuildContext context, String id) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RestaurantScreen(restaurantId: id),
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
