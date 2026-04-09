import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/about_us_model.dart';
import '../services/about_us_service.dart';
import '../widgets/topbar.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  final _titleController = TextEditingController();
  final _missionController = TextEditingController();
  final _visionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _missionController.dispose();
    _visionController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'About Us', subtitle: 'Manage company information'),
        Expanded(
          child: StreamBuilder<AboutUsModel?>(
            stream: AboutUsService.watchAboutUs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final aboutUs = snapshot.data;

              if (aboutUs == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No About Us content yet', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add About Us'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  aboutUs.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showEditDialog(aboutUs),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (aboutUs.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  aboutUs.imageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 16),
                            const Text('Mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(aboutUs.mission),
                            const SizedBox(height: 16),
                            const Text('Vision', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(aboutUs.vision),
                            const SizedBox(height: 16),
                            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(aboutUs.description),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            if (aboutUs.email != null)
                              _buildContactRow(Icons.email, aboutUs.email!),
                            if (aboutUs.phone != null)
                              _buildContactRow(Icons.phone, aboutUs.phone!),
                            if (aboutUs.address != null)
                              _buildContactRow(Icons.location_on, aboutUs.address!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditDialog([AboutUsModel? aboutUs]) {
    if (aboutUs != null) {
      _titleController.text = aboutUs.title;
      _missionController.text = aboutUs.mission;
      _visionController.text = aboutUs.vision;
      _descriptionController.text = aboutUs.description;
      _emailController.text = aboutUs.email ?? '';
      _phoneController.text = aboutUs.phone ?? '';
      _addressController.text = aboutUs.address ?? '';
      _imageUrlController.text = aboutUs.imageUrl ?? '';
    } else {
      _titleController.clear();
      _missionController.clear();
      _visionController.clear();
      _descriptionController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _imageUrlController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(aboutUs == null ? 'Add About Us' : 'Edit About Us'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _missionController,
                  decoration: const InputDecoration(
                    labelText: 'Mission *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _visionController,
                  decoration: const InputDecoration(
                    labelText: 'Vision *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty ||
                  _missionController.text.isEmpty ||
                  _visionController.text.isEmpty ||
                  _descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title, mission, vision, and description are required')),
                );
                return;
              }

              final aboutUsData = AboutUsModel(
                id: aboutUs?.id ?? '',
                title: _titleController.text.trim(),
                mission: _missionController.text.trim(),
                vision: _visionController.text.trim(),
                description: _descriptionController.text.trim(),
                imageUrl: _imageUrlController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                address: _addressController.text.trim(),
                updatedAt: DateTime.now(),
              );

              try {
                await AboutUsService.saveAboutUs(aboutUsData);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        aboutUs == null
                            ? 'About Us added successfully'
                            : 'About Us updated successfully',
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
}
