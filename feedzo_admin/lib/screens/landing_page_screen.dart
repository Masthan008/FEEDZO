import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/landing_page_model.dart';
import '../services/landing_page_service.dart';
import '../widgets/topbar.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _heroImageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ctaTextController = TextEditingController();
  final _ctaLinkController = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _heroImageUrlController.dispose();
    _descriptionController.dispose();
    _ctaTextController.dispose();
    _ctaLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Landing Page', subtitle: 'Customize landing page content'),
        Expanded(
          child: StreamBuilder<LandingPageModel?>(
            stream: LandingPageService.watchActiveLandingPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final landingPage = snapshot.data;

              if (landingPage == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.web, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No landing page content yet', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Landing Page'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              landingPage.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showEditDialog(landingPage),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (landingPage.heroImageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              landingPage.heroImageUrl!,
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
                        Text(
                          landingPage.subtitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        if (landingPage.description != null) ...[
                          const SizedBox(height: 16),
                          Text(landingPage.description!),
                        ],
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text('Call to Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (landingPage.ctaText != null)
                          Text('Button Text: ${landingPage.ctaText}'),
                        if (landingPage.ctaLink != null)
                          Text('Link: ${landingPage.ctaLink}'),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text('App Store URLs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...landingPage.appStoreUrls.map((url) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(url),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditDialog([LandingPageModel? landingPage]) {
    if (landingPage != null) {
      _titleController.text = landingPage.title;
      _subtitleController.text = landingPage.subtitle;
      _heroImageUrlController.text = landingPage.heroImageUrl ?? '';
      _descriptionController.text = landingPage.description ?? '';
      _ctaTextController.text = landingPage.ctaText ?? '';
      _ctaLinkController.text = landingPage.ctaLink ?? '';
      _isActive = landingPage.isActive;
    } else {
      _titleController.clear();
      _subtitleController.clear();
      _heroImageUrlController.clear();
      _descriptionController.clear();
      _ctaTextController.clear();
      _ctaLinkController.clear();
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(landingPage == null ? 'Add Landing Page' : 'Edit Landing Page'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heroImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Hero Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctaTextController,
                  decoration: const InputDecoration(
                    labelText: 'CTA Button Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctaLinkController,
                  decoration: const InputDecoration(
                    labelText: 'CTA Link',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('This landing page is currently visible'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
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
              if (_titleController.text.isEmpty || _subtitleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title and subtitle are required')),
                );
                return;
              }

              final landingPageData = LandingPageModel(
                id: landingPage?.id ?? '',
                title: _titleController.text.trim(),
                subtitle: _subtitleController.text.trim(),
                heroImageUrl: _heroImageUrlController.text.trim(),
                description: _descriptionController.text.trim(),
                featureImages: landingPage?.featureImages ?? [],
                appStoreUrls: landingPage?.appStoreUrls ?? [],
                ctaText: _ctaTextController.text.trim(),
                ctaLink: _ctaLinkController.text.trim(),
                isActive: _isActive,
                updatedAt: DateTime.now(),
              );

              try {
                await LandingPageService.saveLandingPage(landingPageData);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        landingPage == null
                            ? 'Landing page added successfully'
                            : 'Landing page updated successfully',
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
