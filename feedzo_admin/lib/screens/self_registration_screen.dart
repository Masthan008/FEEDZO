import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SelfRegistrationScreen extends StatefulWidget {
  const SelfRegistrationScreen({super.key});

  @override
  State<SelfRegistrationScreen> createState() => _SelfRegistrationScreenState();
}

class _SelfRegistrationScreenState extends State<SelfRegistrationScreen> {
  bool _driverSelfReg = false;
  bool _restaurantSelfReg = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Self-Registration', subtitle: 'Manage self-registration settings'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildRegCard(
                  title: 'Driver Self-Registration',
                  icon: Icons.delivery_dining,
                  color: Colors.blue,
                  description: 'Allow drivers to register themselves',
                  isEnabled: _driverSelfReg,
                  onToggle: (v) => setState(() => _driverSelfReg = v),
                ),
                _buildRegCard(
                  title: 'Restaurant Self-Registration',
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  description: 'Allow restaurants to register themselves',
                  isEnabled: _restaurantSelfReg,
                  onToggle: (v) => setState(() => _restaurantSelfReg = v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
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
            Switch(
              value: isEnabled,
              onChanged: onToggle,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
