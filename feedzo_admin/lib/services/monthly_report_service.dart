import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart' show PdfColor, PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hike_charges_service.dart';

/// Service to generate and store monthly financial reports for restaurants
class MonthlyReportService {
  static final _firestore = FirebaseFirestore.instance;
  static final _supabase = Supabase.instance.client;
  
  // Supabase bucket name for storing PDFs
  static const String _bucketName = 'restaurant-reports';

  /// Generate monthly report data for a restaurant
  static Future<Map<String, dynamic>> _generateReportData(
    String restaurantId,
    String restaurantName,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    // Get orders for this restaurant in the month
    final ordersQuery = await _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: 'delivered')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    // Get hike charges config
    final globalConfig = await HikeChargesService.getGlobalConfig();
    final override = await HikeChargesService.getRestaurantOverride(restaurantId);
    
    final packaging = override?.customPackagingCharges ?? globalConfig?.packagingCharges ?? 10;
    final delivery = override?.customDeliveryCharges ?? globalConfig?.deliveryCharges ?? 20;
    final hikeMultiplier = override?.customHikeMultiplier ?? globalConfig?.hikeMultiplier ?? 10;

    double totalOrderValue = 0;
    double totalHikeCharges = 0;
    double totalCommission = 0;
    int totalOrders = 0;
    List<Map<String, dynamic>> orderDetails = [];

    for (final doc in ordersQuery.docs) {
      final data = doc.data();
      final orderValue = (data['orderTotal'] as num?)?.toDouble() ?? 
                         (data['total'] as num?)?.toDouble() ?? 0;
      final hikeCharges = (data['hikeCharges'] as num?)?.toDouble() ??
                          (data['deliveryCharges'] as num?)?.toDouble() ?? 0;
      final commission = (data['commission'] as num?)?.toDouble() ?? 
                         (orderValue * 0.10); // Default 10%

      totalOrderValue += orderValue;
      totalHikeCharges += hikeCharges;
      totalCommission += commission;
      totalOrders++;

      orderDetails.add({
        'orderId': doc.id.substring(0, 8).toUpperCase(),
        'date': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'orderValue': orderValue,
        'hikeCharges': hikeCharges,
        'commission': commission,
        'netAmount': orderValue - commission,
        'customerName': data['customerName'] ?? 'Customer',
      });
    }

