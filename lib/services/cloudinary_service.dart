import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dfuev7yxo',       // 🔹 Your Cloudinary cloud name
    'flutter_unsigned', // 🔹 Your unsigned preset
    cache: false,
  );

  Future<String?> uploadImage(Uint8List imageBytes, {String? fileName}) async {
    try {
      // Generate unique identifier if not provided
      final id = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: id,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl; // ✅ Cloudinary URL
    } catch (e) {
      print("❌ Cloudinary upload failed: $e");
      return null;
    }
  }
}
