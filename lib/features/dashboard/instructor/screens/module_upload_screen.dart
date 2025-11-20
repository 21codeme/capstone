import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/services/module_service.dart';
import '../../../../core/services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/section_service.dart';

class ModuleUploadScreen extends StatefulWidget {
  const ModuleUploadScreen({super.key});

  @override
  State<ModuleUploadScreen> createState() => _ModuleUploadScreenState();
}

class _ModuleUploadScreenState extends State<ModuleUploadScreen> {
  final ModuleService _moduleService = ModuleService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final SectionService _sectionService = SectionService();
  
  File? _selectedFile;
  String _fileName = '';
  String _moduleTitle = '';
  String _selectedCategory = 'Understanding Movements';
  String _description = '';
  String _videoUrl = ''; // Video URL field
  DateTime? _dueDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'Understanding Movements',
    'Musculoskeletal Basis',
    'Discrete Skills',
    'Throwing & Catching',
    'Serial Skills',
    'Continuous Skills',
  ];

  // Section and Year Level selection state
  List<Map<String, dynamic>> _sections = [];
  List<String> _assignedSectionNames = [];
  List<String> _assignedYearLevels = [];
  String? _selectedSectionId;
  String? _selectedSectionName;
  String? _selectedYearLevel;
  bool _isLoadingSections = false;
  // NEW: Course selection and mapping from Year+Section → Course
  String? _selectedCourse;
  Map<String, String> _courseByYearSection = {};

  @override
  void initState() {
    super.initState();
    _loadInstructorConstraints();
    _loadInstructorSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional header to match Create Quiz screen style without blue AppBar
            Text(
              'Upload Module',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // File Selection
            _buildFileSelection(),
            const SizedBox(height: 16),

            // Module details (title, category, description)
            _buildModuleDetailsCard(),
            const SizedBox(height: 16),

          // Target audience (year level, section)
          _buildTargetAudienceCard(),
          const SizedBox(height: 16),

            // Removed schedule selection per request
            const SizedBox(height: 24),

            // Upload Button
            _buildUploadButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFileSelection() {
    return _SectionCard(
      title: 'Select Module File',
      child: Column(
        children: [
          Icon(
            _selectedFile != null ? Icons.file_present : Icons.upload_file,
            size: 48,
            color: _selectedFile != null ? AppColors.successGreen : AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFile != null ? 'File Selected' : 'Choose a file to upload',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFile != null ? _fileName : 'Accepted: PDF, DOC, PPT, MP4, MP3',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: Icon(_selectedFile != null ? Icons.change_circle : Icons.file_upload),
            label: Text(_selectedFile != null ? 'Change File' : 'Browse Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Modules tab active
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushNamed(context, '/instructor-dashboard');
              break;
            case 1: // Modules (current)
              break;
            case 2: // Quiz
              Navigator.pushNamed(context, '/quiz');
              break;
            case 3: // Settings
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.textTheme.bodySmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Modules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildModuleDetailsCard() {
    return _SectionCard(
      title: 'Module Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Module Title',
            hint: 'Enter module title',
            value: _moduleTitle,
            onChanged: (value) => setState(() => _moduleTitle = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Module Category'),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Description (Optional)',
            hint: 'Enter module description',
            value: _description,
            onChanged: (value) => setState(() => _description = value),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Video URL (Optional)',
            hint: 'Enter video link (YouTube, Vimeo, etc.)',
            value: _videoUrl,
            onChanged: (value) => setState(() => _videoUrl = value),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAudienceCard() {
    return _SectionCard(
      title: 'Target Audience',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select year level and section. Course resolves automatically.',
            style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _buildYearLevelSelection(),
          const SizedBox(height: 10),
          _buildSectionSelection(),
          if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Selected: ${_selectedCourse} • ${_selectedYearLevel} • Section ${_selectedSectionName}',
                    style: AppTextStyles.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Module Category',
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: AppTextStyles.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearLevelSelection() {
    // Use assigned levels if present, else default First–Fifth Year
    final List<String> levels = _assignedYearLevels.isNotEmpty
        ? _assignedYearLevels
        : const ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Year Level',
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedYearLevel,
              isExpanded: true,
              hint: const Text('Select year level'),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
              items: levels.map((yl) => DropdownMenuItem<String?>(
                    value: yl,
                    child: Text(yl),
                  )).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedYearLevel = newValue;
                  // Reset section and course selection on year change
                  _selectedSectionId = null;
                  _selectedSectionName = null;
                  _selectedCourse = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSelection() {
    // Mirror Target Year Level logic: use assigned values or sensible defaults
    final List<String> sections = _assignedSectionNames.isNotEmpty
        ? _assignedSectionNames
        : const ['A','B','C','D','E','F','G','H'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Section',
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSectionName,
              isExpanded: true,
              hint: const Text('Select section'),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
              items: sections.map((sec) => DropdownMenuItem<String?>(
                    value: sec,
                    child: Text(sec),
                  )).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSectionName = newValue;
                  // Track a selection id to satisfy _canUpload; this is a sentinel
                  _selectedSectionId = newValue == null
                      ? null
                      : 'ASSIGNED::' + _normalizeSectionToken(newValue).toUpperCase();
                  // NEW: Resolve course from assignments mapping using selected year + section
                  _selectedCourse = (_selectedYearLevel != null && newValue != null)
                      ? _courseByYearSection['${_selectedYearLevel}::${newValue}']
                      : null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateSelection() {
    // Schedule UI removed; return an empty widget.
    return const SizedBox.shrink();
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canUpload() ? _uploadModule : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Upload Module',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'ppt', 'pptx', 
          'mp4', 'avi', 'mov', 'mp3', 'wav'
        ],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showMessage('Error picking file: $e', isError: true);
    }
  }

  Future<void> _selectDueDate() async {
    // Schedule selection removed; function intentionally left as a no-op.
    return;
  }

  bool _canUpload() {
    return _selectedFile != null && 
           _moduleTitle.trim().isNotEmpty && 
           !_isLoading &&
           _selectedYearLevel != null &&
           _selectedSectionId != null &&
           _selectedCourse != null; // Require course to be resolved
  }

  Future<void> _uploadModule() async {
    if (!_canUpload()) return;

    // Additional validation
    if (_selectedFile == null) {
      _showMessage('Please select a file to upload', isError: true);
      return;
    }

    if (_moduleTitle.trim().isEmpty) {
      _showMessage('Please enter a module title', isError: true);
      return;
    }

    if (_selectedYearLevel == null || _selectedYearLevel!.isEmpty) {
      _showMessage('Please select a year level', isError: true);
      return;
    }

    // If a section is selected, ensure we have a matching name
    if (_selectedSectionId == null || (_selectedSectionName == null || _selectedSectionName!.isEmpty)) {
      _showMessage('Please select a section', isError: true);
      return;
    }

    // Check file size (limit to 50MB)
    final fileSize = await _selectedFile!.length();
    if (fileSize > 50 * 1024 * 1024) {
      _showMessage('File size must be less than 50MB', isError: true);
      return;
    }

    // Check if file exists and is readable
    if (!await _selectedFile!.exists()) {
      _showMessage('Selected file no longer exists', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        _showMessage('User not authenticated', isError: true);
        return;
      }

      print('🚀 Starting module upload for user: ${currentUser.uid}');
      print('📁 File path: ${_selectedFile!.path}');
      print('📊 File size: $fileSize bytes');
      print('🎯 Year Level: ${_selectedYearLevel}');
      print('🎯 Section: ${_selectedSectionName}');
      print('🎓 Course: ${_selectedCourse}');
      
      final result = await _moduleService.uploadModule(
        file: _selectedFile!,
        moduleTitle: _moduleTitle.trim(),
        category: _selectedCategory,
        description: _description.trim(),
        videoUrl: _videoUrl.trim().isNotEmpty ? _videoUrl.trim() : null,
        dueDate: _dueDate,
        sectionId: _selectedSectionId,
        sectionName: _selectedSectionName,
        yearLevel: _selectedYearLevel,
        course: _selectedCourse,
      );

      if (result['success'] == true) {
        _showMessage('Module uploaded successfully! 🎉', isError: false);
        
        // Reset form
        setState(() {
          _selectedFile = null;
          _fileName = '';
          _moduleTitle = '';
          _description = '';
          _videoUrl = '';
          _dueDate = null;
          _selectedSectionId = null;
          _selectedSectionName = null;
          _selectedYearLevel = null;
        });

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        // Show detailed error information
        String errorDetails = result['message'] ?? 'Unknown error';
        if (result['error'] != null) {
          errorDetails += '\n\nTechnical details: ${result['error']}';
        }
        _showDetailedError('Upload Failed', errorDetails);
      }
    } catch (e) {
      print('❌ Exception during upload: $e');
      _showDetailedError('Upload Exception', 'An unexpected error occurred:\n$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDetailedError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The module upload failed. Here are the details:',
                style: AppTextStyles.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                ),
                child: Text(
                  message,
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Common solutions:',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text('• Check your internet connection'),
              Text('• Verify Firebase permissions'),
              Text('• Try uploading a smaller file'),
              Text('• Ensure you\'re logged in'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadModule(); // Retry upload
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Removed date formatting helper; schedule selection UI is not shown.

  String _normalizeSectionToken(String input) {
    final cleaned = input.trim();
    final upper = cleaned.toUpperCase();
    final noPrefix = upper.replaceFirst(RegExp(r'^SECTION\s+'), '');
    return noPrefix.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  void _loadInstructorConstraints() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.currentUser?.uid;
      if (uid == null) {
        return;
      }

      final data = await _authService.getUserData(uid);

      // Prefer combined assignments: assignedYearSectionCourses (e.g., "3rd Year A | BS Computer Science")
      final combined = (data?['assignedYearSectionCourses'] as List?)
              ?.map((e) => e.toString())
              .toList() ?? [];
      List<String> sections = [];
      List<String> yearLevels = [];
      final Map<String, String> courseMap = {}; // NEW: Map Year+Section to Course
      if (combined.isNotEmpty) {
        for (final entry in combined) {
          final raw = entry.trim();
          if (raw.isEmpty) continue;
          // Expected format: "<Year Level> <Section> | <Course>"
          final parts = raw.split('|');
          final left = parts.first.trim();
          final courseName = parts.length > 1 ? parts[1].trim() : null;
          final match = RegExp(r'^(.*)\s([A-H])$').firstMatch(left);
          if (match != null) {
            final yl = match.group(1)!.trim();
            final sec = match.group(2)!.trim();
            if (sec.isNotEmpty) sections.add(sec);
            if (yl.isNotEmpty) yearLevels.add(yl);
            if (courseName != null && courseName.isNotEmpty) {
              courseMap['$yl::$sec'] = courseName;
            }
          } else {
            // Fallback parsing: last token as section
            final tokens = left.split(' ');
            final sec = tokens.isNotEmpty ? tokens.last.trim() : '';
            final yl = tokens.length > 1
                ? tokens.sublist(0, tokens.length - 1).join(' ').trim()
                : left;
            if (sec.isNotEmpty) sections.add(sec);
            if (yl.isNotEmpty) yearLevels.add(yl);
            if (courseName != null && courseName.isNotEmpty) {
              courseMap['$yl::$sec'] = courseName;
            }
          }
        }
        // Deduplicate
        sections = sections.toSet().toList();
        yearLevels = yearLevels.toSet().toList();
      } else {
        // No legacy fallback
        sections = [];
        yearLevels = [];
      }

      setState(() {
        _assignedSectionNames = sections;
        _assignedYearLevels = yearLevels;
        _courseByYearSection = courseMap; // NEW: store mapping
        if (_selectedYearLevel != null && !_assignedYearLevels.contains(_selectedYearLevel)) {
          _selectedYearLevel = null;
        }
        if (_selectedSectionName != null && !_assignedSectionNames.contains(_selectedSectionName)) {
          _selectedSectionId = null;
          _selectedSectionName = null;
        }
        // If both year and section are selected, resolve course now
        if (_selectedYearLevel != null && _selectedSectionName != null) {
          _selectedCourse = _courseByYearSection['${_selectedYearLevel}::${_selectedSectionName}'];
        }
      });
    } catch (e) {
      _showMessage('Failed to load instructor constraints: $e', isError: true);
    }
  }

  void _loadInstructorSections() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        return;
      }
      setState(() {
        _isLoadingSections = true;
      });
      _sectionService.getSectionsByInstructor(currentUser.uid).listen((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'sectionName': (data['sectionName'] as String? ?? '').trim(),
            'yearLevel': (data['yearLevel'] as String?)?.trim(),
          };
        }).toList();
        // Apply filtering by assigned sections with fallback to instructor-owned list
        final filtered = _assignedSectionNames.isEmpty
            ? list
            : list.where((s) {
                final sectionName = ((s['sectionName'] as String?) ?? '').trim().toLowerCase();
                return _assignedSectionNames.any((as) => as.trim().toLowerCase() == sectionName);
              }).toList();
        setState(() {
          _sections = filtered;
          _isLoadingSections = false;
          // Clear selection if it no longer exists
          if (_selectedSectionId != null && !_sections.any((s) => s['id'] == _selectedSectionId)) {
            _selectedSectionId = null;
            _selectedSectionName = null;
          }
        });
      }, onError: (e) {
        setState(() {
          _isLoadingSections = false;
        });
        _showMessage('Failed to load sections: $e', isError: true);
      });
    } catch (e) {
      setState(() {
        _isLoadingSections = false;
      });
      _showMessage('Error loading sections: $e', isError: true);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
