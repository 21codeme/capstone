import 'package:flutter/material.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/core/services/section_service.dart';
import 'package:pathfitcapstone/core/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathfitcapstone/core/services/student_progress_service.dart';

class SectionStudentsScreen extends StatefulWidget {
  final String sectionName;
  final String? sectionId; // Make optional
  final String? courseName;
  final String? yearLevel;
  final String? section; // e.g., 'A'
  
  const SectionStudentsScreen({
    super.key,
    required this.sectionName,
    this.sectionId, // Make optional
    this.courseName,
    this.yearLevel,
    this.section,
  });

  @override
  State<SectionStudentsScreen> createState() => _SectionStudentsScreenState();
}

class _SectionStudentsScreenState extends State<SectionStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SectionService _sectionService = SectionService();
  
  // Backed by Firestore
  List<Map<dynamic, dynamic>> _students = [];
  List<Map<dynamic, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }
  
  Future<String> _resolveSectionId() async {
    // If a valid Firestore section document exists for the provided ID, use it.
    try {
      if (widget.sectionId != null && widget.sectionId!.isNotEmpty) {
        final doc = await _sectionService.getSectionById(widget.sectionId!);
        if (doc.exists) {
          return doc.id;
        }
      }
    } catch (_) {
      // Fall through to resolution via attributes
    }

    // Resolve by instructor + attributes (yearLevel, section name)
    final uid = FirebaseAuthService().currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to view section students.');
    }

    // Parse the section name to extract year and section
    // Expected format: "BS Information Technology- 1st Year A" or similar
    String? yearLevel;
    String? sectionName;
    
    // Try to extract year and section from the combined name
    final sectionNameCombined = widget.sectionName.trim();
    
    // Look for year patterns like "1st Year", "2nd Year", etc.
    final yearPattern = RegExp(r'(\d+(?:st|nd|rd|th)\s+Year)', caseSensitive: false);
    final yearMatch = yearPattern.firstMatch(sectionNameCombined);
    if (yearMatch != null) {
      yearLevel = yearMatch.group(1);
    }
    
    // Look for section letter at the end (A, B, C, etc.)
    final sectionPattern = RegExp(r'\b([A-Z])\s*$');
    final sectionMatch = sectionPattern.firstMatch(sectionNameCombined);
    if (sectionMatch != null) {
      sectionName = sectionMatch.group(1);
    }
    
    // If we couldn't parse from the name, try using the provided values
    if (yearLevel == null && widget.yearLevel != null) {
      yearLevel = widget.yearLevel;
    }
    if (sectionName == null && widget.section != null) {
      sectionName = widget.section;
    }

    // Query sections collection with the parsed values
    Query query = FirebaseFirestore.instance
        .collection('sections')
        .where('instructorId', isEqualTo: uid);

    if (yearLevel != null) {
      query = query.where('yearLevel', isEqualTo: yearLevel);
    }
    if (sectionName != null) {
      query = query.where('sectionName', isEqualTo: sectionName);
    }

    final q = await query.limit(1).get();
    if (q.docs.isNotEmpty) {
      return q.docs.first.id;
    }

    // As a last resort, try matching by a human-readable combined name if it was passed
    final String combined = widget.sectionName.trim();
    final all = await FirebaseFirestore.instance
        .collection('sections')
        .where('instructorId', isEqualTo: uid)
        .get();
    for (final d in all.docs) {
      final data = d.data();
      final name = (data['sectionName'] as String?) ?? '';
      final yl = (data['yearLevel'] as String?) ?? '';
      // Simple heuristics: "<year> <section>" appears inside combined title
      final token = yl.isNotEmpty && name.isNotEmpty ? '$yl $name' : name;
      if (token.isNotEmpty && combined.contains(token)) {
        return d.id;
      }
    }

    throw Exception('No matching section found for ${widget.sectionName}. Parsed: year=$yearLevel, section=$sectionName');
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Parse course, year, and section from the sectionName
      // Format: "BS Information Technology - 1st Year A"
      String? course;
      String? yearLevel;
      String? section;
      
      final sectionName = widget.sectionName.trim();
      
      // Extract course (everything before " - ")
      final courseParts = sectionName.split(' - ');
      if (courseParts.length >= 2) {
        course = courseParts[0].trim();
        final remaining = courseParts[1].trim();
        
        // Extract year level and section from remaining part
        // Look for year patterns like "1st Year", "2nd Year", etc.
        final yearPattern = RegExp(r'(\d+(?:st|nd|rd|th)\s+Year)', caseSensitive: false);
        final yearMatch = yearPattern.firstMatch(remaining);
        if (yearMatch != null) {
          yearLevel = yearMatch.group(1);
        }
        
        // Look for section letter at the end (A, B, C, etc.)
        final sectionPattern = RegExp(r'\b([A-Z])\s*$');
        final sectionMatch = sectionPattern.firstMatch(remaining);
        if (sectionMatch != null) {
          section = sectionMatch.group(1);
        }
      }
      
      // Use provided values if parsing failed
      course = course ?? widget.courseName;
      yearLevel = yearLevel ?? widget.yearLevel;
      section = section ?? widget.section;
      
      if (course == null || yearLevel == null || section == null) {
        throw Exception('Could not parse course, year level, and section from section name: $sectionName');
      }
      
      // Query users collection for students matching course, year, and section
      final firestore = FirebaseFirestore.instance;
      
      Query query = firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('course', isEqualTo: course)
          .where('year', isEqualTo: yearLevel)
          .where('section', isEqualTo: section);
      
      final querySnapshot = await query.get();
      
      final List<Map<dynamic, dynamic>> students = [];
      
      for (final userDoc in querySnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String sid = userDoc.id;
        final String sname = (userData['fullName'] ?? userData['name'] ?? 'Unknown Student').toString();
        
        // Compute average progress as grade proxy
        double avg = 0.0;
        try {
          final progress = await StudentProgressService.getStudentProgressData(sid);
          avg = (progress['averageProgress'] ?? 0.0) as double;
        } catch (_) {}
        
        students.add({
          'name': sname,
          'id': sid,
          'course': course,
          'year': yearLevel,
          'section': section,
          'averageGrade': avg.toStringAsFixed(0),
          'avatar': sname.isNotEmpty ? sname[0].toUpperCase() : '?',
          'userData': userData,
        });
      }
      
      setState(() {
        _students = students;
        _filteredStudents = List.from(students);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load students: ${e.toString()}';
        _students = [];
        _filteredStudents = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_students);
        return;
      }
      
      // Parse advanced search query
      final Map<String, String> searchFilters = {};
      String generalQuery = query;
      
      // Extract prefixed search terms
      final RegExp prefixRegex = RegExp(r'\b(section|year|course|fullName):([^\s]+)', caseSensitive: false);
      final matches = prefixRegex.allMatches(query);
      
      for (final match in matches) {
        final prefix = match.group(1)!.toLowerCase();
        final value = match.group(2)!;
        searchFilters[prefix] = value.toLowerCase();
      }
      
      // Remove prefixed terms from general query
      generalQuery = query.replaceAll(prefixRegex, '').trim();
      
      _filteredStudents = _students.where((student) {
        // Check general name search (if no prefix or remaining query)
        bool matchesGeneralQuery = true;
        if (generalQuery.isNotEmpty) {
          matchesGeneralQuery = student['name'].toLowerCase().contains(generalQuery.toLowerCase());
        }
        
        // Check specific field filters
        bool matchesFilters = true;
        
        // section filter - check against student section field
        if (searchFilters.containsKey('section')) {
          final sectionValue = student['section']?.toString().toLowerCase() ?? '';
          matchesFilters = matchesFilters && sectionValue.contains(searchFilters['section']!);
        }
        
        // year filter - check against student year field  
        if (searchFilters.containsKey('year')) {
          final yearValue = student['year']?.toString().toLowerCase() ?? '';
          matchesFilters = matchesFilters && yearValue.contains(searchFilters['year']!);
        }
        
        // course filter - check against student course field
        if (searchFilters.containsKey('course')) {
          final courseValue = student['course']?.toString().toLowerCase() ?? '';
          matchesFilters = matchesFilters && courseValue.contains(searchFilters['course']!);
        }
        
        // fullName filter - check against student name
        if (searchFilters.containsKey('fullname')) {
          matchesFilters = matchesFilters && 
            student['name'].toLowerCase().contains(searchFilters['fullname']!);
        }
        
        return matchesGeneralQuery && matchesFilters;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Info
                    _buildSectionInfo(),
                    const SizedBox(height: 24),
                    
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    
                    // Students List
                    _buildStudentsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Section Students',
              style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sectionName,
            style: AppTextStyles.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.courseName != null) ...[
            Text(
              widget.courseName!,
              style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.yearLevel != null || widget.section != null) ...[
            Text(
              [widget.yearLevel, widget.section].where((e) => (e ?? '').isNotEmpty).join(' '),
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text(
            '${_students.length} students enrolled',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStudents,
        decoration: InputDecoration(
          hintText: 'Search students (use: section:A year:3 course:IT fullName:John)...',
          hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Students',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Text(
              _error!,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.errorRed),
            ),
          )
        else if (_filteredStudents.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'No students found for this section.',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          ..._filteredStudents.map((student) => _buildStudentItem(student)),
      ],
    );
  }

  Widget _buildStudentItem(Map<dynamic, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              student['avatar'],
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ID: ${student['id']}',
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Average Grade: ${student['averageGrade']}%',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Grade Button
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/grade-student',
                arguments: {
                  'studentName': student['name'],
                  'studentId': student['id'],
                  'course': student['course'],
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Grade',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



