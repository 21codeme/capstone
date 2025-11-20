import 'package:flutter/material.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/module_service.dart';
import '../../../../../../core/services/file_download_service.dart';
import 'dart:io';
import 'permission_test_screen.dart';

class ModuleCategoryScreen extends StatefulWidget {
  final String category;
  final Map<String, dynamic>? categoryStats;

  const ModuleCategoryScreen({
    super.key,
    required this.category,
    this.categoryStats,
  });

  @override
  State<ModuleCategoryScreen> createState() => _ModuleCategoryScreenState();
}

class _ModuleCategoryScreenState extends State<ModuleCategoryScreen> {
  final ModuleService _moduleService = ModuleService();
  final FileDownloadService _downloadService = FileDownloadService();
  List<Map<dynamic, dynamic>> _modules = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _downloadingModules = {};

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final modules = await _moduleService.getModulesByCategory(widget.category);
      setState(() {
        _modules = modules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load modules: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Modules',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadModules,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_modules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Modules Available',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Instructors haven\'t uploaded any modules for this category yet.',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category Stats Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.category,
                style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_modules.length} modules available',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Permission Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _requestPermissions(),
                      icon: const Icon(Icons.storage, size: 18),
                      label: const Text('Grant Storage Permission'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openPermissionTest(),
                    icon: const Icon(Icons.security, size: 18),
                    label: const Text('Test Permissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Modules List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _modules.length,
                    itemBuilder: (context, index) {
          final module = _modules[index];
          final moduleId = module['id'] ?? '';
          return _ModuleListItem(
            module: module,
            onTap: () => _openModule(module),
            isDownloading: _downloadingModules[moduleId] ?? false,
          );
        },
          ),
        ),
      ],
    );
  }

  void _openModule(Map<dynamic, dynamic> module) {
    // Open module (could be PDF viewer, video player, etc.)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(module['title'] ?? 'Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructor: ${(module['fullName'] ?? module['instructorName'] ?? 'Unknown').toString()}'),
            Text('File: ${module['fileName'] ?? 'Unknown'}'),
            Text('Size: ${_formatFileSize(module['fileSize'] ?? 0)}'),
            if (module['description']?.isNotEmpty == true)
              Text('Description: ${module['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadModule(module);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadModule(Map<dynamic, dynamic> module) async {
    final moduleId = module['id'] ?? '';
    if (_downloadingModules[moduleId] == true) return; // Prevent multiple downloads
    
    setState(() {
      _downloadingModules[moduleId] = true;
    });

    try {
      // Show downloading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📥 Downloading ${module['title'] ?? 'module'}...'),
          backgroundColor: AppColors.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Get file path from module
      final fileName = module['fileName'] ?? '';
      final moduleTitle = module['title'] ?? 'module';
      final filePath = 'modules/$moduleTitle/$fileName';

      print('🔄 Downloading file: $filePath');

      // Download the file
      final result = await _downloadService.downloadFile(
        filePath: filePath,
        fileName: fileName,
        customFileName: '${moduleTitle}_$fileName',
        context: context, // Pass context for permission dialog
      );

      if (result.success && result.file != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Downloaded successfully! File size: ${result.formattedFileSize}'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                await _downloadService.openFile(result.file!);
              },
            ),
          ),
        );

        // Ask if user wants to open the file
        _showOpenFileDialog(result.file!, module['title'] ?? 'module');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Download failed: ${result.error}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error downloading module: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Download error: $e'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _downloadingModules[moduleId] = false;
      });
    }
  }

  void _showOpenFileDialog(File file, String moduleTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File Downloaded Successfully!'),
        content: Text('Would you like to open "$moduleTitle" now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadService.openFile(file);
            },
            child: Text('Open Now'),
          ),
        ],
      ),
    );
  }

  /// Request storage permissions directly
  Future<void> _requestPermissions() async {
    try {
      final hasPermission = await _downloadService.requestStoragePermissions(context);
      if (hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Storage permission granted! You can now download files.'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Storage permission denied. Please grant permission in app settings.'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error requesting permissions: $e'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Open permission test screen
  void _openPermissionTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PermissionTestScreen(),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ModuleListItem extends StatelessWidget {
  final Map<dynamic, dynamic> module;
  final VoidCallback onTap;
  final bool isDownloading;

  const _ModuleListItem({
    required this.module,
    required this.onTap,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(module['fileExtension'] ?? ''),
            color: AppColors.primaryBlue,
            size: 24,
          ),
        ),
        title: Text(
          module['title'] ?? 'Untitled Module',
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By ${(module['fullName'] ?? module['instructorName'] ?? 'Unknown Instructor').toString()}',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Uploaded ${_formatDate(module['uploadDate'])}',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: isDownloading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              )
            : Icon(
                Icons.download,
                color: AppColors.primaryBlue,
              ),
        onTap: onTap,
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}
