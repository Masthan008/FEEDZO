import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import 'package:provider/provider.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _db = FirebaseFirestore.instance;
  Map<String, dynamic>? _documents;
  bool _isUploading = false;
  String? _uploadingDocType;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantId = authProvider.restaurantId;
    if (restaurantId == null) return;

    final snapshot = await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('documents')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _documents = snapshot.docs.first.data();
      });
    }
  }

  Future<void> _uploadDocument(String docType, String docName) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _isUploading = true;
      _uploadingDocType = docType;
    });

    try {
      final String? imageUrl = await CloudinaryService.uploadImage(
        File(image.path),
        folder: 'restaurant_documents',
      );

      if (imageUrl != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final restaurantId = authProvider.restaurantId;
        if (restaurantId != null) {
          await _db
              .collection('restaurants')
              .doc(restaurantId)
              .collection('documents')
              .doc('documents')
              .set({
            '${docType}Url': imageUrl,
            '${docType}Status': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await _loadDocuments();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded successfully!')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingDocType = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Documents'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocumentCard(
            title: 'Business License',
            icon: Icons.business,
            status: _documents?['businessLicenseStatus'] ?? 'Not Submitted',
            url: _documents?['businessLicenseUrl'],
            docType: 'businessLicense',
          ),
          _buildDocumentCard(
            title: 'Food Safety Certificate',
            icon: Icons.restaurant,
            status: _documents?['foodSafetyStatus'] ?? 'Not Submitted',
            url: _documents?['foodSafetyUrl'],
            docType: 'foodSafety',
          ),
          _buildDocumentCard(
            title: 'Tax Registration',
            icon: Icons.receipt,
            status: _documents?['taxRegistrationStatus'] ?? 'Not Submitted',
            url: _documents?['taxRegistrationUrl'],
            docType: 'taxRegistration',
          ),
          _buildDocumentCard(
            title: 'FSSAI Certificate',
            icon: Icons.verified,
            status: _documents?['fssaiStatus'] ?? 'Not Submitted',
            url: _documents?['fssaiUrl'],
            docType: 'fssai',
          ),
          _buildDocumentCard(
            title: 'Bank Statement',
            icon: Icons.account_balance,
            status: _documents?['bankStatementStatus'] ?? 'Not Submitted',
            url: _documents?['bankStatementUrl'],
            docType: 'bankStatement',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required String status,
    String? url,
    required String docType,
  }) {
    final statusColor = _getStatusColor(status);
    final isUploading = _isUploading && _uploadingDocType == docType;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: statusColor),
        ),
        title: Text(title),
        subtitle: Text(isUploading ? 'Uploading...' : status),
        trailing: url != null
            ? IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Download document
                },
              )
            : IconButton(
                icon: const Icon(Icons.upload),
                onPressed: isUploading
                    ? null
                    : () => _uploadDocument(docType, title),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
