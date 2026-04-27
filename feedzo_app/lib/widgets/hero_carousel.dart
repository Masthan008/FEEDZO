import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Hero carousel for restaurant cards with parallax scroll effect
/// Used on home screen for featured restaurants
class HeroCarousel extends StatefulWidget {
  final List<HeroRestaurantItem> items;
  final Function(HeroRestaurantItem) onTap;

  const HeroCarousel({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (index) => setState(() {}),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final scale = 1 - (_currentPage - index).abs() * 0.1;
          final opacity = 1 - (_currentPage - index).abs() * 0.3;

          return Transform.scale(
            scale: scale.clamp(0.9, 1.0),
            child: Opacity(
              opacity: opacity.clamp(0.7, 1.0),
              child: GestureDetector(
                onTap: () => widget.onTap(item),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: AppShape.xlarge,
                    boxShadow: AppShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: AppShape.xlarge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image with parallax
                        Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment(
                            (_currentPage - index).clamp(-1, 1) * 0.3,
                            0,
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.cuisine} · ${item.deliveryTime} min',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: AppShape.small,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.rating}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item.offer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: AppShape.small,
                                      ),
                                      child: Text(
                                        item.offer!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HeroRestaurantItem {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisine;
  final int deliveryTime;
  final double rating;
  final String? offer;

  HeroRestaurantItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.deliveryTime,
    required this.rating,
    this.offer,
  });
}
