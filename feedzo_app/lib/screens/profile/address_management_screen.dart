import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final _labelCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );

        // Real reverse geocoding
        try {
          final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String>[];
            if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
            if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
            if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
            if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
            _addrCtrl.text = parts.join(', ');
          } else {
            _addrCtrl.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
          }
        } catch (e) {
          // If geocoding fails, show raw coordinates
          _addrCtrl.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAddress() async {
    if (_labelCtrl.text.isEmpty || _addrCtrl.text.isEmpty) return;
    
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final newAddr = '${_labelCtrl.text} - ${_addrCtrl.text}';
    final addresses = List<String>.from(auth.user!.savedAddresses)..add(newAddr);

    setState(() => _isLoading = true);
    try {
      await FirestoreService.updateAddress(auth.user!.id, addresses);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add New Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Label', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(hintText: 'Home, Work, etc.'),
            ),
            const SizedBox(height: 20),
            const Text('Full Address', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _addrCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter complete address...'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Use Current Location'),
            ),
            const SizedBox(height: 40),
            AppButton(
              label: 'Save Address',
              onPressed: _saveAddress,
              isLoading: _isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}