import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  RangeValues _priceRange = const RangeValues(0, 1000);
  RangeValues _deliveryRange = const RangeValues(0, 10);
  List<String> _selectedCuisines = [];
  List<String> _selectedDietary = [];
  List<String> _selectedOffers = [];
  double _minRating = 0.0;
  bool _showOpenOnly = false;
  bool _vegOnly = true;

  final List<String> _cuisines = [
    'Indian',
    'Chinese',
    'Italian',
    'Mexican',
    'Thai',
    'Continental',
    'Japanese',
    'American',
  ];
  final List<String> _dietary = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Keto',
    'Halal',
  ];
  final List<String> _offers = [
    'Free Delivery',
    '50% OFF',
    'Buy 1 Get 1',
    'Cashback',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Advanced Search'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRange(),
                  const SizedBox(height: 24),
                  _buildDeliveryRange(),
                  const SizedBox(height: 24),
                  _buildVegToggle(),
                  const SizedBox(height: 24),
                  _buildOpenNowFilter(),
                  const SizedBox(height: 24),
                  _buildRatingFilter(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Cuisines'),
                  _buildFilterChips(
                    _cuisines,
                    _selectedCuisines,
                    (val) => _selectedCuisines = val,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Dietary Preferences'),
                  _buildFilterChips(
                    _dietary,
                    _selectedDietary,
                    (val) => _selectedDietary = val,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Offers'),
                  _buildFilterChips(
                    _offers,
                    _selectedOffers,
                    (val) => _selectedOffers = val,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildVegToggle() {
    return Card(
      child: SwitchListTile(
        title: const Text('Vegetarian Only'),
        subtitle: const Text('Hide non-vegetarian options'),
        value: _vegOnly,
        activeColor: AppColors.primary,
        onChanged: (val) => setState(() => _vegOnly = val),
      ),
    );
  }

  Widget _buildPriceRange() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Range (₹)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 2000,
              divisions: 20,
              labels: RangeLabels(
                '₹${_priceRange.start.round()}',
                '₹${_priceRange.end.round()}',
              ),
              activeColor: AppColors.primary,
              onChanged: (values) => setState(() => _priceRange = values),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryRange() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Time (km)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            RangeSlider(
              values: _deliveryRange,
              min: 0,
              max: 20,
              divisions: 20,
              labels: RangeLabels(
                '${_deliveryRange.start.round()} km',
                '${_deliveryRange.end.round()} km',
              ),
              activeColor: AppColors.primary,
              onChanged: (values) => setState(() => _deliveryRange = values),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Minimum Rating',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 10,
              label: '${_minRating.toStringAsFixed(1)}+ stars',
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _minRating = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenNowFilter() {
    return Card(
      child: SwitchListTile(
        title: const Text('Open Now Only'),
        value: _showOpenOnly,
        activeColor: AppColors.primary,
        onChanged: (value) => setState(() => _showOpenOnly = value),
      ),
    );
  }

  Widget _buildFilterChips(
    List<String> options,
    List<String> selected,
    Function(List<String>) onUpdate,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return FilterChip(
          label: Text(option),
          selected: selected.contains(option),
          selectedColor: AppColors.primary.withAlpha(51),
          checkmarkColor: AppColors.primary,
          showCheckmark: true,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                onUpdate([...selected, option]);
              } else {
                onUpdate([...selected].where((e) => e != option).toList());
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _clearAll() {
    setState(() {
      _priceRange = const RangeValues(0, 1000);
      _deliveryRange = const RangeValues(0, 10);
      _selectedCuisines.clear();
      _selectedDietary.clear();
      _selectedOffers.clear();
      _minRating = 0.0;
      _showOpenOnly = false;
      _vegOnly = true;
    });
  }

  void _applyFilters() {
    final filters = {
      'priceMin': _priceRange.start,
      'priceMax': _priceRange.end,
      'deliveryMin': _deliveryRange.start,
      'deliveryMax': _deliveryRange.end,
      'cuisines': _selectedCuisines,
      'dietary': _selectedDietary,
      'offers': _selectedOffers,
      'minRating': _minRating,
      'openNow': _showOpenOnly,
      'vegOnly': _vegOnly,
    };
    Navigator.pop(context, filters);
  }
}
