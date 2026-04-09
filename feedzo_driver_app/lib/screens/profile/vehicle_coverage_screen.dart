import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleCoverageScreen extends StatefulWidget {
  const VehicleCoverageScreen({super.key});

  @override
  State<VehicleCoverageScreen> createState() => _VehicleCoverageScreenState();
}

class _VehicleCoverageScreenState extends State<VehicleCoverageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Coverage'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicleCoverage')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final coverageZones = snapshot.docs;

          if (coverageZones.isEmpty) {
            return const Center(
              child: Text('No coverage zones defined'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coverageZones.length,
            itemBuilder: (context, index) {
              final zone = coverageZones[index].data() as Map<String, dynamic>;
              return _buildZoneCard(zone);
            },
          );
        },
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final name = zone['name'] ?? 'Zone';
    final description = zone['description'] ?? '';
    final isActive = zone['isActive'] ?? false;
    final deliveryFee = (zone['deliveryFee'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.location_on,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(name),
        subtitle: Text(description.isEmpty ? 'No description' : description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${deliveryFee.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
