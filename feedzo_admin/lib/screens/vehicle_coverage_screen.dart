import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class VehicleCoverageScreen extends StatefulWidget {
  const VehicleCoverageScreen({super.key});

  @override
  State<VehicleCoverageScreen> createState() => _VehicleCoverageScreenState();
}

class _VehicleCoverageScreenState extends State<VehicleCoverageScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Vehicle Coverage Areas', subtitle: 'Manage vehicle service areas'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildCoverageCard(
                  title: 'Bike Coverage',
                  icon: Icons.motorcycle,
                  color: Colors.blue,
                  description: 'Bike delivery coverage areas',
                  count: 15,
                ),
                _buildCoverageCard(
                  title: 'Car Coverage',
                  icon: Icons.directions_car,
                  color: Colors.green,
                  description: 'Car delivery coverage areas',
                  count: 8,
                ),
                _buildCoverageCard(
                  title: 'Truck Coverage',
                  icon: Icons.local_shipping,
                  color: Colors.orange,
                  description: 'Truck delivery coverage areas',
                  count: 5,
                ),
                _buildCoverageCard(
                  title: 'Walking Coverage',
                  icon: Icons.directions_walk,
                  color: Colors.purple,
                  description: 'Walking delivery coverage areas',
                  count: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required int count,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$count Areas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
