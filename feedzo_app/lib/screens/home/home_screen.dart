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
import '../../widgets/app_transitions.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/location_provider.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../data/models/banner_model.dart';
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

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Update Delivery Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text('Use Current Location'),
                subtitle: const Text('Auto-fetch based on GPS'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<LocationProvider>().refreshLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blueGrey),
                title: const Text('Enter Location Manually'),
                subtitle: const Text('Search for a specific address'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showManualLocationDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final TextEditingController addressCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Delivery Address'),
        content: TextField(
          controller: addressCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. 123 Main St, New York',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = addressCtrl.text.trim();
              if (val.isNotEmpty) {
                context.read<LocationProvider>().setManualAddress(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                child: GestureDetector(
                  onTap: () => _showLocationOptions(context),
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
                    AppTransitions.fadeSlide(const SearchScreen()),
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
  // (Replaced by _PromoBannerCarousel below)

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
              GestureDetector(
                onTap: () => Navigator.push(context, AppTransitions.fadeSlide(SearchScreen(initialQuery: 'Meals under 250'))),
                child: Container(
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
              ),
              // Category Items
              ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, AppTransitions.fadeSlide(SearchScreen(initialQuery: c['name']!))),
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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          rp.loadRestaurants();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context, rp),
              const _PromoBannerCarousel(),
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
              if (rp.recommended.isNotEmpty)
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rp.recommended.length,
                    itemBuilder: (_, i) => SizedBox(
                      width: 250,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: RestaurantCard(
                          restaurant: rp.recommended[i],
                          onTap: () => _openRestaurant(context, rp.recommended[i].id),
                        ),
                      ),
                    ),
                  ),
                ),
              if (rp.recommended.isNotEmpty) const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: Colors.blueGrey, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'ALL RESTAURANTS',
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
      AppTransitions.fadeSlide(RestaurantScreen(restaurantId: id)),
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

class _PromoBannerCarousel extends StatefulWidget {
  const _PromoBannerCarousel({super.key});
  @override
  State<_PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<_PromoBannerCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  void _startTimer(int bannerCount) {
    _timer?.cancel();
    if (bannerCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextIndex = (_currentIndex + 1) % bannerCount;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BannerModel>>(
      stream: FirestoreService.watchActiveBanners(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final banners = snapshot.data!;
        // Start or restart timer based on current data
        _startTimer(banners.length);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              height: 160,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final b = banners[index];
                  return GestureDetector(
                    onTap: () => _launchURL(b.actionUrl),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(b.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (b.subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(b.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (banners.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
