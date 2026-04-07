import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hike_charges_provider.dart';

class HikeChargesScreen extends StatefulWidget {
  const HikeChargesScreen({super.key});

  @override
  State<HikeChargesScreen> createState() => _HikeChargesScreenState();
}

class _HikeChargesScreenState extends State<HikeChargesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<HikeChargesProvider>().init(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Hike Charges & Commission',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<HikeChargesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.error ?? 'Something went wrong',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final values = provider.getDisplayValues();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                _buildInfoCard(),
                const SizedBox(height: 20),

                // Commission Summary
                _buildCommissionCard(values),
                const SizedBox(height: 16),

                // Charges Breakdown
                _buildChargesCard(values),
                const SizedBox(height: 16),

                // Surge Pricing Info
                _buildSurgeCard(values),
                const SizedBox(height: 16),

                // Example Calculation
                _buildExampleCard(values),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
              Icons.info_outline_rounded,
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
                  'Understanding Your Charges',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'These are the charges applied to your orders. Commission is deducted from your earnings.',
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

  Widget _buildCommissionCard(Map<String, dynamic> values) {
    final commissionPlus = values['commissionPlus'] as double;
    final totalRate = values['totalCommissionRate'] as double;
    final hasCustom = values['hasCustomSettings'] as bool;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Commission Structure',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasCustom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCommissionRow(
            label: 'Base Commission',
            value: '10%',
            isBase: true,
          ),
          if (commissionPlus > 0) ...[
            const SizedBox(height: 8),
            _buildCommissionRow(
              label: 'Commission Plus',
              value: '+${commissionPlus.toStringAsFixed(0)}%',
              isHighlight: true,
            ),
          ],
          const Divider(height: 24),
          _buildCommissionRow(
            label: 'Total Commission Rate',
            value: '${totalRate.toStringAsFixed(0)}%',
            isTotal: true,
          ),
          const SizedBox(height: 12),
          Text(
            'You earn ${(100 - totalRate).toStringAsFixed(0)}% of each order value',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesCard(Map<String, dynamic> values) {
    final packaging = values['packagingCharges'] as double;
    final delivery = values['deliveryCharges'] as double;
    final perKm = values['deliveryChargePerKm'] as double;
    final minOrder = values['minimumOrderValue'] as double;
    final smallOrderFee = values['smallOrderFee'] as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Charges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildChargeRow(
            icon: Icons.inventory_2_outlined,
            label: 'Packaging Charges',
            value: 'Rs.${packaging.toStringAsFixed(0)}',
            per: 'per order',
          ),
          const SizedBox(height: 12),
          _buildChargeRow(
            icon: Icons.local_shipping_outlined,
            label: 'Base Delivery',
            value: 'Rs.${delivery.toStringAsFixed(0)}',
            per: 'per order',
          ),
          const SizedBox(height: 12),
          _buildChargeRow(
            icon: Icons.route_outlined,
            label: 'Distance Charge',
            value: 'Rs.${perKm.toStringAsFixed(0)}',
            per: 'per km',
          ),
          if (minOrder > 0) ...[
            const Divider(height: 24),
            _buildChargeRow(
              icon: Icons.shopping_bag_outlined,
              label: 'Minimum Order Value',
              value: 'Rs.${minOrder.toStringAsFixed(0)}',
              per: 'to avoid small order fee',
            ),
            const SizedBox(height: 12),
            _buildChargeRow(
              icon: Icons.warning_amber_outlined,
              label: 'Small Order Fee',
              value: 'Rs.${smallOrderFee.toStringAsFixed(0)}',
              per: 'if below minimum',
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSurgeCard(Map<String, dynamic> values) {
    final enabled = values['surgeEnabled'] as bool;
    final multiplier = values['hikeMultiplier'] as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: enabled ? AppColors.warning : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surge Pricing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? 'Currently Active' : 'Currently Inactive',
                      style: TextStyle(
                        fontSize: 13,
                        color: enabled ? AppColors.warning : AppColors.textSecondary,
                        fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.statusDeliveredBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  enabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: enabled ? AppColors.warning : AppColors.statusDelivered,
                  ),
                ),
              ),
            ],
          ),
          if (enabled && multiplier > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hike Multiplier: ${multiplier.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Applied during peak hours',
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleCard(Map<String, dynamic> values) {
    final packaging = values['packagingCharges'] as double;
    final delivery = values['deliveryCharges'] as double;
    final perKm = values['deliveryChargePerKm'] as double;
    final totalRate = values['totalCommissionRate'] as double;

    // Example: Rs. 200 order, 3km distance
    const exampleOrderValue = 200.0;
    const exampleDistance = 3.0;
    
    final deliveryCharge = delivery + (perKm * exampleDistance);
    final totalCharges = packaging + deliveryCharge;
    final commission = exampleOrderValue * (totalRate / 100);
    final restaurantEarnings = exampleOrderValue - commission;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Example Calculation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'For an order of Rs.$exampleOrderValueValue with ${exampleDistance}km delivery:',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildCalcRow('Order Value', 'Rs.${exampleOrderValue.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildCalcRow('Packaging', '+ Rs.${packaging.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildCalcRow('Delivery (${exampleDistance}km)', '+ Rs.${deliveryCharge.toStringAsFixed(0)}'),
                const Divider(height: 16),
                _buildCalcRow(
                  'Customer Pays',
                  'Rs.${(exampleOrderValue + totalCharges).toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 12),
                _buildCalcRow(
                  'Your Commission (${totalRate.toStringAsFixed(0)}%)',
                  '- Rs.${commission.toStringAsFixed(0)}',
                  isNegative: true,
                ),
                const Divider(height: 16),
                _buildCalcRow(
                  'You Earn',
                  'Rs.${restaurantEarnings.toStringAsFixed(0)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionRow({
    required String label,
    required String value,
    bool isBase = false,
    bool isHighlight = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isHighlight
                ? const Color(0xFF7C3AED)
                : isTotal
                    ? AppColors.primary
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChargeRow({
    required IconData icon,
    required String label,
    required String value,
    required String per,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isWarning
                ? AppColors.error.withOpacity(0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isWarning ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                per,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isWarning ? AppColors.error : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalcRow(
    String label,
    String value, {
    bool isBold = false,
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight.w600,
            color: isNegative
                ? AppColors.error
                : isTotal
                    ? AppColors.statusDelivered
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Fix for undefined variable
const double exampleOrderValueValue = 200.0;
