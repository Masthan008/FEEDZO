import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverId = authProvider.driverId;

    if (driverId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips Received'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tips')
            .where('driverId', isEqualTo: driverId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tips = snapshot.docs;

          if (tips.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tips received yet'),
                  SizedBox(height: 8),
                  Text('Tips from customers will appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index].data() as Map<String, dynamic>;
              return _buildTipCard(tip);
            },
          );
        },
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final amount = (tip['amount'] ?? 0).toDouble();
    final customerName = tip['customerName'] ?? 'Customer';
    final orderId = tip['orderId'];
    final createdAt = (tip['createdAt'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.card_giftcard, color: Colors.green),
        ),
        title: Text('₹${amount.toStringAsFixed(2)}'),
        subtitle: Text('From $customerName • ${_formatDate(createdAt)}'),
        trailing: orderId != null
            ? const Icon(Icons.receipt_long, color: Colors.grey)
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
