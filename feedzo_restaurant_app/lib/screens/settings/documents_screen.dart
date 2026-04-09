import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _db = FirebaseFirestore.instance;
  Map<String, dynamic>? _documents;

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
          ),
          _buildDocumentCard(
            title: 'Food Safety Certificate',
            icon: Icons.restaurant,
            status: _documents?['foodSafetyStatus'] ?? 'Not Submitted',
            url: _documents?['foodSafetyUrl'],
          ),
          _buildDocumentCard(
            title: 'Tax Registration',
            icon: Icons.receipt,
            status: _documents?['taxRegistrationStatus'] ?? 'Not Submitted',
            url: _documents?['taxRegistrationUrl'],
          ),
          _buildDocumentCard(
            title: 'FSSAI Certificate',
            icon: Icons.verified,
            status: _documents?['fssaiStatus'] ?? 'Not Submitted',
            url: _documents?['fssaiUrl'],
          ),
          _buildDocumentCard(
            title: 'Bank Statement',
            icon: Icons.account_balance,
            status: _documents?['bankStatementStatus'] ?? 'Not Submitted',
            url: _documents?['bankStatementUrl'],
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
  }) {
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: statusColor),
        ),
        title: Text(title),
        subtitle: Text(status),
        trailing: url != null
            ? IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Download document
                },
              )
            : const Icon(Icons.upload),
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
