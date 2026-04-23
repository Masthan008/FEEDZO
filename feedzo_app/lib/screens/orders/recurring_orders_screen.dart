import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recurring_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/recurring_order_service.dart';
import 'package:provider/provider.dart';

class RecurringOrdersScreen extends StatefulWidget {
  const RecurringOrdersScreen({super.key});

  @override
  State<RecurringOrdersScreen> createState() => _RecurringOrdersScreenState();
}

class _RecurringOrdersScreenState extends State<RecurringOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Orders'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recurringOrders')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.docs;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No recurring orders',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up automatic repeat orders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = RecurringOrderModel.fromFirestore(orders[index]);
              return _buildOrderCard(order);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrderCard(RecurringOrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.autorenew, color: Colors.purple.shade700),
        ),
        title: Text(order.restaurantName),
        subtitle: Text('${_getFrequencyText(order.frequency)} • ${order.preferredTime}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _getDaysText(order),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }

  String _getDaysText(RecurringOrderModel order) {
    switch (order.frequency) {
      case 'weekly':
        if (order.daysOfWeek.isEmpty) return 'Every day';
        final days = order.daysOfWeek.map((d) => _getDayName(d)).join(', ');
        return days;
      case 'monthly':
        return 'Day ${order.dayOfMonth}';
      default:
        return '';
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  void _showCreateDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => _CreateRecurringOrderDialog(userId: userId),
    );
  }
}

class _CreateRecurringOrderDialog extends StatefulWidget {
  final String userId;
  const _CreateRecurringOrderDialog({required this.userId});

  @override
  State<_CreateRecurringOrderDialog> createState() => _CreateRecurringOrderDialogState();
}

class _CreateRecurringOrderDialogState extends State<_CreateRecurringOrderDialog> {
  String _frequency = 'weekly';
  final List<int> _selectedDays = [1, 2, 3, 4, 5];
  TimeOfDay _preferredTime = const TimeOfDay(hour: 12, minute: 0);
  int _dayOfMonth = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Recurring Order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                setState(() {
                  _frequency = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_frequency == 'weekly') ...[
              const Text('Select Days', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(_getDayName(day)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            if (_frequency == 'monthly') ...[
              const Text('Day of Month', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _dayOfMonth,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: List.generate(28, (index) {
                  final day = index + 1;
                  return DropdownMenuItem(value: day, child: Text('Day $day'));
                }),
                onChanged: (value) {
                  setState(() {
                    _dayOfMonth = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            const Text('Preferred Time', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              title: Text(_preferredTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _preferredTime,
                );
                if (time != null) {
                  setState(() {
                    _preferredTime = time;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createRecurringOrder,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createRecurringOrder() async {
    final cart = context.read<CartProvider>();
    
    if (cart.restaurantId == null || cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to cart first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Calculate next order date
      final now = DateTime.now();
      DateTime nextOrderDate = DateTime(
        now.year,
        now.month,
        now.day,
        _preferredTime.hour,
        _preferredTime.minute,
      );

      // Ensure next order date is in the future
      if (nextOrderDate.isBefore(now)) {
        nextOrderDate = nextOrderDate.add(const Duration(days: 1));
      }

      // Adjust for weekly/monthly
      if (_frequency == 'weekly' && _selectedDays.isNotEmpty) {
        final currentDay = now.weekday;
        final nextDay = _selectedDays.firstWhere(
          (d) => d >= currentDay,
          orElse: () => _selectedDays.first + 7,
        );
        final daysToAdd = nextDay - currentDay;
        nextOrderDate = nextOrderDate.add(Duration(days: daysToAdd));
      } else if (_frequency == 'monthly') {
        final currentDay = now.day;
        if (_dayOfMonth < currentDay) {
          nextOrderDate = DateTime(
            now.year,
            now.month + 1,
            _dayOfMonth,
            _preferredTime.hour,
            _preferredTime.minute,
          );
        } else {
          nextOrderDate = DateTime(
            now.year,
            now.month,
            _dayOfMonth,
            _preferredTime.hour,
            _preferredTime.minute,
          );
        }
      }

      await RecurringOrderService.createRecurringOrder(
        userId: widget.userId,
        restaurantId: cart.restaurantId!,
        restaurantName: cart.restaurantName!,
        items: cart.items.map((item) => item.toMap()).toList(),
        totalAmount: cart.total,
        frequency: _frequency,
        startDate: nextOrderDate,
        deliveryAddress: user.savedAddresses.isNotEmpty ? user.savedAddresses.first : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring order created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
