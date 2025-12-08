import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerUtils {
  static Future<File?> pickImageFromGallery() async {
    // Request permission first
    PermissionStatus status;

    if (Platform.isAndroid) {
      // For Android 13+ (SDK 33)
      // We can't easily check SDK version in pure Dart without a plugin,
      // but permission_handler handles the mapping if the manifest is correct.
      // However, checking both is safer.
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        status = photosStatus;
      } else {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          status = storageStatus;
        } else {
          // Request both or just one depending on what we suspect.
          // Requesting photos is the modern way.
          status = await Permission.photos.request();

          // If photos is permanently denied or restricted, try storage (for older Android)
          if (status.isDenied || status.isPermanentlyDenied) {
            status = await Permission.storage.request();
          }
        }
      }
    } else {
      // iOS
      status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
    }

    if (status.isGranted || status.isLimited) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    }
    return null;
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    }
    return null;
  }
}
