import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Payment Methods', subtitle: 'Manage payment method configurations'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildPaymentCard(
                  title: 'Cash on Delivery',
                  icon: Icons.money,
                  color: Colors.green,
                  isActive: true,
                ),
                _buildPaymentCard(
                  title: 'Card Payment',
                  icon: Icons.credit_card,
                  color: Colors.blue,
                  isActive: true,
                ),
                _buildPaymentCard(
                  title: 'Digital Wallet',
                  icon: Icons.account_balance_wallet,
                  color: Colors.orange,
                  isActive: true,
                ),
                _buildPaymentCard(
                  title: 'UPI',
                  icon: Icons.qr_code,
                  color: Colors.purple,
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                if (isActive)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: isActive,
              onChanged: (v) {},
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
