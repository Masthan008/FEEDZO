import 'package:flutter/material.dart';
import '../../models/split_payment_model.dart';
import '../../services/split_payment_service.dart';

class SplitPaymentScreen extends StatefulWidget {
  final double totalAmount;
  const SplitPaymentScreen({super.key, required this.totalAmount});

  @override
  State<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends State<SplitPaymentScreen> {
  final List<SplitPaymentPart> _splits = [];
  final _nameControllers = <TextEditingController>[];
  final _emailControllers = <TextEditingController>[];
  final _amountControllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _addSplit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Payment'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _splits.length,
              itemBuilder: (context, index) {
                return _buildSplitCard(index);
              },
            ),
          ),
          _buildSummary(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _splits.length < 4 ? _addSplit : null,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSplitCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Person ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeSplit(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameControllers[index],
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailControllers[index],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountControllers[index],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹${widget.totalAmount.toStringAsFixed(2)} total)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateSplitAmount(index, value);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _splits[index].paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
              ],
              onChanged: (value) {
                setState(() {
                  _splits[index] = SplitPaymentPart(
                    userId: '',
                    userName: _nameControllers[index].text,
                    userEmail: _emailControllers[index].text,
                    amount: _splits[index].amount,
                    paymentMethod: value ?? 'card',
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final totalSplit = _splits.fold<double>(0, (sum, split) => sum + split.amount);
    final remaining = widget.totalAmount - totalSplit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Split Amount'),
              Text(
                '₹${totalSplit.toStringAsFixed(2)}',
                style: TextStyle(
                  color: remaining >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining'),
              Text(
                '₹${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: remaining >= 0 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: remaining == 0 ? _confirmSplitPayment : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Confirm Split Payment'),
          ),
        ],
      ),
    );
  }

  void _addSplit() {
    setState(() {
      _splits.add(SplitPaymentPart(
        userId: '',
        userName: '',
        userEmail: '',
        amount: 0,
        paymentMethod: 'card',
      ));
      _nameControllers.add(TextEditingController());
      _emailControllers.add(TextEditingController());
      _amountControllers.add(TextEditingController());
    });
  }

  void _removeSplit(int index) {
    setState(() {
      _splits.removeAt(index);
      _nameControllers.removeAt(index);
      _emailControllers.removeAt(index);
      _amountControllers.removeAt(index);
    });
  }

  void _updateSplitAmount(int index, String value) {
    final amount = double.tryParse(value) ?? 0;
    setState(() {
      _splits[index] = SplitPaymentPart(
        userId: '',
        userName: _nameControllers[index].text,
        userEmail: _emailControllers[index].text,
        amount: amount,
        paymentMethod: _splits[index].paymentMethod,
      );
    });
  }

  void _confirmSplitPayment() {
    // Create split payment and send invitations
    Navigator.pop(context, _splits);
  }
}
