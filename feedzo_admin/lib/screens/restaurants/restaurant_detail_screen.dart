import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/restaurant_admin_service.dart';
import '../../widgets/topbar.dart';
import 'menu_management_screen.dart';
import 'restaurant_form_dialog.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final RestaurantAdminService _service = RestaurantAdminService();
  bool _isLoading = false;

  Future<void> _toggleOpenClose(AdminRestaurant restaurant) async {
    final success = await _service.toggleOpenClose(
      widget.restaurantId,
      !restaurant.isOpen,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restaurant is now ${!restaurant.isOpen ? 'Open' : 'Closed'}'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
    }
  }

  Future<void> _releasePayout(double amount) async {
    if (amount <= 0) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Payout'),
        content: Text('Release ₹${amount.toStringAsFixed(0)} to this restaurant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _service.releasePayout(widget.restaurantId, amount);
      setState(() => _isLoading = false);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout released successfully'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  Future<void> _approveRestaurant() async {
    setState(() => _isLoading = true);
    final success = await _service.approveRestaurant(widget.restaurantId);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant approved successfully'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
    }
  }

  Future<void> _rejectRestaurant() async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Restaurant'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isLoading = true);
      final success = await _service.rejectRestaurant(widget.restaurantId, reason);
      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteRestaurant(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _service.deleteRestaurant(widget.restaurantId);
      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant deleted successfully'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  Future<void> _editRestaurant(AdminRestaurant restaurant) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => RestaurantFormDialog(existingRestaurant: restaurant),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurantId)
            .update({
          'name': result['name'],
          'email': result['email'],
          'phone': result['phone'],
          'cuisine': result['cuisine'],
          'address': result['address'],
          'commission': result['commissionRate'] ?? 10.0,
          'fssaiNumber': result['fssaiNumber'],
          'gstNumber': result['gstNumber'],
          'panNumber': result['panNumber'],
          'isApproved': result['isApproved'] ?? restaurant.isApproved,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Also update user record if email changed
        if (result['email'] != restaurant.email) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.restaurantId)
              .update({'email': result['email']});
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant updated successfully'),
              backgroundColor: AppColors.statusDelivered,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating restaurant: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error loading restaurant: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Restaurant not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('ID: ${widget.restaurantId}', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final restaurant = AdminRestaurant.fromMap(doc.id, doc.data() as Map<String, dynamic>);

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editRestaurant(restaurant),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () => _deleteRestaurant(restaurant.name),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              restaurant.name.isNotEmpty ? restaurant.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          restaurant.cuisine,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      _buildStatusCard(restaurant),
                      const SizedBox(height: 24),

                      // Approval Actions (if pending)
                      if (!restaurant.isApproved) ...[
                        _buildApprovalActions(),
                        const SizedBox(height: 24),
                      ],

                      // Stats Grid
                      _buildStatsGrid(restaurant),
                      const SizedBox(height: 24),

                      // Contact Information
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _InfoRow(Icons.email_outlined, 'Email', restaurant.email),
                        _InfoRow(Icons.phone_outlined, 'Phone', restaurant.phone),
                        _InfoRow(Icons.location_on_outlined, 'Address', restaurant.location),
                      ]),
                      const SizedBox(height: 24),

                      // Business Details
                      _buildSectionTitle('Business Details'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _InfoRow(Icons.confirmation_number_outlined, 'FSSAI', restaurant.fssaiNumber ?? 'Not provided'),
                        _InfoRow(Icons.receipt_outlined, 'GST Number', restaurant.gstNumber ?? 'Not provided'),
                        _InfoRow(Icons.credit_card_outlined, 'PAN Number', restaurant.panNumber ?? 'Not provided'),
                        _InfoRow(Icons.percent, 'Commission', '${restaurant.commissionRate.toStringAsFixed(0)}%'),
                      ]),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 12),
                      _buildQuickActions(restaurant),
                      const SizedBox(height: 24),

                      // Menu Management Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MenuManagementScreen(
                                restaurantId: widget.restaurantId,
                                restaurantName: restaurant.name,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Manage Menu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AdminRestaurant restaurant) {
    final isApproved = restaurant.isApproved;
    final isOpen = restaurant.isOpen;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isApproved) {
      statusColor = AppColors.warning;
      statusText = 'Pending Approval';
      statusIcon = Icons.pending_actions;
    } else if (isOpen) {
      statusColor = AppColors.statusDelivered;
      statusText = 'Open for Business';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppColors.textSecondary;
      statusText = 'Currently Closed';
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (isApproved) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tap to toggle open/close status',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor.withAlpha(180),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isApproved)
            Switch(
              value: isOpen,
              onChanged: (_) => _toggleOpenClose(restaurant),
              activeColor: statusColor,
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Approval Required'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _approveRestaurant,
                icon: const Icon(Icons.check_circle),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusDelivered,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _rejectRestaurant,
                icon: const Icon(Icons.cancel),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AdminRestaurant restaurant) {
    return Row(
      children: [
        _buildStatCard(
          'Total Orders',
          restaurant.totalOrders.toString(),
          Icons.receipt_long,
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Revenue',
          '₹${(restaurant.totalRevenue / 1000).toStringAsFixed(1)}K',
          Icons.account_balance_wallet,
          AppColors.statusDelivered,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Wallet',
          '₹${restaurant.walletBalance.toStringAsFixed(0)}',
          Icons.wallet,
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(entry.value.icon, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions(AdminRestaurant restaurant) {
    return Row(
      children: [
        if (restaurant.walletBalance > 0)
          Expanded(
            child: _QuickActionBtn(
              icon: Icons.payments,
              label: 'Release ₹${restaurant.walletBalance.toStringAsFixed(0)}',
              color: AppColors.statusDelivered,
              onTap: () => _releasePayout(restaurant.walletBalance),
            ),
          ),
      ],
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  _InfoRow(this.icon, this.label, this.value);
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
