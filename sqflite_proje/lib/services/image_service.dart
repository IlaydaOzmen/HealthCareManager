import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndCropImage({
    ImageSource source = ImageSource.gallery,
    bool cropImage = true,
  }) async {
    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null) return null;

      String imagePath = pickedFile.path;

      // Crop image if requested
      if (cropImage) {
        final croppedFile = await _cropImage(imagePath);
        if (croppedFile != null) {
          imagePath = croppedFile.path;
        }
      }

      // Save to app directory
      final savedPath = await _saveImageToAppDirectory(imagePath);

      // Delete temporary file if it exists
      if (pickedFile.path != savedPath) {
        try {
          await File(pickedFile.path).delete();
        } catch (e) {
          debugPrint('Temporary file could not be deleted: $e');
        }
      }

      return savedPath;
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Resim seçilemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  static Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          IOSUiSettings(
            title: 'Resmi Düzenle',
            doneButtonTitle: 'Tamam',
            cancelButtonTitle: 'İptal',
            aspectRatioPickerButtonHidden: false,
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: false,
            rotateClockwiseButtonHidden: false,
            rotateButtonsHidden: false,
          ),
          AndroidUiSettings(
            toolbarTitle: 'Resmi Düzenle',
            toolbarColor: const Color(0xFF2196F3),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF1976D2),
            backgroundColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
        ],
      );

      return croppedFile;
    } catch (e) {
      debugPrint('Image cropping failed: $e');
      return null;
    }
  }

  static Future<String> _saveImageToAppDirectory(String imagePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = path.join(appDir.path, 'patient_images');

      // Create directory if it doesn't exist
      await Directory(imageDir).create(recursive: true);

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      final String newPath = path.join(imageDir, fileName);

      // Copy file to new location
      await File(imagePath).copy(newPath);

      return newPath;
    } catch (e) {
      throw Exception('Resim kaydedilemedi: $e');
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
      debugPrint('Image could not be deleted: $e');
    }
  }

  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;

    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Widget buildImageWidget({
    required String? imagePath,
    required double size,
    Widget? placeholder,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return placeholder ??
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: Icon(
              Icons.person,
              size: size * 0.6,
              color: Colors.grey[400],
            ),
          );
    }

    return FutureBuilder<bool>(
      future: imageExists(imagePath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.file(
              File(imagePath),
              width: size,
              height: size,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return placeholder ??
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(size / 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: size * 0.6,
                        color: Colors.grey[400],
                      ),
                    );
              },
            ),
          );
        }

        return placeholder ??
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(size / 2),
              ),
              child: Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.grey[400],
              ),
            );
      },
    );
  }

  static void showImagePickerDialog(
    BuildContext context, {
    required VoidCallback onCameraSelected,
    required VoidCallback onGallerySelected,
    VoidCallback? onRemoveSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.of(context).pop();
                  onGallerySelected();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  onCameraSelected();
                },
              ),
              if (onRemoveSelected != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Resmi Kaldır',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onRemoveSelected();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('İptal'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
