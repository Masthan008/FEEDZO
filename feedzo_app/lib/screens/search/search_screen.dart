import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/restaurant_card.dart';
import '../restaurant/restaurant_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RestaurantProvider>().setSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    context.read<RestaurantProvider>().resetFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RestaurantProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search restaurants, cuisines...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: rp.setSearch,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _ctrl.clear();
                rp.setSearch('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(rp),
          Expanded(
            child: rp.restaurants.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rp.restaurants.length,
                    itemBuilder: (_, i) => RestaurantCard(
                      restaurant: rp.restaurants[i],
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => RestaurantScreen(
                              restaurantId: rp.restaurants[i].id),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: AppConstants.animPageTransition,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(RestaurantProvider rp) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Veg Only',
              selected: rp.vegOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                rp.setVegOnly(!rp.vegOnly);
              },
              icon: Icons.eco_rounded,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: '4.0+ Rating',
              selected: rp.minRating >= 4.0,
              onTap: () {
                HapticFeedback.selectionClick();
                rp.setMinRating(rp.minRating >= 4.0 ? 0 : 4.0);
              },
              icon: Icons.star_rounded,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Fast Delivery',
              selected: rp.fastDeliveryOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                rp.setFastDeliveryOnly(!rp.fastDeliveryOnly);
              },
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Free Delivery',
              selected: rp.freeDeliveryOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                rp.setFreeDeliveryOnly(!rp.freeDeliveryOnly);
              },
              icon: Icons.delivery_dining_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
