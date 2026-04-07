import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../services/hike_charges_service.dart';
import '../widgets/topbar.dart';

class HikeChargesScreen extends StatefulWidget {
  const HikeChargesScreen({super.key});

  @override
  State<HikeChargesScreen> createState() => _HikeChargesScreenState();
}

class _HikeChargesScreenState extends State<HikeChargesScreen> {
  bool _isLoading = true;
  HikeChargesConfig? _config;
  
  // Controllers
  final _packagingCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _perKmCtrl = TextEditingController();
  final _hikeMultiplierCtrl = TextEditingController();
  final _commissionPlusCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _smallOrderFeeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  @override
  void dispose() {
    _packagingCtrl.dispose();
    _deliveryCtrl.dispose();
    _perKmCtrl.dispose();
    _hikeMultiplierCtrl.dispose();
    _commissionPlusCtrl.dispose();
    _minOrderCtrl.dispose();
    _smallOrderFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeConfig() async {
    await HikeChargesService.initializeDefaultConfig();
    _loadConfig();
  }

  void _loadConfig() {
    HikeChargesService.watchGlobalConfig().listen((config) {
      if (mounted && config != null) {
        setState(() {
          _config = config;
          _packagingCtrl.text = config.packagingCharges.toStringAsFixed(0);
          _deliveryCtrl.text = config.deliveryCharges.toStringAsFixed(0);
          _perKmCtrl.text = config.deliveryChargePerKm.toStringAsFixed(0);
          _hikeMultiplierCtrl.text = config.hikeMultiplier.toStringAsFixed(0);
          _commissionPlusCtrl.text = config.commissionPlus.toStringAsFixed(0);
          _minOrderCtrl.text = config.minimumOrderValue.toStringAsFixed(0);
          _smallOrderFeeCtrl.text = config.smallOrderFee.toStringAsFixed(0);
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    final updatedConfig = HikeChargesConfig(
      id: _config!.id,
      packagingCharges: double.tryParse(_packagingCtrl.text) ?? _config!.packagingCharges,
      deliveryCharges: double.tryParse(_deliveryCtrl.text) ?? _config!.deliveryCharges,
      deliveryChargePerKm: double.tryParse(_perKmCtrl.text) ?? _config!.deliveryChargePerKm,
      hikeMultiplier: double.tryParse(_hikeMultiplierCtrl.text) ?? _config!.hikeMultiplier,
      commissionPlus: double.tryParse(_commissionPlusCtrl.text) ?? _config!.commissionPlus,
      minimumOrderValue: double.tryParse(_minOrderCtrl.text) ?? _config!.minimumOrderValue,
      smallOrderFee: double.tryParse(_smallOrderFeeCtrl.text) ?? _config!.smallOrderFee,
      surgeEnabled: _config!.surgeEnabled,
      peakHoursStart: _config!.peakHoursStart,
      peakHoursEnd: _config!.peakHoursEnd,
      updatedAt: DateTime.now(),
    );

    await HikeChargesService.saveGlobalConfig(updatedConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hike charges updated successfully'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(
          title: 'Hike Charges',
          subtitle: 'Configure packaging, delivery, commission, and surge pricing',
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      _buildSummaryCards(),
                      const SizedBox(height: 24),

                      // Configuration Form
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Charges
                          Expanded(
                            child: _buildChargesCard(),
                          ),
                          const SizedBox(width: 20),
                          // Right Column - Commission & Surge
                          Expanded(
                            child: Column(
                              children: [
                                _buildCommissionCard(),
                                const SizedBox(height: 16),
                                _buildSurgeCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Restaurant Overrides Section
                      _buildRestaurantOverridesSection(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _SummaryCard(
          icon: Icons.inventory_2_rounded,
          label: 'Packaging',
          value: 'Rs.${_config?.packagingCharges.toStringAsFixed(0) ?? '0'}',
          color: AppColors.primary,
          sub: 'Per order',
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.local_shipping_rounded,
          label: 'Base Delivery',
          value: 'Rs.${_config?.deliveryCharges.toStringAsFixed(0) ?? '0'}',
          color: AppColors.info,
          sub: '+ Rs.${_config?.deliveryChargePerKm.toStringAsFixed(0) ?? '0'}/km',
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.trending_up_rounded,
          label: 'Hike Multiplier',
          value: '${_config?.hikeMultiplier.toStringAsFixed(0) ?? '0'}%',
          color: AppColors.warning,
          sub: _config?.surgeEnabled == true ? 'Surge ON' : 'Surge OFF',
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.percent_rounded,
          label: 'Commission Plus',
          value: '+${_config?.commissionPlus.toStringAsFixed(0) ?? '0'}%',
          color: const Color(0xFF7C3AED),
          sub: 'On top of base',
        ),
      ],
    );
  }

  Widget _buildChargesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Order Charges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Packaging Charges',
            controller: _packagingCtrl,
            suffix: 'Rs.',
            hint: '10',
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Base Delivery Charge',
            controller: _deliveryCtrl,
            suffix: 'Rs.',
            hint: '20',
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Per KM Charge',
            controller: _perKmCtrl,
            suffix: 'Rs.',
            hint: '5',
          ),
          const Divider(height: 24),
          _buildInputField(
            label: 'Minimum Order Value',
            controller: _minOrderCtrl,
            suffix: 'Rs.',
            hint: '100',
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Small Order Fee',
            controller: _smallOrderFeeCtrl,
            suffix: 'Rs.',
            hint: '15',
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: const Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Commission Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Base commission is 10% for all restaurants. Commission Plus adds extra on top.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Commission Plus',
            controller: _commissionPlusCtrl,
            suffix: '%',
            hint: '2',
            helpText: 'Additional commission percentage',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7C3AED).withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: const Color(0xFF7C3AED), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total commission: ${(10 + (_config?.commissionPlus ?? 0)).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Surge Pricing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _config?.surgeEnabled ?? false,
                onChanged: (value) async {
                  if (_config != null) {
                    final updated = HikeChargesConfig(
                      id: _config!.id,
                      packagingCharges: _config!.packagingCharges,
                      deliveryCharges: _config!.deliveryCharges,
                      deliveryChargePerKm: _config!.deliveryChargePerKm,
                      hikeMultiplier: _config!.hikeMultiplier,
                      commissionPlus: _config!.commissionPlus,
                      minimumOrderValue: _config!.minimumOrderValue,
                      smallOrderFee: _config!.smallOrderFee,
                      surgeEnabled: value,
                      peakHoursStart: _config!.peakHoursStart,
                      peakHoursEnd: _config!.peakHoursEnd,
                      updatedAt: DateTime.now(),
                    );
                    await HikeChargesService.saveGlobalConfig(updated);
                  }
                },
                activeColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Hike Multiplier',
            controller: _hikeMultiplierCtrl,
            suffix: '%',
            hint: '10',
            helpText: 'Percentage increase during peak hours',
            enabled: _config?.surgeEnabled ?? false,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantOverridesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Restaurant-Specific Overrides',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Configure custom hike charges for specific restaurants. Restaurants without overrides will use global settings.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<RestaurantHikeOverride>>(
            stream: HikeChargesService.watchAllOverrides(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final overrides = snap.data!;
              if (overrides.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No restaurant overrides yet. Click Edit on any restaurant to set custom charges.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return _buildOverridesTable(overrides);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverridesTable(List<RestaurantHikeOverride> overrides) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Restaurant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Packaging', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Commission+', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
          ),
          ...overrides.map((override) => _buildOverrideRow(override)),
        ],
      ),
    );
  }

  Widget _buildOverrideRow(RestaurantHikeOverride override) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              override.restaurantId.substring(0, 8) + '...',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              override.useGlobalSettings || override.customPackagingCharges == null
                  ? 'Global'
                  : 'Rs.${override.customPackagingCharges!.toStringAsFixed(0)}',
              style: TextStyle(
                color: override.useGlobalSettings ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              override.useGlobalSettings || override.customDeliveryCharges == null
                  ? 'Global'
                  : 'Rs.${override.customDeliveryCharges!.toStringAsFixed(0)}',
              style: TextStyle(
                color: override.useGlobalSettings ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              override.useGlobalSettings || override.customCommissionPlus == null
                  ? 'Global'
                  : '+${override.customCommissionPlus!.toStringAsFixed(0)}%',
              style: TextStyle(
                color: override.useGlobalSettings ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: override.useGlobalSettings
                    ? AppColors.statusDeliveredBg
                    : AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                override.useGlobalSettings ? 'Global' : 'Custom',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: override.useGlobalSettings ? AppColors.statusDelivered : AppColors.warning,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required String hint,
    String? helpText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (helpText != null)
          Text(
            helpText,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: enabled ? AppColors.border : AppColors.border.withAlpha(100)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: !enabled,
            fillColor: enabled ? null : AppColors.border.withAlpha(50),
          ),
        ),
      ],
    );
  }
}

// ─── Summary Card Widget ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String sub;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
