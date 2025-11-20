import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class FileDownloadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Request storage permissions with a direct dialog
  Future<bool> requestStoragePermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true; // iOS doesn't need this

    try {
      print('🔐 Requesting storage permissions...');
      
      // Check multiple permission types for Android
      bool hasPermission = false;
      
      // For Android 13+ (API 33+), use media permissions
      if (await _checkAndroidVersion(33)) {
        print('📱 Android 13+ detected, using media permissions');
        
        // Check media permissions
        final imageStatus = await Permission.photos.status;
        final videoStatus = await Permission.videos.status;
        final audioStatus = await Permission.audio.status;
        
        print('📸 Photos permission: $imageStatus');
        print('🎥 Videos permission: $videoStatus');
        print('🎵 Audio permission: $audioStatus');
        
        if (imageStatus.isGranted && videoStatus.isGranted && audioStatus.isGranted) {
          hasPermission = true;
        } else {
          // Request media permissions
          final imageResult = await Permission.photos.request();
          final videoResult = await Permission.videos.request();
          final audioResult = await Permission.audio.request();
          
          hasPermission = imageResult.isGranted && videoResult.isGranted && audioResult.isGranted;
        }
      } else {
        // For Android 12 and below, use storage permission
        print('📱 Android 12 or below detected, using storage permission');
        
        final storageStatus = await Permission.storage.status;
        print('💾 Storage permission status: $storageStatus');
        
        if (storageStatus.isGranted) {
          hasPermission = true;
        } else if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          hasPermission = result.isGranted;
        }
      }
      
      // If still no permission, try manage external storage
      if (!hasPermission) {
        print('🔄 Trying manage external storage permission...');
        final manageStatus = await Permission.manageExternalStorage.status;
        
        if (manageStatus.isGranted) {
          hasPermission = true;
        } else if (manageStatus.isDenied) {
          final result = await Permission.manageExternalStorage.request();
          hasPermission = result.isGranted;
        }
      }
      
      if (hasPermission) {
        print('✅ Storage permissions granted successfully!');
        return true;
      }
      
      // Show settings dialog if permissions are permanently denied
      print('🚨 Permissions denied, showing settings dialog');
      return await _showPermissionSettingsDialog(context);
      
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check Android version
  Future<bool> _checkAndroidVersion(int targetVersion) async {
    try {
      if (Platform.isAndroid) {
        // This is a simplified check - in production you might want to use device_info_plus
        return true; // Assume Android 13+ for now
      }
      return false;
    } catch (e) {
      print('❌ Error checking Android version: $e');
      return false;
    }
  }

  /// Show dialog to open app settings for permissions
  Future<bool> _showPermissionSettingsDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'This app needs storage permission to download files to your device. '
          'Please grant the permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Download a file from Firebase Storage
  Future<FileDownloadResult> downloadFile({
    required String filePath,
    required String fileName,
    String? customFileName,
    required BuildContext context, // Add context for permission dialog
  }) async {
    try {
      print('🔄 Starting download: $filePath');
      
      // Request storage permission with dialog
      final hasPermission = await requestStoragePermissions(context);
      if (!hasPermission) {
        return FileDownloadResult(
          success: false,
          error: 'Storage permission denied. Please grant permission in app settings.',
          file: null,
        );
      }

      // Get the file reference
      final ref = _storage.ref().child(filePath);
      
      // Get file metadata
      final metadata = await ref.getMetadata();
      final fileSize = metadata.size ?? 0;
      
      print('📁 File size: ${_formatFileSize(fileSize)}');

      // Get download directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        // Try multiple download directories
        final possibleDirs = [
          Directory('/storage/emulated/0/Download'),
          Directory('/storage/emulated/0/Downloads'),
          await getExternalStorageDirectory(),
          await getApplicationDocumentsDirectory(),
        ];

        for (final dir in possibleDirs) {
          if (dir != null && await dir.exists()) {
            downloadDir = dir;
            print('📁 Using download directory: ${dir.path}');
            break;
          }
        }

        if (downloadDir == null) {
          // Create Downloads directory if it doesn't exist
          downloadDir = Directory('/storage/emulated/0/Download');
          await downloadDir.create(recursive: true);
          print('📁 Created download directory: ${downloadDir.path}');
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        return FileDownloadResult(
          success: false,
          error: 'Could not access download directory',
          file: null,
        );
      }

      // Create file path
      final displayName = customFileName ?? fileName;
      final localFile = File('${downloadDir.path}/$displayName');
      
      print('💾 Downloading to: ${localFile.path}');

      // Download the file
      await ref.writeToFile(localFile);
      
      print('✅ Download completed successfully!');
      
      return FileDownloadResult(
        success: true,
        error: null,
        file: localFile,
        fileSize: fileSize,
      );
      
    } catch (e) {
      print('❌ Download failed: $e');
      return FileDownloadResult(
        success: false,
        error: 'Download failed: $e',
        file: null,
      );
    }
  }

  /// Open a downloaded file
  Future<bool> openFile(File file) async {
    try {
      print('🔓 Opening file: ${file.path}');
      
      if (!await file.exists()) {
        print('❌ File does not exist: ${file.path}');
        return false;
      }

      final result = await OpenFile.open(file.path);
      print('📱 Open file result: $result');
      
      return result.type == ResultType.done;
    } catch (e) {
      print('❌ Error opening file: $e');
      return false;
    }
  }

  /// Get file download URL (for web or direct access)
  Future<String?> getDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting download URL: $e');
      return null;
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file extension from filename
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  /// Get file icon based on extension
  String getFileIcon(String fileName) {
    final ext = getFileExtension(fileName);
    
    switch (ext) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'xls':
      case 'xlsx':
        return '📈';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
      case 'aac':
        return '🎵';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📁';
    }
  }
}

/// Result of file download operation
class FileDownloadResult {
  final bool success;
  final String? error;
  final File? file;
  final int? fileSize;

  FileDownloadResult({
    required this.success,
    this.error,
    this.file,
    this.fileSize,
  });

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
