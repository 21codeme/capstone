import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePictureService {
  static final ProfilePictureService _instance = ProfilePictureService._internal();
  factory ProfilePictureService() => _instance;
  ProfilePictureService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      debugPrint('Requesting photos permission...');
      
      // Check current permission status
      PermissionStatus status = await Permission.photos.status;
      
      if (status.isDenied) {
        // Request permission
        status = await Permission.photos.request();
        debugPrint('Photos permission status after request: $status');
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('Photos permission permanently denied, opening app settings...');
        await openAppSettings();
        return null;
      }
      
      if (status.isDenied) {
        debugPrint('Photos permission denied');
        return null;
      }
      
      debugPrint('Photos permission granted, opening gallery...');
      
      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      debugPrint('Gallery picker result: ${image?.path}');
      
      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          debugPrint('Image file exists: ${file.path}');
          return file;
        } else {
          debugPrint('Image file does not exist: ${file.path}');
          return null;
        }
      }
      
      debugPrint('No image selected from gallery');
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take photo with camera
  Future<File?> takePhotoWithCamera() async {
    try {
      debugPrint('Requesting camera permission...');
      
      // Check current permission status
      PermissionStatus status = await Permission.camera.status;
      
      if (status.isDenied) {
        // Request permission
        status = await Permission.camera.request();
        debugPrint('Camera permission status after request: $status');
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('Camera permission permanently denied, opening app settings...');
        await openAppSettings();
        return null;
      }
      
      if (status.isDenied) {
        debugPrint('Camera permission denied');
        return null;
      }
      
      debugPrint('Camera permission granted, opening camera...');
      
      // Take photo with camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      debugPrint('Camera picker result: ${image?.path}');
      
      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          debugPrint('Camera image file exists: ${file.path}');
          return file;
        } else {
          debugPrint('Camera image file does not exist: ${file.path}');
          return null;
        }
      }
      
      debugPrint('No image taken with camera');
      return null;
    } catch (e) {
      debugPrint('Error taking photo with camera: $e');
      return null;
    }
  }

  /// Show image picker dialog with safer context handling
  Future<File?> showImagePickerDialog(BuildContext parentContext) async {
    try {
      debugPrint('Showing image picker dialog...');
      return await showDialog<File?>(
        context: parentContext,
        barrierDismissible: false, // Prevent accidental dismissal
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Select Profile Picture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select an existing photo'),
                  onTap: () async {
                    debugPrint('Gallery option tapped');
                    try {
                      final file = await pickImageFromGallery();
                      if (file != null) {
                        debugPrint('Gallery image selected: ${file.path}');
                        // Return the file to the calling context
                        Navigator.of(dialogContext).pop(file);
                      } else {
                        debugPrint('No gallery image selected');
                        // Show error message
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('No image selected from gallery'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Return null to indicate no selection
                        Navigator.of(dialogContext).pop(null);
                      }
                    } catch (e) {
                      debugPrint('Error in gallery selection: $e');
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Error accessing gallery: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Return null to indicate error
                      Navigator.of(dialogContext).pop(null);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Take a Photo'),
                  subtitle: const Text('Use camera to take a new photo'),
                  onTap: () async {
                    debugPrint('Camera option tapped');
                    try {
                      final file = await takePhotoWithCamera();
                      
                      if (file != null) {
                        debugPrint('Camera image taken: ${file.path}');
                        // Return the file to the calling context
                        Navigator.of(dialogContext).pop(file);
                      } else {
                        debugPrint('No camera image taken');
                        // Show error message
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('No photo taken with camera'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Return null to indicate no selection
                        Navigator.of(dialogContext).pop(null);
                      }
                    } catch (e) {
                      debugPrint('Error in camera selection: $e');
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Error accessing camera: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Return null to indicate error
                      Navigator.of(dialogContext).pop(null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint('Cancel button tapped');
                  Navigator.of(dialogContext).pop(null); // Return null for cancellation
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing image picker dialog: $e');
      return null;
    }
  }

  /// Convert image file to base64 string for storage
  Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      return null;
    }
  }

  /// Convert base64 string back to image
  Image? base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 40);
        },
      );
    } catch (e) {
      debugPrint('Error converting base64 to image: $e');
      return null;
    }
  }

  /// Save image to local storage
  Future<String?> saveImageToLocal(File imageFile, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/profile_pictures');
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final fileName = 'profile_$userId.jpg';
      final savedImage = await imageFile.copy('${imageDir.path}/$fileName');
      
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image to local storage: $e');
      return null;
    }
  }

  /// Get image from local storage
  File? getImageFromLocal(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting image from local storage: $e');
      return null;
    }
  }

  /// Delete image from local storage
  Future<bool> deleteImageFromLocal(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image from local storage: $e');
      return false;
    }
  }

  /// Test method to check permissions and image picker functionality
  Future<Map<dynamic, dynamic>> testPermissions() async {
    final results = <String, dynamic>{};
    
    try {
      // Test camera permission
      final cameraStatus = await Permission.camera.status;
      results['camera_status'] = cameraStatus.name;
      
      // Test photos permission
      final photosStatus = await Permission.photos.status;
      results['photos_status'] = photosStatus.name;
      
      debugPrint('Permission test results: $results');
      
    } catch (e) {
      results['error'] = e.toString();
      debugPrint('Error testing permissions: $e');
    }
    
    return results;
  }

  /// Simplified image picker for testing
  Future<File?> pickImageSimple(ImageSource source) async {
    try {
      debugPrint('Picking image from source: $source');
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        final file = File(image.path);
        debugPrint('Image picked: ${file.path}');
        return file;
      }
      
      debugPrint('No image picked');
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
