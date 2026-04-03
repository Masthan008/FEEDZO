import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:file_picker/file_picker.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';
import '../data/models/banner_model.dart';
import '../services/cloudinary_service.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const _AddBannerDialog(),
    );
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    await _firestore.collection('banners').doc(id).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> _deleteBanner(String id) async {
    await _firestore.collection('banners').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Banners', subtitle: 'Manage app promotional banners'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('banners').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              final banners = docs.map((d) => BannerModel.fromFirestore(d)).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: const Text('Add Banner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (banners.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: const [
                              Icon(Icons.view_carousel_outlined, size: 48, color: AppColors.textHint),
                              SizedBox(height: 12),
                              Text('No banners online yet. Add some to populate the app!', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: banners.length,
                        itemBuilder: (context, i) {
                          final b = banners[i];
                          return _BannerCard(
                            banner: b,
                            onToggle: () => _toggleStatus(b.id, b.isActive),
                            onDelete: () => _deleteBanner(b.id),
                          );
                        },
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
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerCard({required this.banner, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(banner.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (banner.subtitle.isNotEmpty) Text(banner.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (banner.actionUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('🔗 Link Attached', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: banner.isActive ? AppColors.statusDeliveredBg : AppColors.statusCancelledBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(banner.isActive ? 'Active' : 'Hidden', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: banner.isActive ? AppColors.statusDelivered : AppColors.statusCancelled)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBannerDialog extends StatefulWidget {
  const _AddBannerDialog();

  @override
  State<_AddBannerDialog> createState() => _AddBannerDialogState();
}

class _AddBannerDialogState extends State<_AddBannerDialog> {
  final _titleCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  
  bool _isLoading = false;
  PlatformFile? _pickedFile;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _uploadAndSave() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image.')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final url = await CloudinaryService.uploadBytes(_pickedFile!.bytes!, _pickedFile!.name, folder: 'feedzo/banners');
      if (url == null) throw Exception('Cloudinary upload failed.');

      final model = BannerModel(
        id: '',
        imageUrl: url,
        title: _titleCtrl.text.trim(),
        subtitle: _subCtrl.text.trim(),
        actionUrl: _linkCtrl.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('banners').add(model.toMap());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Promotional Banner'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _pickedFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_pickedFile!.bytes!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textHint),
                            SizedBox(height: 8),
                            Text('Click to upload image', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. PLAY & WIN)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _subCtrl, decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: 'Action URL (Optional)', hintText: 'https://...', border: OutlineInputBorder())),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _uploadAndSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save & Publish'),
        ),
      ],
    );
  }
}