    // Calculate admin take from hike
    final adminHikeTake = totalHikeCharges * 0.30; // 30% of hike goes to admin
    final netToRestaurant = totalOrderValue - totalCommission;

    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'month': month,
      'monthName': DateFormat('MMMM yyyy').format(month),
      'generatedAt': DateTime.now(),
      'totalOrders': totalOrders,
      'totalOrderValue': totalOrderValue,
      'totalHikeCharges': totalHikeCharges,
      'totalCommission': totalCommission,
      'adminHikeTake': adminHikeTake,
      'netToRestaurant': netToRestaurant,
      'orderDetails': orderDetails,
      'hikeBreakdown': {
        'packaging': packaging,
        'delivery': delivery,
        'hikeMultiplier': hikeMultiplier,
      },
    };
  }

  /// Generate PDF report
  static Future<Uint8List> _generatePdf(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();
    final monthName = reportData['monthName'] as String;
    final restaurantName = reportData['restaurantName'] as String;
    final generatedAt = reportData['generatedAt'] as DateTime;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FEEDZO',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('4F46E5'),
                      ),
                    ),
                    pw.Text(
                      'Monthly Financial Report',
                      style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('6B7280')),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      monthName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('dd MMM yyyy').format(generatedAt)}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('6B7280')),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('9CA3AF')),
            ),
          ],
        ),
        build: (context) => [
          // Restaurant Info
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F3F4F6'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  restaurantName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Restaurant ID: ${reportData['restaurantId']}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('6B7280')),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Summary Cards
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _buildSummaryCard(
                'Total Orders',
                '${reportData['totalOrders']}',
                PdfColor.fromHex('3B82F6'),
              ),
              pw.SizedBox(width: 12),
              _buildSummaryCard(
                'Order Value',
                '₹${_formatCurrency(reportData['totalOrderValue'])}',
                PdfColor.fromHex('10B981'),
              ),
              pw.SizedBox(width: 12),
              _buildSummaryCard(
                'Net Payout',
                '₹${_formatCurrency(reportData['netToRestaurant'])}',
                PdfColor.fromHex('8B5CF6'),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Detailed Breakdown
          pw.Text(
            'Revenue Breakdown',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          _buildBreakdownTable(reportData),
          pw.SizedBox(height: 24),

          // Hike Charges Section
          pw.Text(
            'Hike Charges Analysis',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('E5E7EB')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Hike Charges Collected:'),
                    pw.Text(
                      '₹${_formatCurrency(reportData['totalHikeCharges'])}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Admin Share (30% of hike):'),
                    pw.Text(
                      '₹${_formatCurrency(reportData['adminHikeTake'])}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('EF4444'),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Platform Commission:'),
                    pw.Text(
                      '₹${_formatCurrency(reportData['totalCommission'])}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Admin Revenue:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '₹${_formatCurrency(reportData['totalCommission'] + reportData['adminHikeTake'])}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: PdfColor.fromHex('059669'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Order Details Table
          pw.Text(
            'Order Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          _buildOrderDetailsTable(reportData['orderDetails'] as List<Map<String, dynamic>>),
        ],
      ),
    );

    return pdf.save();
  }

  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red, color.green, color.blue, opacity);
  }

  static pw.Widget _buildSummaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _withOpacity(color, 0.1),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _withOpacity(color, 0.3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('6B7280'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBreakdownTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('E5E7EB')),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F9FAFB')),
          children: [
            _buildTableHeaderCell('Description'),
            _buildTableHeaderCell('Amount'),
            _buildTableHeaderCell('% of Total'),
          ],
        ),
        _buildTableRow(
          'Total Order Value (Items)',
          '₹${_formatCurrency(data['totalOrderValue'])}',
          '100%',
        ),
        _buildTableRow(
          'Hike Charges (Packaging + Delivery)',
          '₹${_formatCurrency(data['totalHikeCharges'])}',
          '${((data['totalHikeCharges'] / data['totalOrderValue']) * 100).toStringAsFixed(1)}%',
        ),
        _buildTableRow(
          'Platform Commission Deduction',
          '-₹${_formatCurrency(data['totalCommission'])}',
          '${((data['totalCommission'] / data['totalOrderValue']) * 100).toStringAsFixed(1)}%',
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Net Amount to Restaurant',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '₹${_formatCurrency(data['netToRestaurant'])}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(''),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildOrderDetailsTable(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No orders for this month',
          style: pw.TextStyle(color: PdfColor.fromHex('9CA3AF')),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('E5E7EB')),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F9FAFB')),
          children: [
            _buildTableHeaderCell('Order ID'),
            _buildTableHeaderCell('Date'),
            _buildTableHeaderCell('Value'),
            _buildTableHeaderCell('Commission'),
            _buildTableHeaderCell('Net'),
          ],
        ),
        ...orders.map((order) => _buildOrderRow(order)),
      ],
    );
  }

  static pw.TableRow _buildOrderRow(Map<String, dynamic> order) {
    return pw.TableRow(
      children: [
        _buildTableCell(order['orderId'] as String),
        _buildTableCell(DateFormat('dd MMM').format(order['date'] as DateTime)),
        _buildTableCell('₹${_formatCurrency(order['orderValue'])}'),
        _buildTableCell('₹${_formatCurrency(order['commission'])}'),
        _buildTableCell('₹${_formatCurrency(order['netAmount'])}'),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
          color: PdfColor.fromHex('374151'),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.TableRow _buildTableRow(String desc, String amount, String percent) {
    return pw.TableRow(
      children: [
        _buildTableCell(desc),
        _buildTableCell(amount),
        _buildTableCell(percent),
      ],
    );
  }

  static String _formatCurrency(double value) {
    return value.toStringAsFixed(0);
  }

  /// Generate and upload monthly report for a restaurant
  static Future<String?> generateAndUploadReport({
    required String restaurantId,
    required String restaurantName,
    required DateTime month,
  }) async {
    try {
      // Generate report data
      final reportData = await _generateReportData(restaurantId, restaurantName, month);

      // Generate PDF
      final pdfBytes = await _generatePdf(reportData);

      // Create filename
      final fileName = 'report_${restaurantId}_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf';

      // Upload to Supabase
      final response = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, pdfBytes, fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ));

      // Get public URL
      final fileUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);

      // Save report metadata to Firestore
      await _firestore.collection('monthlyReports').add({
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'month': month,
        'year': month.year,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'generatedAt': FieldValue.serverTimestamp(),
        'totalOrders': reportData['totalOrders'],
        'totalOrderValue': reportData['totalOrderValue'],
        'totalHikeCharges': reportData['totalHikeCharges'],
        'totalCommission': reportData['totalCommission'],
        'netToRestaurant': reportData['netToRestaurant'],
        'adminHikeTake': reportData['adminHikeTake'],
      });

      debugPrint('MonthlyReportService: Generated and uploaded report for $restaurantName - ${reportData['monthName']}');
      return fileUrl;
    } catch (e) {
      debugPrint('MonthlyReportService Error: $e');
      return null;
    }
  }

  /// Generate reports for all restaurants for a given month
  static Future<Map<String, String?>> generateReportsForAllRestaurants(DateTime month) async {
    final results = <String, String?>{};

    try {
      // Get all restaurants
      final restaurantsSnapshot = await _firestore.collection('restaurants').get();

      for (final doc in restaurantsSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? 'Unknown Restaurant';

        final url = await generateAndUploadReport(
          restaurantId: doc.id,
          restaurantName: name,
          month: month,
        );

        results[doc.id] = url;
      }

      debugPrint('MonthlyReportService: Generated ${results.length} reports for ${DateFormat('MMMM yyyy').format(month)}');
    } catch (e) {
      debugPrint('MonthlyReportService Error generating all reports: $e');
    }

    return results;
  }

  /// Get report history for a restaurant
  static Stream<List<Map<String, dynamic>>> watchReportHistory(String restaurantId) {
    return _firestore
        .collection('monthlyReports')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Download report from Supabase
  static Future<Uint8List?> downloadReport(String fileName) async {
    try {
      final response = await _supabase.storage.from(_bucketName).download(fileName);
      return response;
    } catch (e) {
      debugPrint('MonthlyReportService Error downloading: $e');
      return null;
    }
  }
}
