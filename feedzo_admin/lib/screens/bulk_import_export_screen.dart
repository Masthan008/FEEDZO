import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class BulkImportExportScreen extends StatefulWidget {
  const BulkImportExportScreen({super.key});

  @override
  State<BulkImportExportScreen> createState() => _BulkImportExportScreenState();
}

class _BulkImportExportScreenState extends State<BulkImportExportScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Bulk Import/Export', subtitle: 'Manage bulk data operations'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildImportCard(
                  title: 'Import Restaurants',
                  icon: Icons.store,
                  color: Colors.blue,
                  description: 'Import restaurant data from CSV/Excel file',
                ),
                _buildImportCard(
                  title: 'Import Menu Items',
                  icon: Icons.restaurant_menu,
                  color: Colors.orange,
                  description: 'Import menu items in bulk',
                ),
                _buildImportCard(
                  title: 'Import Drivers',
                  icon: Icons.delivery_dining,
                  color: Colors.green,
                  description: 'Import driver data',
                ),
                _buildImportCard(
                  title: 'Import Users',
                  icon: Icons.people,
                  color: Colors.purple,
                  description: 'Import customer data',
                ),
                _buildExportCard(
                  title: 'Export Orders',
                  icon: Icons.receipt_long,
                  color: Colors.red,
                  description: 'Export order data to CSV/Excel',
                ),
                _buildExportCard(
                  title: 'Export Restaurants',
                  icon: Icons.store,
                  color: Colors.blue,
                  description: 'Export restaurant data',
                ),
                _buildExportCard(
                  title: 'Export Drivers',
                  icon: Icons.delivery_dining,
                  color: Colors.green,
                  description: 'Export driver data',
                ),
                _buildExportCard(
                  title: 'Export Users',
                  icon: Icons.people,
                  color: Colors.purple,
                  description: 'Export customer data',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
