import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../hike_charges_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isVeg = false;

  bool _isSaving = false;
  File? _newCoverFile;
  List<File> _newGalleryFiles = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _descCtrl.text = auth.description;
    _phoneCtrl.text = auth.phone;
    _prepTimeCtrl.text = auth.defaultPrepTime.toString();
    _radiusCtrl.text = auth.deliveryRadius.toString();
    _upiCtrl.text = auth.payoutUpi;
    _cuisineCtrl.text = auth.cuisine;
    _deliveryFeeCtrl.text = auth.deliveryFee.toString();
    _minOrderCtrl.text = auth.minOrder.toString();
    _addressCtrl.text = auth.address;
    _isVeg = auth.isVeg;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _prepTimeCtrl.dispose();
    _radiusCtrl.dispose();
    _upiCtrl.dispose();
    _cuisineCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _minOrderCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newCoverFile = File(picked.path));
    }
  }

  Future<void> _pickGallery() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _newGalleryFiles.addAll(picked.map((p) => File(p.path)));
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    try {
      String? coverUrl = auth.coverImageUrl;
      if (_newCoverFile != null) {
        coverUrl = await CloudinaryService.uploadImage(
          _newCoverFile!,
          folder: 'covers',
        );
      }

      List<String> galleryUrls = List.from(auth.restaurantImages);
      for (var file in _newGalleryFiles) {
        final url = await CloudinaryService.uploadImage(
          file,
          folder: 'gallery',
        );
        if (url != null) galleryUrls.add(url);
      }

      await auth.updateProfile(
        description: _descCtrl.text.trim(),
        coverImageUrl: coverUrl,
        restaurantImages: galleryUrls,
        phone: _phoneCtrl.text.trim(),
        defaultPrepTime: int.tryParse(_prepTimeCtrl.text) ?? 20,
        deliveryRadius: double.tryParse(_radiusCtrl.text) ?? 5.0,
        payoutUpi: _upiCtrl.text.trim(),
        cuisine: _cuisineCtrl.text.trim(),
        deliveryFee: double.tryParse(_deliveryFeeCtrl.text) ?? 0.0,
        minOrder: double.tryParse(_minOrderCtrl.text) ?? 0.0,
        isVeg: _isVeg,
        address: _addressCtrl.text.trim(),
      );

      setState(() {
        _newCoverFile = null;
        _newGalleryFiles = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cover Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _newCoverFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_newCoverFile!, fit: BoxFit.cover),
                      )
                    : (auth.coverImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                auth.coverImageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: Colors.grey,
                            )),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About Restaurant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter restaurant description...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Operational Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Support Phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Restaurant Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cuisineCtrl,
              decoration: InputDecoration(
                labelText: 'Cuisines (comma-separated)',
                hintText: 'e.g. Burgers, Pizza, Indian',
                prefixIcon: const Icon(Icons.restaurant_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deliveryFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Delivery Fee',
                      prefixText: '₹ ',
                      prefixIcon: const Icon(Icons.delivery_dining_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minOrderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Order',
                      prefixText: '₹ ',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pure Veg Restaurant'),
              subtitle: const Text('Show the green veg icon to customers'),
              value: _isVeg,
              onChanged: (v) => setState(() => _isVeg = v),
              activeColor: Colors.green,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prepTimeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Avg. Prep Time',
                      suffixText: 'mins',
                      prefixIcon: const Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _radiusCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Delivery Radius',
                      suffixText: 'km',
                      prefixIcon: const Icon(Icons.map_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Financial Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiCtrl,
              decoration: InputDecoration(
                labelText: 'Payout UPI ID',
                hintText: 'e.g. restaurant@upi',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.price_change_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'View Hike Charges',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'See packaging, delivery & commission rates',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HikeChargesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Restaurant Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _pickGallery,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Images'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: auth.restaurantImages.length + _newGalleryFiles.length,
              itemBuilder: (context, index) {
                if (index < auth.restaurantImages.length) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      auth.restaurantImages[index],
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  final fileIndex = index - auth.restaurantImages.length;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _newGalleryFiles[fileIndex],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _newGalleryFiles.removeAt(fileIndex),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
