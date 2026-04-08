import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RestaurantFormDialog extends StatefulWidget {
  const RestaurantFormDialog({super.key});

  @override
  State<RestaurantFormDialog> createState() => _RestaurantFormDialogState();
}

class _RestaurantFormDialogState extends State<RestaurantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController(text: '10');
  final _fssaiCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  
  bool _isApproved = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cuisineCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _commissionCtrl.dispose();
    _fssaiCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'cuisine': _cuisineCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'commissionRate': double.tryParse(_commissionCtrl.text) ?? 10.0,
        'fssaiNumber': _fssaiCtrl.text.trim().isEmpty ? null : _fssaiCtrl.text.trim(),
        'gstNumber': _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        'panNumber': _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
        'isApproved': _isApproved,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Restaurant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Restaurant Name *',
                                hintText: 'e.g., Spice Garden',
                                prefixIcon: Icon(Icons.store),
                              ),
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cuisineCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Cuisine Type *',
                                hintText: 'e.g., North Indian',
                                prefixIcon: Icon(Icons.local_dining),
                              ),
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                hintText: 'restaurant@email.com',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return 'Required';
                                if (!v!.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Phone *',
                                hintText: '10 digit mobile number',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          hintText: 'Full restaurant address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          hintText: 'Min 6 characters',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (v!.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Business Documents
                      _buildSectionTitle('Business Documents (Optional)'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fssaiCtrl,
                              decoration: const InputDecoration(
                                labelText: 'FSSAI License Number',
                                hintText: '14 digit number',
                                prefixIcon: Icon(Icons.verified_user),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _gstCtrl,
                              decoration: const InputDecoration(
                                labelText: 'GST Number',
                                hintText: '15 character GSTIN',
                                prefixIcon: Icon(Icons.receipt),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _panCtrl,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                          hintText: '10 character PAN',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Settings
                      _buildSectionTitle('Settings'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _commissionCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Commission Rate (%)',
                                suffixText: '%',
                                prefixIcon: Icon(Icons.percent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isApproved,
                                  onChanged: (v) => setState(() => _isApproved = v!),
                                  activeColor: AppColors.statusDelivered,
                                ),
                                const Expanded(
                                  child: Text(
                                    'Auto-approve restaurant',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Restaurant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
