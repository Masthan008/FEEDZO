import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class CsvImportExportScreen extends StatefulWidget {
  const CsvImportExportScreen({super.key});

  @override
  State<CsvImportExportScreen> createState() => _CsvImportExportScreenState();
}

class _CsvImportExportScreenState extends State<CsvImportExportScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _selectedExportType;
  String? _importStatus;

  final List<String> _exportTypes = [
    'Orders',
    'Users',
    'Restaurants',
    'Drivers',
    'Coupons',
    'Reviews',
  ];

  Future<void> _exportData(String type) async {
    setState(() {
      _isExporting = true;
      _selectedExportType = type;
    });

    try {
      List<List<dynamic>> csvData = [];
      String fileName = '';

      switch (type) {
        case 'Orders':
          final snapshot = await FirebaseFirestore.instance.collection('orders').get();
          csvData = [
            ['Order ID', 'Restaurant ID', 'Customer ID', 'Driver ID', 'Status', 'Total Amount', 'Payment Method', 'Created At']
          ];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            csvData.add([
              doc.id,
              data['restaurantId'] ?? '',
              data['customerId'] ?? '',
              data['driverId'] ?? '',
              data['status'] ?? '',
              data['totalAmount'] ?? 0,
              data['paymentMethod'] ?? '',
              (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '',
            ]);
          }
          fileName = 'orders_export';
          break;

        case 'Users':
          final snapshot = await FirebaseFirestore.instance.collection('users').get();
          csvData = [
            ['User ID', 'Name', 'Email', 'Phone', 'Role', 'Created At']
          ];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            csvData.add([
              doc.id,
              data['name'] ?? '',
              data['email'] ?? '',
              data['phone'] ?? '',
              data['role'] ?? '',
              (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '',
            ]);
          }
          fileName = 'users_export';
          break;

        case 'Restaurants':
          final snapshot = await FirebaseFirestore.instance.collection('users')
              .where('role', isEqualTo: 'restaurant').get();
          csvData = [
            ['Restaurant ID', 'Name', 'Email', 'Phone', 'Address', 'Status', 'Created At']
          ];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            csvData.add([
              doc.id,
              data['name'] ?? '',
              data['email'] ?? '',
              data['phone'] ?? '',
              data['address'] ?? '',
              data['status'] ?? '',
              (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '',
            ]);
          }
          fileName = 'restaurants_export';
          break;

        case 'Drivers':
          final snapshot = await FirebaseFirestore.instance.collection('users')
              .where('role', isEqualTo: 'driver').get();
          csvData = [
            ['Driver ID', 'Name', 'Email', 'Phone', 'Vehicle', 'Status', 'Created At']
          ];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            csvData.add([
              doc.id,
              data['name'] ?? '',
              data['email'] ?? '',
              data['phone'] ?? '',
              data['vehicle'] ?? '',
              data['status'] ?? '',
              (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '',
            ]);
          }
          fileName = 'drivers_export';
          break;

        case 'Coupons':
          final snapshot = await FirebaseFirestore.instance.collection('coupons').get();
          csvData = [
            ['Coupon ID', 'Code', 'Discount Type', 'Discount Value', 'Min Order', 'Max Discount', 'Usage Limit', 'Active', 'Expiry Date']
          ];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            csvData.add([
              doc.id,
              data['code'] ?? '',
              data['discountType'] ?? '',
              data['discountValue'] ?? 0,
              data['minOrder'] ?? 0,
              data['maxDiscount'] ?? 0,
              data['usageLimit'] ?? 0,
              data['isActive'] ?? false,
              (data['expiryDate'] as Timestamp?)?.toDate().toString() ?? '',
            ]);
          }
          fileName = 'coupons_export';
          break;

        case 'Reviews':
          final snapshot = await FirebaseFirestore.instance.collection('reviews').get();
          csvData = [
            ['Review ID', 'Restaurant ID', 'Customer Name', 'Rating', 'Comment', 'Created At']
          ];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            csvData.add([
              doc.id,
              data['restaurantId'] ?? '',
              data['customerName'] ?? '',
              data['rating'] ?? 0,
              data['comment'] ?? '',
              (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '',
            ]);
          }
          fileName = 'reviews_export';
          break;
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      
      // Use file picker to save the file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: '$fileName.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(csvString);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$type exported successfully to $result'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _selectedExportType = null;
        });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
      _importStatus = 'Selecting file...';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
          _importStatus = null;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvString);

      setState(() {
        _importStatus = 'Processing ${rows.length} rows...';
      });

      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        
        // Determine collection based on data structure
        // This is a simplified implementation - in production, you'd need proper mapping
        if (row.length >= 6) {
          // Try to determine the collection type based on the first row
          if (i == 1) {
            setState(() {
              _importStatus = 'Detecting data type...';
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV import is a complex operation. Please use the admin API for bulk imports.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'CSV Import/Export', subtitle: 'Import and export data in CSV format'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Export Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.download, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Download data as CSV files', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Select data type to export:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        ..._exportTypes.map((type) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ExportButton(
                            type: type,
                            isLoading: _isExporting && _selectedExportType == type,
                            onTap: () => _exportData(type),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Import Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.upload_file, color: Colors.orange, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Import Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Upload CSV files to import data', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              const Text(
                                'Upload CSV File',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Supported format: .csv',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 20),
                              if (_importStatus != null) ...[
                                LinearProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(_importStatus!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(height: 16),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isImporting ? null : _importData,
                                  icon: const Icon(Icons.upload),
                                  label: Text(_isImporting ? 'Importing...' : 'Select File'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'For bulk imports, use the admin API endpoint. CSV import requires proper data validation and mapping.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String type;
  final bool isLoading;
  final VoidCallback onTap;

  const _ExportButton({
    required this.type,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.file_download_outlined, size: 18),
        label: Text(isLoading ? 'Exporting $type...' : type),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: isLoading ? AppColors.textHint : null,
        ),
      ),
    );
  }
}
