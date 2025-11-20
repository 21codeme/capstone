import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class PermissionTestScreen extends StatefulWidget {
  const PermissionTestScreen({super.key});

  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
        Permission.accessMediaLocation,
      ];

      final statuses = <Permission, PermissionStatus>{};
      
      for (final permission in permissions) {
        final status = await permission.status;
        statuses[permission] = status;
        print('🔐 ${permission.toString()}: $status');
      }

      setState(() {
        _permissionStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error checking permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    try {
      print('🔄 Requesting ${permission.toString()}...');
      final status = await permission.request();
      
      setState(() {
        _permissionStatuses[permission] = status;
      });
      
      print('✅ ${permission.toString()} result: $status');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${permission.toString()}: $status'),
          backgroundColor: status.isGranted ? AppColors.successGreen : AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error requesting ${permission.toString()}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permission: $e'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ Error opening app settings: $e');
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppColors.successGreen;
      case PermissionStatus.denied:
        return AppColors.warningOrange;
      case PermissionStatus.permanentlyDenied:
        return AppColors.errorRed;
      case PermissionStatus.restricted:
        return AppColors.errorRed;
      case PermissionStatus.limited:
        return AppColors.warningOrange;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅ Granted';
      case PermissionStatus.denied:
        return '❌ Denied';
      case PermissionStatus.permanentlyDenied:
        return '🚨 Permanently Denied';
      case PermissionStatus.restricted:
        return '🚫 Restricted';
      case PermissionStatus.limited:
        return '⚠️ Limited';
      default:
        return '❓ Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllPermissions,
            tooltip: 'Refresh Permissions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.security,
                          size: 48,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Storage Permission Test',
                          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Test and manage all storage-related permissions',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Permission List
                  Text(
                    'Permission Status',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ..._permissionStatuses.entries.map((entry) {
                    final permission = entry.key;
                    final status = entry.value;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getPermissionIcon(permission),
                            color: _getStatusColor(status),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _getPermissionName(permission),
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _getStatusText(status),
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: status.isGranted
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.successGreen,
                              )
                            : ElevatedButton(
                                onPressed: () => _requestPermission(permission),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Grant'),
                              ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAppSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Open App Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warningOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkAllPermissions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh All Permissions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ℹ️ Permission Information',
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Storage permissions are required to download files to your device\n'
                          '• Android 13+ uses media permissions instead of general storage\n'
                          '• If permissions are permanently denied, use App Settings\n'
                          '• Some permissions may require device restart after granting',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return Icons.storage;
      case Permission.manageExternalStorage:
        return Icons.folder_shared;
      case Permission.photos:
        return Icons.photo_library;
      case Permission.videos:
        return Icons.video_library;
      case Permission.audio:
        return Icons.audio_file;
      case Permission.accessMediaLocation:
        return Icons.location_on;
      default:
        return Icons.security;
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'Storage Access';
      case Permission.manageExternalStorage:
        return 'Manage External Storage';
      case Permission.photos:
        return 'Photos & Images';
      case Permission.videos:
        return 'Videos';
      case Permission.audio:
        return 'Audio Files';
      case Permission.accessMediaLocation:
        return 'Media Location';
      default:
        return permission.toString();
    }
  }
}





