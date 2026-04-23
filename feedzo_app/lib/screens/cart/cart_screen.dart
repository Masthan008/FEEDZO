import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/quantity_control.dart';
import '../../widgets/app_transitions.dart';
import '../../services/firestore_service.dart';
import '../../services/razorpay_service.dart';
import '../orders/order_tracking_screen.dart';

import '../profile/address_management_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _selectedAddress = 0;
  bool _orderPlaced = false;
  String _paymentType = 'cod'; // 'cod' or 'online'
  String? _placedOrderId; // Stores the orderId for navigation after overlay
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;

  @override
  void initState() {
    super.initState();
    // Calculate hike charges when cart screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartProvider>();
      if (cart.restaurantId != null && cart.items.isNotEmpty) {
        cart.calculateHikeCharges(distanceKm: 3.0);
      }
    });
  }

  Future<void> _placeOrder(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (auth.user == null) return;

    final addresses = auth.user!.savedAddresses;
    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a delivery address first'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    var order = Order(
      id: '',
      customerId: auth.user!.id,
      customerName: auth.user!.name,
      customerPhone: auth.user!.phone,
      restaurantId: cart.restaurantId!,
      restaurantName: cart.restaurantName!,
      restaurantImage: cart.restaurantImage!,
      items: List.from(cart.items),
      totalAmount: cart.total,
      address: addresses[_selectedAddress],
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
      paymentType: _paymentType,
      couponCode: cart.couponCode,
      discount: cart.discount,
      tipAmount: cart.tipAmount,
      deliveryFee: cart.deliveryFee,
      taxAmount: cart.taxAmount,
      deliveryInstructions: cart.deliveryInstructions,
      scheduledFor: cart.scheduledFor,
    );

    try {
      // If online payment, open Razorpay first
      if (_paymentType == 'online') {
        try {
          final paymentId = await RazorpayService.openCheckout(
            amount: cart.total,
            orderId: 'feedzo_${DateTime.now().millisecondsSinceEpoch}',
            customerName: auth.user!.name,
            customerEmail: auth.user!.email,
            customerPhone: auth.user!.phone,
          );
          order = order.copyWith(paymentId: paymentId, paymentStatus: 'paid');
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final orderId = await orderProvider.placeOrder(order);
      HapticFeedback.heavyImpact();

      // CRITICAL: Set _orderPlaced and store orderId BEFORE clearing cart.
      // cart.clear() triggers a rebuild via context.watch<CartProvider>.
      // If _orderPlaced isn't set first, the widget rebuilds to the
      // empty cart state instead of the success overlay.
      _placedOrderId = orderId;
      setState(() => _orderPlaced = true);

      // Now safe to clear cart — the overlay is already rendering
      cart.clear();

      await Future.delayed(const Duration(milliseconds: 1500));

      if (context.mounted && _placedOrderId != null) {
        Navigator.pushAndRemoveUntil(
          context,
          AppTransitions.fadeSlide(OrderTrackingScreen(orderId: _placedOrderId!)),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      // Reset state on error so user can retry
      setState(() {
        _orderPlaced = false;
        _placedOrderId = null;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final addresses = auth.user?.savedAddresses ?? [];

    // ── Order placed success overlay ──
    if (_orderPlaced) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Light blue, not green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2563EB), // Blue
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your food is being prepared',
                style: TextStyle(color: const Color(0xFF6B7280), fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Redirecting to order tracking...',
                style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFF2563EB), // Blue spinner
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Cart'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 56,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add items from a restaurant',
                style: TextStyle(color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Cart'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              cart.clear();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cart.restaurantImage ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.restaurantName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${cart.itemCount} items',
                          style: const TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cart items
            ...cart.items.map(
              (ci) => _CartItemRow(
                cartItem: ci,
                onAdd: () => context.read<CartProvider>().addItem(
                  ci.item,
                  cart.restaurantId!,
                  cart.restaurantName!,
                  cart.restaurantImage!,
                  cart.deliveryFee,
                  forceSwitch: true,
                ),
                onRemove: () =>
                    context.read<CartProvider>().removeItem(ci.item.id),
              ),
            ),
            const SizedBox(height: 16),
            // Address
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    AppTransitions.fadeSlide(const AddressManagementScreen()),
                  ),
                  child: const Text('Change/Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No addresses saved. Please add one.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...addresses.asMap().entries.map(
                (e) => _AddressTile(
                  address: e.value,
                  selected: _selectedAddress == e.key,
                  onTap: () => setState(() => _selectedAddress = e.key),
                ),
              ),
            const SizedBox(height: 16),

            // ── Delivery Instructions ─────────────────────
            _DeliveryInstructionsSection(cart: cart),
            const SizedBox(height: 12),

            // ── Schedule Order ─────────────────────────
            _ScheduleOrderSection(
              isScheduled: _isScheduled,
              scheduledDateTime: _scheduledDateTime,
              onToggle: (value) {
                setState(() {
                  _isScheduled = value;
                  if (!value) {
                    _scheduledDateTime = null;
                    cart.setScheduledFor(null);
                  }
                });
              },
              onDateTimeSelected: (dateTime) {
                setState(() {
                  _scheduledDateTime = dateTime;
                  cart.setScheduledFor(dateTime);
                });
              },
            ),
            const SizedBox(height: 12),

            // ── Tip for the Delivery Partner ──────────────
            _TipSection(cart: cart),
            const SizedBox(height: 12),

            // ── Coupon Code ───────────────────────────────
            _CouponSection(cart: cart),
            const SizedBox(height: 16),

            // Bill summary
            _BillSummary(cart: cart),
            const SizedBox(height: 16),
            // Payment method selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentType = 'cod'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _paymentType == 'cod'
                                  ? const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.1)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paymentType == 'cod'
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE5E7EB),
                                width: _paymentType == 'cod' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.money_rounded,
                                  color: _paymentType == 'cod'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF9CA3AF),
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cash on\nDelivery',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _paymentType == 'cod'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentType = 'online'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _paymentType == 'online'
                                  ? const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.1)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paymentType == 'online'
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE5E7EB),
                                width: _paymentType == 'online' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: _paymentType == 'online'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF9CA3AF),
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Online\nPayment',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _paymentType == 'online'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 86,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A000000),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: AppButton(
            label: _paymentType == 'cod'
                ? 'Place Order (COD) • ₹${cart.total.toStringAsFixed(0)}'
                : 'Pay Online • ₹${cart.total.toStringAsFixed(0)}',
            onPressed: () => _placeOrder(context),
            isLoading: orderProvider.isPlacing,
            width: double.infinity,
            useGradient: true,
          ),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemRow({
    required this.cartItem,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: cartItem.item.isVeg ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '₹${cartItem.item.discountedPrice.toInt()} each',
                  style: const TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          QuantityControl(
            quantity: cartItem.quantity,
            onAdd: onAdd,
            onRemove: onRemove,
            compact: true,
          ),
          const SizedBox(width: 12),
          Text(
            '₹${cartItem.total.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final String address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
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
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.location_on_rounded : Icons.location_on_outlined,
              color: selected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _BillSummary extends StatelessWidget {
  final CartProvider cart;
  const _BillSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _BillRow('Item Total', '₹${cart.subtotal.toStringAsFixed(0)}'),
          
          // Hike Charges Breakdown
          if (cart.hikeChargesLoaded && cart.totalHikeCharges > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cart.isSurgeActive 
                            ? 'Hike Charges (Surge Active +${cart.hikeMultiplier.toStringAsFixed(0)}%)'
                            : 'Hike Charges',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BillRow(
                    '  Packaging',
                    '₹${cart.packagingCharge.toStringAsFixed(0)}',
                    isIndented: true,
                  ),
                  _BillRow(
                    '  Delivery Fee',
                    '₹${cart.deliveryCharge.toStringAsFixed(0)}',
                    isIndented: true,
                  ),
                  if (cart.smallOrderFee > 0)
                    _BillRow(
                      '  Small Order Fee',
                      '₹${cart.smallOrderFee.toStringAsFixed(0)}',
                      isIndented: true,
                    ),
                  if (cart.surgeCharge > 0)
                    _BillRow(
                      '  Surge Charge',
                      '₹${cart.surgeCharge.toStringAsFixed(0)}',
                      isIndented: true,
                      highlight: true,
                    ),
                  const Divider(color: Color(0xFFFCD34D), height: 12),
                  _BillRow(
                    '  Total Hike',
                    '₹${cart.totalHikeCharges.toStringAsFixed(0)}',
                    isIndented: true,
                    bold: true,
                  ),
                ],
              ),
            ),
          ] else if (!cart.hikeChargesLoaded) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          _BillRow('Taxes & GST (5%)', '₹${cart.taxAmount.toStringAsFixed(0)}'),
          if (cart.discount > 0)
            _BillRow(
              'Coupon Discount',
              '-₹${cart.discount.toStringAsFixed(0)}',
              highlight: true,
            ),
          if (cart.tipAmount > 0)
            _BillRow('Delivery Tip', '₹${cart.tipAmount.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: const Color(0xFFE5E7EB)),
          ),
          _BillRow(
            'Grand Total',
            '₹${cart.total.toStringAsFixed(0)}',
            bold: true,
          ),
          if (cart.discount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: const Color(0xFF16A34A),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'You\'re saving ₹${cart.discount.toStringAsFixed(0)} on this order!',
                      style: const TextStyle(
                        color: const Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool highlight;
  final bool isIndented;

  const _BillRow(
    this.label,
    this.value, {
    this.bold = false,
    this.highlight = false,
    this.isIndented = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: isIndented ? 8 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? const Color(0xFF111827) : const Color(0xFF6B7280),
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              fontSize: bold ? 15 : (isIndented ? 13 : 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFF16A34A)
                  : bold
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF111827),
              fontWeight: bold || highlight ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 16 : (isIndented ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery Instructions ────────────────────────────────────────────────────
class _DeliveryInstructionsSection extends StatefulWidget {
  final CartProvider cart;
  const _DeliveryInstructionsSection({required this.cart});

  @override
  State<_DeliveryInstructionsSection> createState() =>
      _DeliveryInstructionsSectionState();
}

class _DeliveryInstructionsSectionState
    extends State<_DeliveryInstructionsSection> {
  bool _isExpanded = false;
  late TextEditingController _ctrl;

  final _quickOptions = [
    'Don\'t ring the bell',
    'Leave at door',
    'No cutlery, please',
    'Call before arriving',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.cart.deliveryInstructions ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: const Color(0xFF16A34A),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Delivery Instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                if (widget.cart.deliveryInstructions != null &&
                    widget.cart.deliveryInstructions!.isNotEmpty)
                  const Icon(
                    Icons.check_circle,
                    color: const Color(0xFF16A34A),
                    size: 18,
                  ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickOptions.map((opt) {
                final isSelected = widget.cart.deliveryInstructions == opt;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.cart.setDeliveryInstructions(
                      isSelected ? null : opt,
                    );
                    _ctrl.text = isSelected ? '' : opt;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              onChanged: (v) =>
                  widget.cart.setDeliveryInstructions(v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'Or type your own...',
                hintStyle: const TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tip Section ──────────────────────────────────────────────────────────────
class _TipSection extends StatelessWidget {
  final CartProvider cart;
  const _TipSection({required this.cart});

  @override
  Widget build(BuildContext context) {
    final tipOptions = [0.0, 20.0, 30.0, 50.0];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.pinkAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Tip your delivery partner',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your kindness means a lot! 100% goes to your partner.',
            style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: tipOptions.map((tip) {
              final isSelected = cart.tipAmount == tip;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cart.setTip(tip);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      tip == 0 ? 'None' : '₹${tip.toInt()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Coupon Section ───────────────────────────────────────────────────────────
class _CouponSection extends StatefulWidget {
  final CartProvider cart;
  const _CouponSection({required this.cart});

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  final _couponCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final result = await FirestoreService.validateCoupon(
      code,
      widget.cart.subtotal,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _errorMsg = 'Invalid or expired coupon code';
      });
    } else {
      widget.cart.applyCoupon(
        result['code'] as String,
        (result['discount'] as num).toDouble(),
      );
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon applied! You save ₹${(result['discount'] as num).toStringAsFixed(0)}',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasApplied = widget.cart.couponCode != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasApplied ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasApplied)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: const Color(0xFF16A34A),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.cart.couponCode!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '-₹${widget.cart.discount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    widget.cart.removeCoupon();
                    _couponCtrl.clear();
                    setState(() => _errorMsg = null);
                  },
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _couponCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: const TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      errorText: _errorMsg,
                      errorStyle: const TextStyle(fontSize: 11),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                    onSubmitted: (_) => _applyCoupon(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : _applyCoupon,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'APPLY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Schedule Order Section ───────────────────────────────────────────────────
class _ScheduleOrderSection extends StatefulWidget {
  final bool isScheduled;
  final DateTime? scheduledDateTime;
  final Function(bool) onToggle;
  final Function(DateTime) onDateTimeSelected;

  const _ScheduleOrderSection({
    required this.isScheduled,
    required this.scheduledDateTime,
    required this.onToggle,
    required this.onDateTimeSelected,
  });

  @override
  State<_ScheduleOrderSection> createState() => _ScheduleOrderSectionState();
}

class _ScheduleOrderSectionState extends State<_ScheduleOrderSection> {
  bool _isExpanded = false;

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.scheduledDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          widget.scheduledDateTime ?? now.add(const Duration(hours: 1)),
        ),
      );

      if (selectedTime != null) {
        final scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Ensure scheduled time is at least 1 hour in the future
        if (scheduledDateTime.isBefore(now.add(const Duration(hours: 1)))) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please schedule at least 1 hour in advance'),
              ),
            );
          }
          return;
        }

        widget.onDateTimeSelected(scheduledDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 22,
                  color: widget.isScheduled ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Schedule Order',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                Switch(
                  value: widget.isScheduled,
                  onChanged: widget.onToggle,
                  activeColor: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
          if (_isExpanded && widget.isScheduled) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDateTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    Text(
                      widget.scheduledDateTime != null
                          ? '${widget.scheduledDateTime!.day}/${widget.scheduledDateTime!.month}/${widget.scheduledDateTime!.year} at ${widget.scheduledDateTime!.hour}:${widget.scheduledDateTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select date and time',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
