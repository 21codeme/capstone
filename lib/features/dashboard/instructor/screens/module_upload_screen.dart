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
import 'package:permission_handler/permission_handler.dart';

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
  bool _isPickingFile = false; // Flag to prevent multiple simultaneous file picker calls

  final List<String> _categories = [
    'Understanding Movements',
    'Musculoskeletal Basis',
    'Discrete Skills',
    'Throwing & Catching',
    'Serial Skills',
    'Continuous Skills',
    'Neuromuscular Basis of Movement Competency',
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Module',
          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: AppColors.textWhite,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Module',
                              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload your educational content',
                              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textWhite.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // File Selection
            _buildFileSelection(),
            const SizedBox(height: 20),

            // Module details (title, category, description)
            _buildModuleDetailsCard(),
            const SizedBox(height: 20),

            // Target audience (year level, section)
            _buildTargetAudienceCard(),
            const SizedBox(height: 24),

            // Upload Button
            _buildUploadButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFileSelection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedFile != null 
              ? AppColors.successGreen.withOpacity(0.3)
              : AppColors.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_selectedFile != null 
                ? AppColors.successGreen 
                : AppColors.primaryBlue).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.textBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (_selectedFile != null 
                  ? AppColors.successGreen 
                  : AppColors.primaryBlue).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
              size: 64,
              color: _selectedFile != null ? AppColors.successGreen : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFile != null ? 'File Selected' : 'Choose a file to upload',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFile != null ? _fileName : 'Accepted: PDF, DOC, DOCX, PPT, PPTX, MP4, MP3',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isPickingFile ? null : _pickFile,
            icon: _isPickingFile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _selectedFile != null ? Icons.change_circle : Icons.folder_open,
                    size: 20,
                  ),
            label: Text(
              _isPickingFile
                  ? 'Opening file picker...'
                  : (_selectedFile != null ? 'Change File' : 'Browse Files'),
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedFile != null 
                  ? AppColors.successGreen 
                  : AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.textBlack.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Module Details',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Module Title',
            hint: 'Enter module title',
            value: _moduleTitle,
            onChanged: (value) => setState(() => _moduleTitle = value),
            icon: Icons.title,
          ),
          const SizedBox(height: 20),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Description (Optional)',
            hint: 'Enter module description',
            value: _description,
            onChanged: (value) => setState(() => _description = value),
            maxLines: 3,
            icon: Icons.description,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Video URL (Optional)',
            hint: 'Enter video link (YouTube, Vimeo, etc.)',
            value: _videoUrl,
            onChanged: (value) => setState(() => _videoUrl = value),
            maxLines: 1,
            icon: Icons.video_library,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
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
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            hint: Text(
              'Select category',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            items: _categories.map((c) => DropdownMenuItem<String>(
              value: c,
              child: Text(
                c,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: Colors.black,
                ),
              ),
            )).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCategory = val);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(
                Icons.category,
                color: AppColors.primaryBlue,
              ),
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryBlue,
            ),
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: Colors.black,
            ),
            selectedItemBuilder: (BuildContext context) {
              return _categories.map((String category) {
                return Text(
                  category,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAudienceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.textBlack.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: AppColors.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Target Audience',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select year level and section. Course resolves automatically.',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildYearLevelSelection(),
          const SizedBox(height: 20),
          _buildSectionSelection(),
          if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successGreen.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Audience',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedCourse} • ${_selectedYearLevel} • Section ${_selectedSectionName}',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    IconData? icon,
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
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: icon != null ? Icon(
              icon,
              color: AppColors.primaryBlue,
            ) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String?>(
            value: _selectedYearLevel,
            isExpanded: true,
            hint: const Text('Select year level'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: AppColors.primaryBlue,
              ),
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryBlue,
            ),
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
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String?>(
            value: _selectedSectionName,
            isExpanded: true,
            hint: const Text('Select section'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(
                Icons.class_,
                color: AppColors.primaryBlue,
              ),
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryBlue,
            ),
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
      ],
    );
  }

  Widget _buildDueDateSelection() {
    // Schedule UI removed; return an empty widget.
    return const SizedBox.shrink();
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _canUpload() && !_isLoading
              ? [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
                ]
              : [
                  AppColors.grey300,
                  AppColors.grey300,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _canUpload() && !_isLoading
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _canUpload() && !_isLoading ? _uploadModule : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload Module',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickFile() async {
    // Prevent multiple simultaneous file picker calls
    if (_isPickingFile) {
      return;
    }

    setState(() {
      _isPickingFile = true;
    });

    try {
      // Clear any existing file picker state first
      try {
        await FilePicker.platform.clearTemporaryFiles();
      } catch (e) {
        print('⚠️ Could not clear temporary files: $e');
      }

      // Request storage permissions for Android
      if (Platform.isAndroid) {
        bool hasPermission = await _requestStoragePermissions();
        if (!hasPermission) {
          _showMessage('Storage permission is required to select files. Please grant permission in app settings.', isError: true);
          setState(() {
            _isPickingFile = false;
          });
          return;
        }
      }

      // Add a delay to ensure any previous picker is fully closed
      await Future.delayed(const Duration(milliseconds: 500));
      
      FilePickerResult? result;
      
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf', 'doc', 'docx', 'ppt', 'pptx', 
            'mp4', 'avi', 'mov', 'mp3', 'wav'
          ],
          withData: false, // Don't load file data into memory
          withReadStream: false, // Don't create read stream
          allowMultiple: false, // Single file selection
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            print('⏱️ File picker timeout');
            return null;
          },
        );
      } catch (pickerError) {
        // Handle "already_active" error specifically
        if (pickerError.toString().contains('already_active')) {
          print('🔄 File picker already active, clearing and retrying...');
          // Clear and wait a bit longer
          await Future.delayed(const Duration(seconds: 1));
          try {
            await FilePicker.platform.clearTemporaryFiles();
          } catch (e) {
            print('⚠️ Error clearing: $e');
          }
          
          // Retry once
          await Future.delayed(const Duration(milliseconds: 500));
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'pdf', 'doc', 'docx', 'ppt', 'pptx', 
              'mp4', 'avi', 'mov', 'mp3', 'wav'
            ],
            withData: true, // Load file data for real devices (handles content URIs)
            withReadStream: false,
            allowMultiple: false,
          ).timeout(
            const Duration(seconds: 60),
            onTimeout: () => null,
          );
        } else {
          rethrow;
        }
      }

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        final fileName = pickedFile.name;
        
        print('📁 Selected file: $fileName');
        print('📁 File path: ${pickedFile.path}');
        print('📁 File size: ${pickedFile.size}');
        print('📁 File extension: ${pickedFile.extension}');
        
        // Handle file path - on real devices, path might be null but bytes/data might be available
        if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
          final filePath = pickedFile.path!;
          print('📁 Using file path: $filePath');
          
          final file = File(filePath);
          
          // Verify file exists before setting state
          if (await file.exists()) {
            print('✅ File exists at path: $filePath');
            setState(() {
              _selectedFile = file;
              _fileName = fileName;
            });
            _showMessage('File selected: $fileName', isError: false);
          } else {
            print('❌ File does not exist at path: $filePath');
            // Try to use bytes if available (for content URIs on real devices)
            if (pickedFile.bytes != null) {
              print('📦 Using file bytes instead of path');
              // Save bytes to temporary file
              final tempDir = await Directory.systemTemp.createTemp('module_upload');
              final tempFile = File('${tempDir.path}/$fileName');
              await tempFile.writeAsBytes(pickedFile.bytes!);
              
              setState(() {
                _selectedFile = tempFile;
                _fileName = fileName;
              });
              _showMessage('File selected: $fileName', isError: false);
            } else {
              _showMessage('Selected file does not exist and cannot be accessed', isError: true);
            }
          }
        } else if (pickedFile.bytes != null) {
          // On some devices, path might be null but bytes are available
          print('📦 File path is null, using bytes instead');
          try {
            // Save bytes to temporary file
            final tempDir = await Directory.systemTemp.createTemp('module_upload');
            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(pickedFile.bytes!);
            
            print('✅ Saved file to temp location: ${tempFile.path}');
            setState(() {
              _selectedFile = tempFile;
              _fileName = fileName;
            });
            _showMessage('File selected: $fileName', isError: false);
          } catch (e) {
            print('❌ Error saving file bytes: $e');
            _showMessage('Error accessing file: $e', isError: true);
          }
        } else {
          print('❌ File path is null and bytes are not available');
          _showMessage('File path is not available. Please try selecting the file again.', isError: true);
        }
      } else if (result == null) {
        // User cancelled - don't show error
        print('ℹ️ User cancelled file selection');
      }
    } catch (e) {
      String errorMessage = 'Error picking file';
      
      // Handle specific error types
      if (e.toString().contains('already_active')) {
        errorMessage = 'File picker is busy. Please wait a moment and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Storage permission denied. Please grant permission in app settings.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'File picker timeout. Please try again.';
      } else {
        errorMessage = 'Error picking file: ${e.toString()}';
      }
      
      _showMessage(errorMessage, isError: true);
      print('❌ File picker error: $e');
    } finally {
      // Always reset the flag after picker closes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isPickingFile = false;
          });
        }
      });
    }
  }

  Future<bool> _requestStoragePermissions() async {
    if (!Platform.isAndroid) return true; // iOS doesn't need explicit storage permission for file picker

    try {
      print('🔐 Requesting storage permissions for file picker...');
      
      // For Android 13+ (API 33+), file picker doesn't need explicit permissions
      // But we can check if we have basic access
      bool hasPermission = true;
      
      // For older Android versions, check storage permission
      try {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          hasPermission = result.isGranted;
        } else if (storageStatus.isGranted) {
          hasPermission = true;
        }
      } catch (e) {
        // On newer Android, storage permission might not be needed
        print('ℹ️ Storage permission check not needed: $e');
        hasPermission = true;
      }
      
      print('✅ Storage permission status: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('❌ Error requesting storage permissions: $e');
      // Return true to allow file picker to try anyway
      return true;
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
