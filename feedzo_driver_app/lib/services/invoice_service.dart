import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculate distance between two GeoPoints (in km)
  static double calculateDistance(GeoPoint from, GeoPoint to) {
    const double earthRadius = 6371; // in km
    final double dLat = _toRadians(to.latitude - from.latitude);
    final double dLng = _toRadians(to.longitude - from.longitude);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(_toRadians(from.latitude)) * cos(_toRadians(to.latitude));
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * (3.14159265359 / 180);

  /// Generate PDF invoice
  static Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FEEDZO',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Food Delivery Invoice',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice ID: ${invoice.id}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Order ID: ${invoice.orderId}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Date: ${_formatDate(invoice.createdAt)}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Divider
              pw.Divider(color: PdfColors.black),
              pw.SizedBox(height: 20),

              // Restaurant Details
              pw.Text(
                'FROM (Restaurant)',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.restaurantName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(invoice.restaurantAddress),
              pw.Text('Phone: ${invoice.restaurantPhone}'),
              pw.SizedBox(height: 20),

              // Customer Details
              pw.Text(
                'TO (Customer)',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.customerName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(invoice.customerAddress),
              pw.Text('Phone: ${invoice.customerPhone}'),
              pw.SizedBox(height: 20),

              // Driver Details
              pw.Text(
                'DELIVERED BY',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.driverName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Driver ID: ${invoice.driverId}'),
              pw.SizedBox(height: 20),

              // Divider
              pw.Divider(color: PdfColors.black),
              pw.SizedBox(height: 20),

              // Distance
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Delivery Distance'),
                  pw.Text('${invoice.distanceKm.toStringAsFixed(2)} km'),
                ],
              ),
              pw.SizedBox(height: 20),

              // Order Details Table
              pw.Text(
                'ORDER DETAILS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Subtotal'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('₹${invoice.subtotal.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Delivery Fee'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                            invoice.deliveryFee == 0 ? 'FREE' : '₹${invoice.deliveryFee.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Tax'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('₹${invoice.taxAmount.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  if (invoice.discount > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Discount'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('-₹${invoice.discount.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  if (invoice.tipAmount > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Tip'),
                        ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('₹${invoice.tipAmount.toStringAsFixed(2)}'),
                      ),
                    ],
                    ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('TOTAL',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('₹${invoice.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Payment Info
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Method'),
                    pw.Text(
                      invoice.paymentType == 'cod' ? 'Cash on Delivery' : 'Paid Online',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for using Feedzo!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated invoice.',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Save invoice to Firestore
  static Future<String> saveInvoice(InvoiceModel invoice) async {
    final docRef = await _db.collection('invoices').add(invoice.toMap());
    return docRef.id;
  }

  /// Download and print invoice
  static Future<void> downloadAndPrintInvoice(InvoiceModel invoice) async {
    final pdfData = await generateInvoicePdf(invoice);
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'Feedzo_Invoice_${invoice.orderId}.pdf',
    );
  }

  /// Save invoice to device storage
  static Future<String> saveInvoiceToDevice(InvoiceModel invoice) async {
    final pdfData = await generateInvoicePdf(invoice);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Feedzo_Invoice_${invoice.orderId}.pdf');
    await file.writeAsBytes(pdfData);
    return file.path;
  }

  /// Get invoice by order ID
  static Future<InvoiceModel?> getInvoiceByOrderId(String orderId) async {
    final query = await _db
        .collection('invoices')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    
    return InvoiceModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  /// Create invoice from order data
  static Future<InvoiceModel> createInvoiceFromOrder(
    Map<String, dynamic> orderData,
    String orderId,
    String driverId,
    String driverName,
  ) async {
    // Calculate distance if locations are available
    double distanceKm = 0.0;
    final customerLoc = orderData['customerLocation'] as GeoPoint?;
    final restaurantLoc = orderData['restaurantLocation'] as GeoPoint?;
    
    if (customerLoc != null && restaurantLoc != null) {
      distanceKm = calculateDistance(restaurantLoc, customerLoc);
    }

    final invoice = InvoiceModel(
      id: '', // Will be set by Firestore
      orderId: orderId,
      customerId: orderData['customerId'] ?? '',
      customerName: orderData['customerName'] ?? '',
      customerPhone: orderData['customerPhone'] ?? '',
      customerAddress: orderData['address'] ?? '',
      restaurantId: orderData['restaurantId'] ?? '',
      restaurantName: orderData['restaurantName'] ?? '',
      restaurantPhone: orderData['restaurantPhone'] ?? '',
      restaurantAddress: orderData['restaurantAddress'] ?? '',
      driverId: driverId,
      driverName: driverName,
      distanceKm: distanceKm,
      subtotal: (orderData['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (orderData['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (orderData['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discount: (orderData['discount'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (orderData['tipAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentType: orderData['paymentType'] ?? 'cod',
      createdAt: DateTime.now(),
      customerLocation: customerLoc,
      restaurantLocation: restaurantLoc,
    );

    return invoice;
  }
}
