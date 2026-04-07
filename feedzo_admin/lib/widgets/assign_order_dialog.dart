import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../services/driver_assignment_service.dart';
import '../providers/admin_provider.dart';

/// Dialog for admin to assign orders to drivers including busy drivers
class AssignOrderDialog extends StatefulWidget {
  final AdminOrder order;
  
  const AssignOrderDialog({
    super.key,
    required this.order,
  });

  @override
  State<AssignOrderDialog> createState() => _AssignOrderDialogState();
}

class _AssignOrderDialogState extends State<AssignOrderDialog> {
  final DriverAssignmentService _assignmentService = DriverAssignmentService();
  String? _selectedDriverId;
  bool _isAssigning = false;
  bool _showAllDrivers = false;

  @override
  Widget build(BuildContext context) {
    final adminId = context.read<AdminProvider>().adminId ?? 'unknown';
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Order to Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Order #${widget.order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Order summary
            _buildOrderSummary(),
            
            const SizedBox(height: 24),
            
            // Toggle for showing all drivers
            Row(
              children: [
                Checkbox(
                  value: _showAllDrivers,
                  onChanged: (v) => setState(() => _showAllDrivers = v ?? false),
                  activeColor: AppColors.primary,
                ),
                const Expanded(
                  child: Text(
                    'Show all drivers (including busy)',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Driver list
            Expanded(
              child: StreamBuilder<List<Driver>>(
                stream: _showAllDrivers 
                    ? _assignmentService.getAvailableDrivers()
                    : _assignmentService.getMultiOrderCapableDrivers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final drivers = snapshot.data ?? [];
                  
                  if (drivers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_rounded,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showAllDrivers 
                                ? 'No available drivers'
                                : 'No drivers available for multi-order',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (!_showAllDrivers) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() => _showAllDrivers = true),
                              child: const Text('Show all drivers'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      final isSelected = _selectedDriverId == driver.id;
                      final canAcceptMore = driver.canAcceptMoreOrders;
                      
                      return _buildDriverTile(
                        driver: driver,
                        isSelected: isSelected,
                        canAcceptMore: canAcceptMore,
                        onTap: canAcceptMore 
                            ? () => setState(() => _selectedDriverId = driver.id)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedDriverId == null || _isAssigning
                        ? null
                        : () => _assignOrder(adminId),
                    icon: _isAssigning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_ind_rounded),
                    label: Text(_isAssigning ? 'Assigning...' : 'Assign Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.order.restaurantName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.order.items.length} items • ₹${widget.order.orderValue.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          if (widget.order.assignedDriverId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Reassign from: ${widget.order.assignedDriverName ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
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

  Widget _buildDriverTile({
    required Driver driver,
    required bool isSelected,
    required bool canAcceptMore,
    VoidCallback? onTap,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (driver.status) {
      case DriverStatus.available:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Available';
        break;
      case DriverStatus.busy:
        statusColor = AppColors.warning;
        statusIcon = Icons.local_shipping_rounded;
        statusText = 'Busy (${driver.activeOrderCount} orders)';
        break;
      case DriverStatus.multiOrder:
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = Icons.stacked_line_chart_rounded;
        statusText = 'Multi-Order (${driver.activeOrderCount})';
        break;
      case DriverStatus.offline:
        statusColor = AppColors.textHint;
        statusIcon = Icons.offline_bolt_rounded;
        statusText = 'Offline';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected 
              ? AppColors.primary 
              : canAcceptMore 
                  ? Colors.transparent 
                  : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Radio button
              Radio<String>(
                value: driver.id,
                groupValue: _selectedDriverId,
                onChanged: canAcceptMore 
                    ? (v) => setState(() => _selectedDriverId = v)
                    : null,
                activeColor: AppColors.primary,
              ),
              
              // Driver avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: canAcceptMore 
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.textHint.withValues(alpha: 0.1),
                child: Text(
                  driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: canAcceptMore ? AppColors.primary : AppColors.textHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: canAcceptMore ? null : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver.vehicle} • ${driver.totalDeliveries} deliveries',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignOrder(String adminId) async {
    if (_selectedDriverId == null) return;
    
    setState(() => _isAssigning = true);
    HapticFeedback.mediumImpact();
    
    try {
      // Get selected driver details
      final driverDoc = await _assignmentService.getDriverDoc(_selectedDriverId!);
      final driverName = driverDoc?.data()?['name'] ?? 'Driver';
      
      await _assignmentService.assignOrderToDriver(
        orderId: widget.order.id,
        driverId: _selectedDriverId!,
        driverName: driverName,
        assignedBy: adminId,
        isAdminOverride: widget.order.assignedDriverId != null,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order assigned to $driverName'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Extension method to get driver document
extension on DriverAssignmentService {
  Future<DocumentSnapshot?> getDriverDoc(String driverId) async {
    try {
      return await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
    } catch (e) {
      return null;
    }
  }
}
