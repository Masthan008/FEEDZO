import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/customer_detail_model.dart';
import '../services/customer_service.dart';
import '../widgets/topbar.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  CustomerDetail? _customer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    try {
      final customer = await CustomerService.getCustomerDetail(widget.customerId);
      if (mounted) {
        setState(() {
          _customer = customer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load customer: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Customer Details',
          subtitle: _customer != null ? _customer!.name : 'Loading...',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCustomer,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _customer == null
                      ? const Center(child: Text('Customer not found'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Header
                              _buildProfileHeader(),
                              const SizedBox(height: 24),
                              
                              // Statistics Cards
                              _buildStatsSection(),
                              const SizedBox(height: 24),
                              
                              // Active Order (if any)
                              if (_customer!.activeOrder != null) ...[
                                _buildActiveOrderSection(),
                                const SizedBox(height: 24),
                              ],
                              
                              // Order History
                              _buildOrderHistorySection(),
                              const SizedBox(height: 24),
                              
                              // Saved Addresses
                              _buildAddressesSection(),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Photo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withAlpha(50), width: 3),
            ),
            child: _customer!.photoUrl != null && _customer!.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _customer!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                    ),
                  )
                : _buildInitialsAvatar(),
          ),
          const SizedBox(width: 24),
          
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _customer!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _customer!.status == 'active' 
                            ? AppColors.statusDeliveredBg 
                            : AppColors.error.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _customer!.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _customer!.status == 'active' 
                              ? AppColors.statusDelivered 
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email_outlined, _customer!.email),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, _customer!.phone),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today_outlined, 
                  'Joined ${_formatDate(_customer!.joinedAt)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _customer!.name.isNotEmpty ? _customer!.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _StatCard(
          icon: Icons.receipt_long_rounded,
          label: 'Total Orders',
          value: '${_customer!.totalOrders}',
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.currency_rupee_rounded,
          label: 'Total Spent',
          value: '₹${_customer!.totalSpent.toStringAsFixed(0)}',
          color: AppColors.statusDelivered,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.trending_up_rounded,
          label: 'Avg. Order',
          value: '₹${_customer!.averageOrderValue.toStringAsFixed(0)}',
          color: AppColors.info,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.favorite_border_rounded,
          label: 'Favorite',
          value: _customer!.favoriteRestaurant ?? 'N/A',
          color: AppColors.warning,
          isSmallText: true,
        ),
      ],
    );
  }

  Widget _buildActiveOrderSection() {
    final order = _customer!.activeOrder!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(20), AppColors.primary.withAlpha(5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE ORDER - TRACKING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Order is currently active',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusPendingBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusPending,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          
          // Order Details
          Row(
            children: [
              Expanded(
                child: _buildOrderDetailColumn(
                  'Restaurant',
                  order.restaurantName,
                  Icons.store_rounded,
                ),
              ),
              Expanded(
                child: _buildOrderDetailColumn(
                  'Order ID',
                  '#${order.orderId.substring(order.orderId.length - 6).toUpperCase()}',
                  Icons.receipt_rounded,
                ),
              ),
              Expanded(
                child: _buildOrderDetailColumn(
                  'Amount',
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Items
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items Ordered:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.isVeg ? Icons.circle : Icons.circle,
                        size: 10,
                        color: item.isVeg ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.name}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '₹${item.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          if (order.deliveryAddress != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryAddress!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (order.driverName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusDeliveredBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.statusDelivered, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Driver:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusDelivered,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.driverName}${order.driverPhone != null ? ' • ${order.driverPhone}' : ''}',
                          style: const TextStyle(fontSize: 13),
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

  Widget _buildOrderDetailColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildOrderHistorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_customer!.recentOrders.isNotEmpty)
                Text(
                  '${_customer!.recentOrders.length} orders',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_customer!.recentOrders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No orders yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._customer!.recentOrders.map((order) => _buildOrderHistoryItem(order)),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryItem(CustomerOrderSummary order) {
    Color statusColor;
    Color statusBg;
    
    switch (order.status) {
      case 'delivered':
        statusColor = AppColors.statusDelivered;
        statusBg = AppColors.statusDeliveredBg;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusBg = AppColors.error.withAlpha(30);
        break;
      default:
        statusColor = AppColors.statusPending;
        statusBg = AppColors.statusPendingBg;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: order.restaurantImage != null && order.restaurantImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          order.restaurantImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.store, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} items • ${_formatDateTime(order.orderedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  item.isVeg ? Icons.circle : Icons.circle,
                  size: 8,
                  color: item.isVeg ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (order.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${order.items.length - 3} more items',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (order.deliveryAddress != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved Addresses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_customer!.savedAddresses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No saved addresses',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._customer!.savedAddresses.asMap().entries.map((entry) {
              final index = entry.key;
              final address = entry.value;
              final isDefault = index == 0; // Assuming first is default
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDefault ? AppColors.primary : AppColors.border,
                    width: isDefault ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDefault ? AppColors.primarySurface : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: isDefault ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDefault)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Text(
                            address,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} at $hour:$minute';
  }
}

// ─── Stat Card Widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isSmallText;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isSmallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallText ? 14 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withAlpha(180),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
