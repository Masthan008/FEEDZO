import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/third_party_config_model.dart';
import '../services/third_party_config_service.dart';
import '../widgets/topbar.dart';

class ThirdPartyConfigScreen extends StatefulWidget {
  const ThirdPartyConfigScreen({super.key});

  @override
  State<ThirdPartyConfigScreen> createState() => _ThirdPartyConfigScreenState();
}

class _ThirdPartyConfigScreenState extends State<ThirdPartyConfigScreen> {
  final _serviceNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _secretController = TextEditingController();
  final _additionalConfigController = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _serviceNameController.dispose();
    _apiKeyController.dispose();
    _secretController.dispose();
    _additionalConfigController.dispose();
    super.dispose();
  }

  void _showConfigDialog([ThirdPartyConfigModel? config]) {
    if (config != null) {
      _serviceNameController.text = config.serviceName;
      _apiKeyController.text = config.config['apiKey'] ?? '';
      _secretController.text = config.config['secret'] ?? '';
      _additionalConfigController.text = config.config['additional'] ?? '';
      _isActive = config.isActive;
    } else {
      _serviceNameController.clear();
      _apiKeyController.clear();
      _secretController.clear();
      _additionalConfigController.clear();
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(config == null ? 'Add Third Party Config' : 'Edit Third Party Config'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: config != null ? config.serviceName : null,
                decoration: const InputDecoration(
                  labelText: 'Service Name *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                  DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                  DropdownMenuItem(value: 'razorpay', child: Text('Razorpay')),
                  DropdownMenuItem(value: 'google_maps', child: Text('Google Maps')),
                  DropdownMenuItem(value: 'onesignal', child: Text('OneSignal')),
                  DropdownMenuItem(value: 'firebase', child: Text('Firebase')),
                  DropdownMenuItem(value: 'sendgrid', child: Text('SendGrid')),
                  DropdownMenuItem(value: 'twilio', child: Text('Twilio')),
                ],
                onChanged: config == null ? (v) => setState(() => _serviceNameController.text = v!) : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secretController,
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _additionalConfigController,
                decoration: const InputDecoration(
                  labelText: 'Additional Config (JSON)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_serviceNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service name is required')),
                );
                return;
              }

              Map<String, dynamic> configData = {};
              if (_apiKeyController.text.isNotEmpty) {
                configData['apiKey'] = _apiKeyController.text.trim();
              }
              if (_secretController.text.isNotEmpty) {
                configData['secret'] = _secretController.text.trim();
              }
              if (_additionalConfigController.text.isNotEmpty) {
                configData['additional'] = _additionalConfigController.text.trim();
              }

              final configModel = ThirdPartyConfigModel(
                id: config?.id ?? '',
                serviceName: _serviceNameController.text.trim(),
                config: configData,
                isActive: _isActive,
                updatedAt: DateTime.now(),
              );

              try {
                await ThirdPartyConfigService.saveConfig(configModel);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        config == null
                            ? 'Config added successfully'
                            : 'Config updated successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Third Party Config', subtitle: 'Manage external service integrations'),
        Expanded(
          child: StreamBuilder<List<ThirdPartyConfigModel>>(
            stream: ThirdPartyConfigService.watchAllConfigs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final configs = snapshot.data ?? [];

              if (configs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.extension, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No third party configs yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Service')),
                    DataColumn(label: Text('API Key')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: configs.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(Text(c.serviceName.toUpperCase())),
                        DataCell(
                          Text(
                            c.config['apiKey']?.substring(0, 8) ?? 'N/A',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: c.isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              c.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showConfigDialog(c),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(
                                  c.isActive ? Icons.toggle_on : Icons.toggle_off,
                                  size: 18,
                                  color: c.isActive ? Colors.green : Colors.red,
                                ),
                                onPressed: () async {
                                  await ThirdPartyConfigService.toggleConfigStatus(
                                    c.id,
                                    !c.isActive,
                                  );
                                },
                                tooltip: c.isActive ? 'Deactivate' : 'Activate',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Config'),
                                      content: Text(
                                        'Are you sure you want to delete ${c.serviceName} config?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ThirdPartyConfigService.deleteConfig(c.id);
                                  }
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showConfigDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Config'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
