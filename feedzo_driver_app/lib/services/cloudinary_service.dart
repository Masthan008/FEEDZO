import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cloudinary image upload service.
/// Replace the constants with your real Cloudinary credentials.
class CloudinaryService {
  // Get these from: https://cloudinary.com/console
  static const _cloudName = 'dxbpni461';
  static const _uploadPreset = 'ml_default'; // unsigned preset

  // Fixed URL without interpolation issues
  static const _baseUrl =
      'https://api.cloudinary.com/v1_1/dxbpni461/image/upload';

  /// Upload a file and return the secure URL, or null on failure.
  static Future<String?> uploadImage(
    File imageFile, {
    String folder = 'feedzo',
  }) async {
    try {
      print('Cloudinary: Starting upload for ${imageFile.path}');
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // For unsigned uploads, we ONLY need upload_preset and file
      request.fields['upload_preset'] = _uploadPreset;

      // If you want to use folder with unsigned, it must be enabled in Cloudinary dashboard
      // request.fields['folder'] = folder;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      print('Cloudinary: Status Code ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(body.body) as Map<String, dynamic>;
        print('Cloudinary: Success! URL: ${json['secure_url']}');
        return json['secure_url'] as String?;
      } else {
        print('Cloudinary: Upload failed with body: ${body.body}');
        return null;
      }
    } catch (e) {
      print('Cloudinary: Error during upload: $e');
      return null;
    }
  }

  /// Upload from bytes (useful for web/picked images)
  static Future<String?> uploadBytes(
    List<int> bytes,
    String filename, {
    String folder = 'feedzo',
  }) async {
    try {
      print('Cloudinary: Starting byte upload for $filename');
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // For unsigned uploads, we ONLY need upload_preset and file
      request.fields['upload_preset'] = _uploadPreset;

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      print('Cloudinary: Status Code ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(body.body) as Map<String, dynamic>?;
        print('Cloudinary: Success! URL: ${json?['secure_url']}');
        return json?['secure_url'] as String?;
      } else {
        print('Cloudinary: Upload failed with body: ${body.body}');
        return null;
      }
    } catch (e) {
      print('Cloudinary: Error during byte upload: $e');
      return null;
    }
  }
}
