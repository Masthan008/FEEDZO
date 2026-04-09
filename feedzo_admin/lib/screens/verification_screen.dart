import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/verification_model.dart';
import '../services/verification_service.dart';
import '../widgets/topbar.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Customer Verification', subtitle: 'Manage customer identity verifications'),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text('Filter by status: '),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<VerificationModel>>(
            stream: _selectedStatus == 'all'
                ? VerificationService.watchAllVerifications()
                : _selectedStatus == 'pending'
                    ? VerificationService.watchPendingVerifications()
                    : VerificationService.watchAllVerifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final verifications = snapshot.data ?? [];

              if (verifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No verification requests', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final filtered = _selectedStatus == 'all'
                  ? verifications
                  : verifications.where((v) => v.status == _selectedStatus).toList();

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filtered.map((v) {
                    return DataRow(
                      cells: [
                        DataCell(Text(v.customerName)),
                        DataCell(Text(v.customerPhone)),
                        DataCell(Text(v.verificationType.toUpperCase())),
                        DataCell(_buildStatusChip(v.status)),
                        DataCell(Text(
                          DateFormat('MMM dd, yyyy').format(v.createdAt),
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          Row(
                            children: [
                              if (v.status == 'pending') ...[
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  onPressed: () => _approveVerification(v),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                  onPressed: () => _rejectVerification(v),
                                  tooltip: 'Reject',
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey, size: 18),
                                onPressed: () async {
                                  await VerificationService.deleteVerification(v.id);
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _approveVerification(VerificationModel verification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Verification'),
        content: Text('Approve verification for ${verification.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await VerificationService.approveVerification(verification.id, 'admin');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification approved'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectVerification(VerificationModel verification) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject verification for ${verification.customerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason')),
                );
                return;
              }
              await VerificationService.rejectVerification(
                verification.id,
                reasonController.text,
                'admin',
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification rejected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
