import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class ImageHelper {
  static const int maxImageWidth = 800; // Maksimal lebar gambar
  static const int maxImageHeight = 800; // Maksimal tinggi gambar
  static const int maxSizeInBytes = 1024 * 1024; // 1MB

  static Future<String?> pickAndProcessImage({
    required ImageSource source,
    bool compressImage = true,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile == null) {
        return null;
      }

      final File imageFile = File(pickedFile.path);
      final imageBytes = await imageFile.readAsBytes();
      
      // Jika ukuran file sudah di bawah batas maksimal dan tidak perlu kompresi, gunakan langsung
      if (!compressImage && imageBytes.length <= maxSizeInBytes) {
        return await _saveImageToAppDirectory(imageFile);
      }

      // Jika ukuran file melebihi batas maksimal atau perlu dikompresi, lakukan kompresi
      return await _compressAndSaveImage(imageFile);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  static Future<String?> _compressAndSaveImage(File imageFile) async {
    try {
      // Decode image
      final bytes = await imageFile.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) {
        return null;
      }

      // Resize image jika perlu
      img.Image resizedImage = decodedImage;
      if (decodedImage.width > maxImageWidth || decodedImage.height > maxImageHeight) {
        resizedImage = img.copyResize(
          decodedImage,
          width: decodedImage.width > maxImageWidth 
              ? maxImageWidth 
              : decodedImage.width,
          height: decodedImage.height > maxImageHeight 
              ? maxImageHeight 
              : decodedImage.height,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode dengan kualitas lebih rendah (kompresi)
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 80);

      // Cek ukuran setelah kompresi awal
      if (compressedBytes.length > maxSizeInBytes) {
        // Jika masih terlalu besar, kompres lagi dengan kualitas lebih rendah
        int quality = 70;
        while (compressedBytes.length > maxSizeInBytes && quality > 10) {
          compressedBytes = img.encodeJpg(resizedImage, quality: quality);
          quality -= 10; // Kurangi kualitas sampai mencapai ukuran yang diinginkan
        }
      }

      // Simpan gambar yang telah dikompresi
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await tempFile.writeAsBytes(compressedBytes);

      // Salin ke direktori aplikasi
      return await _saveImageToAppDirectory(tempFile);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  static Future<String?> _saveImageToAppDirectory(File imageFile) async {
    try {
      final fileName = 'product_image_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      
      // Buat folder images jika belum ada
      final Directory imageDir = Directory('$appDocPath/images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final String filePath = '${imageDir.path}/$fileName';
      final File newImage = await imageFile.copy(filePath);
      
      return newImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
} 