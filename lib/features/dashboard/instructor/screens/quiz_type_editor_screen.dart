import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:pathfitcapstone/features/auth/presentation/providers/auth_provider.dart';
import 'package:pathfitcapstone/core/services/section_service.dart';
import 'package:pathfitcapstone/core/services/quiz_service.dart';
import 'package:pathfitcapstone/core/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pathfitcapstone/core/services/quiz_media_service.dart';

class QuizTypeEditorScreen extends StatefulWidget {
  final String topic;
  final String type;
  final String label;

  const QuizTypeEditorScreen({
    super.key,
    required this.topic,
    required this.type,
    required this.label,
  });

  @override
  State<QuizTypeEditorScreen> createState() => _QuizTypeEditorScreenState();
}

class _QuizTypeEditorScreenState extends State<QuizTypeEditorScreen> {
  bool previewMode = false;
  final TextEditingController _titleController = TextEditingController(text: 'Untitled Quiz');
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _timeLimitController = TextEditingController(text: '0');
  final TextEditingController _pointsController = TextEditingController(text: '1');
  bool shuffleQuestions = false;
  bool shuffleOptions = false;

  // Services
  final SectionService _sectionService = SectionService();
  final QuizService _quizService = QuizService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final QuizMediaService _mediaService = QuizMediaService();

  // Instructor constraints and sections from Firebase
  final List<Map<String, dynamic>> _sections = []; // {id, sectionName, yearLevel}
  bool _isLoadingSections = false;

  final Set<String> _courses = <String>{};
  final Map<String, Set<String>> _yearsByCourse = {}; // course -> set(years)
  final Map<String, Set<String>> _sectionsByCourseYear = {}; // "course|year" -> set(sectionNames)
  final List<String> _assignedSectionNames = [];
  final List<String> _assignedYearLevels = [];
  final Map<String, String> _courseByYearSection = {};

  String? _selectedCourse;
  String? _selectedYearLevel;
  String? _selectedSectionId;
  String? _selectedSectionName;
  String? _pendingQuizFolderId;

  // Availability window
  DateTime? _availableFrom;
  DateTime? _availableUntil;

  Future<void> _pickAvailableFrom() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _availableFrom ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _availableFrom != null
          ? TimeOfDay(hour: _availableFrom!.hour, minute: _availableFrom!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _availableFrom = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickAvailableUntil() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _availableUntil ?? _availableFrom ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _availableUntil != null
          ? TimeOfDay(hour: _availableUntil!.hour, minute: _availableUntil!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _availableUntil = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _fmtDT(DateTime? dt) {
    if (dt == null) return 'Not set';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  final List<_MCQuestion> _questions = [
    _MCQuestion(
      text: 'Sample question',
      options: ['Option A', 'Option B', 'Option C', 'Option D'],
      correctIndex: 0,
    ),
  ];

  // True/False and Identification question lists
  final List<_TFQuestion> _tfQuestions = [
    _TFQuestion(text: 'Sample statement', answer: true),
  ];
  final List<_IDQuestion> _idQuestions = [
    _IDQuestion(text: 'Sample question', answer: 'Sample answer'),
  ];
  final List<_UIImageQuestion> _uiQuestions = [
    _UIImageQuestion(
      questionIsImage: true,
      questionText: '',
      questionImageUrl: null,
      identification: false,
      identificationAnswer: '',
      optionsAreImage: true,
      optionsText: const [],
      optionsImageUrls: const ['', ''],
      correctIndex: 0,
    ),
  ];

  // Mixed question entries for Custom quiz type
  final List<_CustomQuestionEntry> _customItems = [];

  bool get _isMultipleChoice =>
      widget.type.toLowerCase().contains('multiple') || widget.label.toLowerCase().contains('multiple');
  bool get _isTrueFalse =>
      widget.type.toLowerCase().contains('true') || widget.label.toLowerCase().contains('true');
  bool get _isIdentification =>
      widget.type.toLowerCase().contains('identification') || widget.label.toLowerCase().contains('identification');
  bool get _isUnderstandImage => widget.type.toLowerCase().contains('understand-image') || widget.label.toLowerCase().contains('understand');
  bool get _isCustom => widget.type.toLowerCase().contains('custom') || widget.label.toLowerCase().contains('custom');
  

  @override
  void initState() {
    super.initState();
    _loadInstructorConstraints();
    _subscribeInstructorSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create ${widget.label}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: (_isMultipleChoice || _isUnderstandImage || _isCustom)
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _ModeToggle(
                    previewMode: previewMode,
                    onChanged: (v) => setState(() => previewMode = v),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(text: widget.topic, icon: Icons.topic_outlined),
                  _Chip(text: widget.label, icon: Icons.category_outlined),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isMultipleChoice
                    ? _buildMultipleChoiceContent(context)
                    : _isTrueFalse
                        ? _buildTrueFalseContent(context)
                        : _isIdentification
                            ? _buildIdentificationContent(context)
                            : _isUnderstandImage
                                ? _buildUnderstandImageContent(context)
                                : _isCustom
                                    ? _buildCustomContent(context)
                                    : _buildPlaceholder(),
              ),
              const SizedBox(height: 12),
              _buildCreateButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            ' editor coming soon',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is a placeholder for the "" quiz type.',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Quiz Details',
                  child: Column(
                    children: [
                      _LabeledField(label: 'Title', controller: _titleController),
                      const SizedBox(height: 12),
                      _LabeledField(label: 'Instructions', controller: _instructionsController, maxLines: 3),
                      const SizedBox(height: 12),
                      _NumberField(label: 'Points per question', controller: _pointsController),
                      const SizedBox(height: 12),
                      // Time limit in hours (converted to minutes on save)
                      _NumberField(label: 'Time limit (hours)', controller: _timeLimitController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableFrom,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Start'),
                                  Text(_fmtDT(_availableFrom)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableUntil,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('End'),
                                  Text(_fmtDT(_availableUntil)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle questions',
                              value: shuffleQuestions,
                              onChanged: (v) => setState(() => shuffleQuestions = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle options',
                              value: shuffleOptions,
                              onChanged: (v) => setState(() => shuffleOptions = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Target Audience',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select course, year level, and section to target.',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      // Course picker
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        items: _courses
                            .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourse = val;
                            _selectedYearLevel = null;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select a course',
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Year level picker
                      DropdownButtonFormField<String>(
                        value: _selectedYearLevel,
                        items: (
                                  _selectedCourse != null
                                      ? (_yearsByCourse[_selectedCourse!] ?? <String>{}).toList()
                                      : (_assignedYearLevels.isNotEmpty
                                          ? _assignedYearLevels
                                          : const ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'])
                                )
                                .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedYearLevel = val;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select a year level',
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Section picker (from Firebase when available; fallback to assigned names)
                      DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        items: _buildSectionDropdownItems(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                            if (val != null && val.startsWith('ASSIGNED::')) {
                              final sec = val.substring('ASSIGNED::'.length);
                              _selectedSectionName = sec;
                              if (_selectedYearLevel != null) {
                                final resolved = _courseByYearSection['${_selectedYearLevel}::$sec'];
                                if (resolved != null && resolved.isNotEmpty) {
                                  _selectedCourse = resolved;
                                }
                              }
                            } else {
                              final match = _sections.firstWhere(
                                (s) => s['id'] == val,
                                orElse: () => {'sectionName': null},
                              );
                              _selectedSectionName = match['sectionName'] as String?;
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select a section',
                        ),
                      ),
                      if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Selected:  �  ',
                                style: AppTextStyles.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!previewMode) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions', style: AppTextStyles.textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _questions.length; i++) _QuestionEditorCard(index: i, question: _questions[i], onDelete: () => _removeQuestion(i), onUpdate: (q) => setState(() => _questions[i] = q)),
                ] else ...[
                  Text('Student View', style: AppTextStyles.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _questions.length; i++) _PreviewQuestionCard(index: i, question: _questions[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Quiz Details',
                  child: Column(
                    children: [
                      _LabeledField(label: 'Title', controller: _titleController),
                      const SizedBox(height: 12),
                      _LabeledField(label: 'Instructions', controller: _instructionsController, maxLines: 3),
                      const SizedBox(height: 12),
                      _NumberField(label: 'Points per question', controller: _pointsController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableFrom,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Start'),
                                  Text(_fmtDT(_availableFrom)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableUntil,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('End'),
                                  Text(_fmtDT(_availableUntil)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle questions',
                              value: shuffleQuestions,
                              onChanged: (v) => setState(() => shuffleQuestions = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Target Audience',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select course, year level, and section to target.',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        items: _courses.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourse = val;
                            _selectedYearLevel = null;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a course'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedYearLevel,
                        items: (
                                  _selectedCourse != null
                                      ? (_yearsByCourse[_selectedCourse!] ?? <String>{}).toList()
                                      : (_assignedYearLevels.isNotEmpty
                                          ? _assignedYearLevels
                                          : const ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'])
                                )
                                .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedYearLevel = val;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a year level'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        items: _buildSectionDropdownItems(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                            if (val != null && val.startsWith('ASSIGNED::')) {
                              final sec = val.substring('ASSIGNED::'.length);
                              _selectedSectionName = sec;
                              if (_selectedYearLevel != null) {
                                final resolved = _courseByYearSection['${_selectedYearLevel}::$sec'];
                                if (resolved != null && resolved.isNotEmpty) {
                                  _selectedCourse = resolved;
                                }
                              }
                            } else {
                              final match = _sections.firstWhere(
                                (s) => s['id'] == val,
                                orElse: () => {'sectionName': null},
                              );
                              _selectedSectionName = match['sectionName'] as String?;
                            }
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a section'),
                      ),
                      if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Selected:  �  ',
                                style: AppTextStyles.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Questions', style: AppTextStyles.textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: () => setState(() => _tfQuestions.add(_TFQuestion(text: '', answer: true))),
                      icon: const Icon(Icons.add),
                      label: const Text('Add question'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _tfQuestions.length; i++)
                  _TFQuestionEditorCard(
                    index: i,
                    question: _tfQuestions[i],
                    onDelete: () => setState(() => _tfQuestions.removeAt(i)),
                    onUpdate: (q) => setState(() => _tfQuestions[i] = q),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentificationContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Quiz Details',
                  child: Column(
                    children: [
                      _LabeledField(label: 'Title', controller: _titleController),
                      const SizedBox(height: 12),
                      _LabeledField(label: 'Instructions', controller: _instructionsController, maxLines: 3),
                      const SizedBox(height: 12),
                      _NumberField(label: 'Points per question', controller: _pointsController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableFrom,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Start'),
                                  Text(_fmtDT(_availableFrom)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableUntil,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('End'),
                                  Text(_fmtDT(_availableUntil)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle questions',
                              value: shuffleQuestions,
                              onChanged: (v) => setState(() => shuffleQuestions = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Target Audience',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select course, year level, and section to target.',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        items: _courses.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourse = val;
                            _selectedYearLevel = null;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a course'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedYearLevel,
                        items: (
                                  _selectedCourse != null
                                      ? (_yearsByCourse[_selectedCourse!] ?? <String>{}).toList()
                                      : (_assignedYearLevels.isNotEmpty
                                          ? _assignedYearLevels
                                          : const ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'])
                                )
                                .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedYearLevel = val;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a year level'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        items: _buildSectionDropdownItems(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                            if (val != null && val.startsWith('ASSIGNED::')) {
                              final sec = val.substring('ASSIGNED::'.length);
                              _selectedSectionName = sec;
                              if (_selectedYearLevel != null) {
                                final resolved = _courseByYearSection['${_selectedYearLevel}::$sec'];
                                if (resolved != null && resolved.isNotEmpty) {
                                  _selectedCourse = resolved;
                                }
                              }
                            } else {
                              final match = _sections.firstWhere(
                                (s) => s['id'] == val,
                                orElse: () => {'sectionName': null},
                              );
                              _selectedSectionName = match['sectionName'] as String?;
                            }
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a section'),
                      ),
                      if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Selected:  �  ',
                                style: AppTextStyles.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Questions', style: AppTextStyles.textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: () => setState(() => _idQuestions.add(_IDQuestion(text: '', answer: ''))),
                      icon: const Icon(Icons.add),
                      label: const Text('Add question'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _idQuestions.length; i++)
                  _IDQuestionEditorCard(
                    index: i,
                    question: _idQuestions[i],
                    onDelete: () => setState(() => _idQuestions.removeAt(i)),
                    onUpdate: (q) => setState(() => _idQuestions[i] = q),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnderstandImageContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Quiz Details',
                  child: Column(
                    children: [
                      _LabeledField(label: 'Title', controller: _titleController),
                      const SizedBox(height: 12),
                      _LabeledField(label: 'Instructions', controller: _instructionsController, maxLines: 3),
                      const SizedBox(height: 12),
                      _NumberField(label: 'Points per question', controller: _pointsController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableFrom,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Start'),
                                  Text(_fmtDT(_availableFrom)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableUntil,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('End'),
                                  Text(_fmtDT(_availableUntil)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle questions',
                              value: shuffleQuestions,
                              onChanged: (v) => setState(() => shuffleQuestions = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle options',
                              value: shuffleOptions,
                              onChanged: (v) => setState(() => shuffleOptions = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Target Audience',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select course, year level, and section to target.',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        items: _courses.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourse = val;
                            _selectedYearLevel = null;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a course'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedYearLevel,
                        items: (
                                  _selectedCourse != null
                                      ? (_yearsByCourse[_selectedCourse!] ?? <String>{}).toList()
                                      : (_assignedYearLevels.isNotEmpty
                                          ? _assignedYearLevels
                                          : const ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'])
                                )
                                .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedYearLevel = val;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a year level'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        items: _buildSectionDropdownItems(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                            if (val != null && val.startsWith('ASSIGNED::')) {
                              final sec = val.substring('ASSIGNED::'.length);
                              _selectedSectionName = sec;
                              if (_selectedYearLevel != null) {
                                final resolved = _courseByYearSection['${_selectedYearLevel}::$sec'];
                                if (resolved != null && resolved.isNotEmpty) {
                                  _selectedCourse = resolved;
                                }
                              }
                            } else {
                              final match = _sections.firstWhere(
                                (s) => s['id'] == val,
                                orElse: () => {'sectionName': null},
                              );
                              _selectedSectionName = match['sectionName'] as String?;
                            }
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a section'),
                      ),
                      if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Selected:  �  ',
                                style: AppTextStyles.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!previewMode) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions', style: AppTextStyles.textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _addUIImageQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _uiQuestions.length; i++)
                    _UIImageQuestionEditorCard(
                      index: i,
                      question: _uiQuestions[i],
                      onDelete: () => _removeUIImageQuestion(i),
                      onUpdate: (q) => setState(() => _uiQuestions[i] = q),
                      ensureFolder: _ensureFolder,
                      uploadImage: (file, {fileName}) => _uploadQuizImage(file, fileName: fileName),
                    ),
                ] else ...[
                  Text('Student View', style: AppTextStyles.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _uiQuestions.length; i++) _UIImagePreviewCard(index: i, question: _uiQuestions[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Quiz Details',
                  child: Column(
                    children: [
                      _LabeledField(label: 'Title', controller: _titleController),
                      const SizedBox(height: 12),
                      _LabeledField(label: 'Instructions', controller: _instructionsController, maxLines: 3),
                      const SizedBox(height: 12),
                      _NumberField(label: 'Points per question', controller: _pointsController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableFrom,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Start'),
                                  Text(_fmtDT(_availableFrom)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickAvailableUntil,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('End'),
                                  Text(_fmtDT(_availableUntil)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle questions',
                              value: shuffleQuestions,
                              onChanged: (v) => setState(() => shuffleQuestions = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SwitchTile(
                              label: 'Shuffle options',
                              value: shuffleOptions,
                              onChanged: (v) => setState(() => shuffleOptions = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Target Audience',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select course, year level, and section to target.',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        items: _courses.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourse = val;
                            _selectedYearLevel = null;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a course'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedYearLevel,
                        items: (
                                  _selectedCourse != null
                                      ? (_yearsByCourse[_selectedCourse!] ?? <String>{}).toList()
                                      : (_assignedYearLevels.isNotEmpty
                                          ? _assignedYearLevels
                                          : const ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'])
                                )
                                .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedYearLevel = val;
                            _selectedSectionId = null;
                            _selectedSectionName = null;
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a year level'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        items: _buildSectionDropdownItems(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                            if (val != null && val.startsWith('ASSIGNED::')) {
                              final sec = val.substring('ASSIGNED::'.length);
                              _selectedSectionName = sec;
                              if (_selectedYearLevel != null) {
                                final resolved = _courseByYearSection['${_selectedYearLevel}::$sec'];
                                if (resolved != null && resolved.isNotEmpty) {
                                  _selectedCourse = resolved;
                                }
                              }
                            } else {
                              final match = _sections.firstWhere(
                                (s) => s['id'] == val,
                                orElse: () => {'sectionName': null},
                              );
                              _selectedSectionName = match['sectionName'] as String?;
                            }
                          });
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select a section'),
                      ),
                      if (_selectedCourse != null && _selectedYearLevel != null && _selectedSectionName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Selected:  �  ',
                                style: AppTextStyles.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!previewMode) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Questions', style: AppTextStyles.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(onPressed: _addCustomMC, icon: const Icon(Icons.add), label: const Text('Add MC')),
                          TextButton.icon(onPressed: _addCustomTF, icon: const Icon(Icons.add), label: const Text('Add TF')),
                          TextButton.icon(onPressed: _addCustomID, icon: const Icon(Icons.add), label: const Text('Add ID')),
                          TextButton.icon(onPressed: _addCustomUI, icon: const Icon(Icons.add), label: const Text('Add UI')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _customItems.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final item = _customItems[i];
                        switch (item.type) {
                          case 'mc':
                            final q = item.question as _MCQuestion;
                            return _QuestionEditorCard(
                              index: i,
                              question: q,
                              onDelete: () => _removeCustomItem(i),
                              onUpdate: (newQ) => setState(() => _customItems[i] = _CustomQuestionEntry(type: 'mc', question: newQ)),
                            );
                          case 'tf':
                            final qtf = item.question as _TFQuestion;
                            return _TFQuestionEditorCard(
                              index: i,
                              question: qtf,
                              onDelete: () => _removeCustomItem(i),
                              onUpdate: (newQ) => setState(() => _customItems[i] = _CustomQuestionEntry(type: 'tf', question: newQ)),
                            );
                          case 'id':
                            final qid = item.question as _IDQuestion;
                            return _IDQuestionEditorCard(
                              index: i,
                              question: qid,
                              onDelete: () => _removeCustomItem(i),
                              onUpdate: (newQ) => setState(() => _customItems[i] = _CustomQuestionEntry(type: 'id', question: newQ)),
                            );
                          case 'ui':
                            final qu = item.question as _UIImageQuestion;
                            return _UIImageQuestionEditorCard(
                              index: i,
                              question: qu,
                              onDelete: () => _removeCustomItem(i),
                              onUpdate: (newQ) => setState(() => _customItems[i] = _CustomQuestionEntry(type: 'ui', question: newQ)),
                              ensureFolder: _ensureFolder,
                              uploadImage: (file, {fileName}) => _uploadQuizImage(file, fileName: fileName),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ] else ...[
                  Text('Student View', style: AppTextStyles.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _customItems.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final item = _customItems[i];
                        switch (item.type) {
                          case 'mc':
                            final q = item.question as _MCQuestion;
                            return _PreviewQuestionCard(index: i, question: q);
                          case 'tf':
                            final qtf = item.question as _TFQuestion;
                            return _SectionCard(
                              title: 'Question ${i + 1}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(qtf.text.isNotEmpty ? qtf.text : 'No question text', style: AppTextStyles.textTheme.titleSmall),
                                  const SizedBox(height: 8),
                                  RadioListTile<bool>(value: true, groupValue: qtf.answer, onChanged: null, title: const Text('True')),
                                  RadioListTile<bool>(value: false, groupValue: qtf.answer, onChanged: null, title: const Text('False')),
                                ],
                              ),
                            );
                          case 'id':
                            final qid = item.question as _IDQuestion;
                            return _SectionCard(
                              title: 'Question ${i + 1}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  TextField(
                                    enabled: false,
                                    decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Student answer input (preview)'),
                                  ),
                                ],
                              ),
                            );
                          case 'ui':
                            final qu = item.question as _UIImageQuestion;
                            return _UIImagePreviewCard(index: i, question: qu);
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Validate selections
          if (_selectedCourse == null || _selectedYearLevel == null || _selectedSectionId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select course, year level, and section before creating the quiz.')),
            );
            return;
          }
          // Validate quiz details
          final title = _titleController.text.trim();
          if (title.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a quiz title.')),
            );
            return;
          }
          if (_isMultipleChoice) {
            if (_questions.isEmpty || _questions.any((q) => q.text.trim().isEmpty || q.options.any((o) => o.trim().isEmpty))) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please complete all questions and options.')),
              );
              return;
            }
          } else if (_isTrueFalse) {
            if (_tfQuestions.isEmpty || _tfQuestions.any((q) => q.text.trim().isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please complete all True/False questions.')),
              );
              return;
            }
          } else if (_isIdentification) {
            if (_idQuestions.isEmpty || _idQuestions.any((q) => q.text.trim().isEmpty || q.answer.trim().isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide question text and answer for Identification.')),
              );
              return;
            }
          } else if (_isUnderstandImage) {
            if (_uiQuestions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one question.')),
              );
              return;
            }
            for (final q in _uiQuestions) {
              if (q.questionIsImage) {
                if ((q.questionImageUrl ?? '').trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload an image for the image-based question.')),
                  );
                  return;
                }
              } else {
                if (q.questionText.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter question text.')),
                  );
                  return;
                }
              }
              if (q.identification) {
                if (q.identificationAnswer.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide the identification answer.')),
                  );
                  return;
                }
              } else {
                if (q.optionsAreImage) {
                  if (q.optionsImageUrls.length < 2 || q.correctIndex < 0 || q.correctIndex >= q.optionsImageUrls.length) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Provide at least two image choices and select the correct one.')),
                    );
                    return;
                  }
                } else {
                  final nonEmpty = q.optionsText.where((e) => e.trim().isNotEmpty).toList();
                  if (nonEmpty.length < 2 || q.correctIndex < 0 || q.correctIndex >= nonEmpty.length) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Provide at least two text choices and select the correct one.')),
                    );
                    return;
                  }
                }
              }
            }
          } else if (_isCustom) {
            if (_customItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one question.')),
              );
              return;
            }
            for (final item in _customItems) {
              switch (item.type) {
                case 'mc':
                  final q = item.question as _MCQuestion;
                  if (q.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter question text.')));
                    return;
                  }
                  final nonEmpty = q.options.where((e) => e.trim().isNotEmpty).toList();
                  if (nonEmpty.length < 2 || q.correctIndex < 0 || q.correctIndex >= q.options.length) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide at least two choices and select the correct one.')));
                    return;
                  }
                  break;
                case 'tf':
                  final qtf = item.question as _TFQuestion;
                  if (qtf.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all True/False questions.')));
                    return;
                  }
                  break;
                case 'id':
                  final qid = item.question as _IDQuestion;
                  if (qid.text.trim().isEmpty || qid.answer.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide question text and answer for Identification.')));
                    return;
                  }
                  break;
                case 'ui':
                  final qu = item.question as _UIImageQuestion;
                  if (qu.questionIsImage) {
                    if ((qu.questionImageUrl ?? '').trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image for the image-based question.')));
                      return;
                    }
                  } else {
                    if (qu.questionText.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter question text.')));
                      return;
                    }
                  }
                  if (qu.identification) {
                    if (qu.identificationAnswer.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide the identification answer.')));
                      return;
                    }
                  } else {
                    if (qu.optionsAreImage) {
                      if (qu.optionsImageUrls.length < 2 || qu.correctIndex < 0 || qu.correctIndex >= qu.optionsImageUrls.length) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide at least two image choices and select the correct one.')));
                        return;
                      }
                    } else {
                      final nonEmpty = qu.optionsText.where((e) => e.trim().isNotEmpty).toList();
                      if (nonEmpty.length < 2 || qu.correctIndex < 0 || qu.correctIndex >= nonEmpty.length) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide at least two text choices and select the correct one.')));
                        return;
                      }
                    }
                  }
                  break;
              }
            }
          }

          // Parse numbers safely
          final hoursRaw = _timeLimitController.text.trim();
          final hours = int.tryParse(hoursRaw) ?? 0;
          final int timeLimit = hours > 0 ? hours * 60 : 0; // minutes
          final int pointsPerQuestion = int.tryParse(_pointsController.text.trim()) ?? 1;

          // Get instructor UID
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final instructorUid = auth.currentUser?.uid;
          if (instructorUid == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to determine instructor account. Please sign in again.')),
            );
            return;
          }

          // Build questions payload
          late final List<Map<String, dynamic>> questions;
          if (_isMultipleChoice) {
            questions = _questions
                .map((q) => {
                      'text': q.text.trim(),
                      'options': q.options.map((o) => o.trim()).toList(),
                      'correctIndex': q.correctIndex,
                    })
                .toList();
          } else if (_isTrueFalse) {
            questions = _tfQuestions
                .map((q) => {
                      'text': q.text.trim(),
                      'answer': q.answer,
                    })
                .toList();
          } else if (_isIdentification) {
            // Identification
            questions = _idQuestions
                .map((q) => {
                      'text': q.text.trim(),
                      'answer': q.answer.trim(),
                    })
                .toList();
          } else if (_isUnderstandImage) {
            questions = _uiQuestions.map((q) {
              final base = <String, dynamic>{
                if (q.questionIsImage) 'imageUrl': q.questionImageUrl,
                if (!q.questionIsImage) 'text': q.questionText.trim(),
              };
              if (q.identification) {
                base['answer'] = q.identificationAnswer.trim();
              } else {
                base['correctIndex'] = q.correctIndex;
                if (q.optionsAreImage) {
                  base['optionsImages'] = q.optionsImageUrls;
                } else {
                  base['options'] = q.optionsText.map((e) => e.trim()).toList();
                }
              }
              return base;
            }).toList();
          } else if (_isCustom) {
            questions = _customItems.map((item) {
              switch (item.type) {
                case 'mc':
                  final q = item.question as _MCQuestion;
                  return {
                    'type': 'multiple_choice',
                    'text': q.text.trim(),
                    'options': q.options.map((o) => o.trim()).toList(),
                    'correctIndex': q.correctIndex,
                  };
                case 'tf':
                  final q = item.question as _TFQuestion;
                  return {
                    'type': 'true_false',
                    'text': q.text.trim(),
                    'answer': q.answer,
                  };
                case 'id':
                  final q = item.question as _IDQuestion;
                  return {
                    'type': 'identification',
                    'text': q.text.trim(),
                    'answer': q.answer.trim(),
                  };
                case 'ui':
                  final q = item.question as _UIImageQuestion;
                  final base = <String, dynamic>{
                    'type': 'understand_image',
                    if (q.questionIsImage) 'imageUrl': q.questionImageUrl,
                    if (!q.questionIsImage) 'text': q.questionText.trim(),
                  };
                  if (q.identification) {
                    base['answer'] = q.identificationAnswer.trim();
                  } else {
                    base['correctIndex'] = q.correctIndex;
                    if (q.optionsAreImage) {
                      base['optionsImages'] = q.optionsImageUrls;
                    } else {
                      base['options'] = q.optionsText.map((e) => e.trim()).toList();
                    }
                  }
                  return base;
                default:
                  return {'type': item.type};
              }
            }).toList();
          }

          // Persist to Firestore (new targeted database for testing)
          final hasUIImage = _isUnderstandImage
              ? true
              : _isCustom
                  ? _customItems.any((e) => e.type == 'ui')
                  : false;

          final result = await _quizService.createTargetedCourseQuiz(
            instructorId: instructorUid,
            course: _selectedCourse ?? '',
            yearLevel: _selectedYearLevel ?? '',
            section: _selectedSectionName ?? '',
            title: title,
            instructions: _instructionsController.text.trim(),
            timeLimitMinutes: timeLimit,
            pointsPerQuestion: pointsPerQuestion,
            shuffleQuestions: shuffleQuestions,
            shuffleOptions: (_isMultipleChoice || _isUnderstandImage || _isCustom) ? shuffleOptions : false,
            questions: questions,
            topic: widget.topic,
            type: _isMultipleChoice
                ? 'multiple_choice'
                : _isTrueFalse
                    ? 'true_false'
                    : _isIdentification
                        ? 'identification'
                        : _isUnderstandImage
                            ? 'understand_image'
                            : widget.type,
            label: widget.label,
            quizId: hasUIImage ? (_pendingQuizFolderId ?? FirebaseFirestore.instance.collection('courseQuizzes').doc().id) : null,
            mediaFolder: hasUIImage ? (_pendingQuizFolderId ?? '') : null,
            availableFrom: _availableFrom,
            availableUntil: _availableUntil,
          );

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Quiz saved to courseQuizzes (ID: ${result['id']}).')),
            );
          } else {
            final error = (result['error'] ?? 'Unknown error').toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create quiz: ')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: AppTextStyles.textTheme.titleMedium,
        ),
        child: const Text('Create Quiz'),
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_MCQuestion(
        text: '',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctIndex: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addUIImageQuestion() {
    setState(() {
      _uiQuestions.add(_UIImageQuestion(
        questionIsImage: true,
        questionText: '',
        questionImageUrl: null,
        identification: false,
        identificationAnswer: '',
        optionsAreImage: true,
        optionsText: const [],
        optionsImageUrls: const ['', ''],
        correctIndex: 0,
      ));
    });
  }

  void _removeUIImageQuestion(int index) {
    setState(() {
      _uiQuestions.removeAt(index);
    });
  }

  // ===== Custom quiz add/remove helpers =====
  void _addCustomMC() {
    setState(() {
      _customItems.add(
        _CustomQuestionEntry(
          type: 'mc',
          question: _MCQuestion(text: '', options: ['Option A', 'Option B', 'Option C', 'Option D'], correctIndex: 0),
        ),
      );
    });
  }

  void _addCustomTF() {
    setState(() {
      _customItems.add(
        _CustomQuestionEntry(type: 'tf', question: _TFQuestion(text: '', answer: true)),
      );
    });
  }

  void _addCustomID() {
    setState(() {
      _customItems.add(
        _CustomQuestionEntry(type: 'id', question: _IDQuestion(text: '', answer: '')),
      );
    });
  }

  void _addCustomUI() {
    setState(() {
      _customItems.add(
        _CustomQuestionEntry(
          type: 'ui',
          question: _UIImageQuestion(
            questionIsImage: true,
            questionText: '',
            questionImageUrl: null,
            identification: false,
            identificationAnswer: '',
            optionsAreImage: true,
            optionsText: const [],
            optionsImageUrls: const ['', ''],
            correctIndex: 0,
          ),
        ),
      );
    });
  }

  void _removeCustomItem(int index) {
    setState(() {
      _customItems.removeAt(index);
    });
  }

  Future<void> _ensureFolder() async {
    if ((_pendingQuizFolderId ?? '').isEmpty) {
      _pendingQuizFolderId = FirebaseFirestore.instance.collection('courseQuizzes').doc().id;
      setState(() {});
    }
  }

  Future<String?> _uploadQuizImage(XFile file, {String? fileName}) async {
    await _ensureFolder();
    try {
      return await _mediaService.uploadXFile(
        file: file,
        folderId: _pendingQuizFolderId!,
        fileName: fileName,
      );
    } catch (_) {
      return null;
    }
  }

  // ===== Helpers to load instructor constraints and sections =====
  void _loadInstructorConstraints() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.currentUser?.uid;
      if (uid == null) {
        return;
      }

      // Load user data directly from Firestore to access assignedYearSectionCourses
      _authService.getUserData(uid).then((data) {
        final combined = (data?['assignedYearSectionCourses'] as List?)
                ?.map((e) => e.toString())
                .toList() ?? [];

        if (combined.isEmpty) {
          return; // Leave pickers empty; sections stream will still load
        }

        for (final entry in combined) {
          final raw = entry.trim();
          if (raw.isEmpty) continue;
          // Expected format: "<Year Level> <Section> | <Course>"
          final parts = raw.split('|');
          final left = parts.first.trim();
          final course = parts.length > 1 ? parts[1].trim() : '';

          // Parse year level and section from left side
          final match = RegExp(r'^(.*)\s([A-H])$').firstMatch(left);
          String yearLevel;
          String sectionName;
          if (match != null) {
            yearLevel = match.group(1)!.trim();
            sectionName = match.group(2)!.trim();
          } else {
            final tokens = left.split(' ');
            sectionName = tokens.isNotEmpty ? tokens.last.trim() : '';
            yearLevel = tokens.length > 1
                ? tokens.sublist(0, tokens.length - 1).join(' ').trim()
                : left;
          }

          if (course.isNotEmpty) {
            _courses.add(course);
            _yearsByCourse.putIfAbsent(course, () => <String>{}).add(yearLevel);
            _sectionsByCourseYear
                .putIfAbsent('$course|$yearLevel', () => <String>{})
                .add(sectionName);
            _courseByYearSection['$yearLevel::$sectionName'] = course;
          }
          _assignedSectionNames.add(sectionName);
          _assignedYearLevels.add(yearLevel);
        }

        // Deduplicate assigned lists
        _assignedYearLevels
          ..clear()
          ..addAll(_assignedYearLevels.toSet().toList());

        // Default selection (first course if available)
        if (_selectedCourse == null && _courses.isNotEmpty) {
          _selectedCourse = _courses.first;
        }
        setState(() {});
      });
    } catch (_) {
      // Silent fail; UI will still show sections once they stream in
    }
  }

  void _subscribeInstructorSections() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      if (currentUser == null) return;

      setState(() => _isLoadingSections = true);

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
          _sections
            ..clear()
            ..addAll(filtered);
          _isLoadingSections = false;
          // Clear selection if it no longer exists
          if (_selectedSectionId != null && !_sections.any((s) => s['id'] == _selectedSectionId)) {
            _selectedSectionId = null;
            _selectedSectionName = null;
          }
        });
      });
    } catch (_) {
      setState(() => _isLoadingSections = false);
    }
  }

  List<DropdownMenuItem<String>> _buildSectionDropdownItems() {
    // If Firestore sections exist, filter by selected course+year when provided
    if (_sections.isNotEmpty) {
      if (_selectedCourse == null || _selectedYearLevel == null) {
        return const <DropdownMenuItem<String>>[];
      }

      final key = '${_selectedCourse!}|${_selectedYearLevel!}';
      final allowedNames = _sectionsByCourseYear[key] ?? <String>{};

      String normalizeSection(String s) {
        return s.replaceFirst(RegExp(r'(?i)^section\s+'), '').trim();
      }

      final filtered = _sections.where((s) {
        final raw = (s['sectionName'] as String? ?? '').trim();
        final normalized = normalizeSection(raw);
        return allowedNames.isEmpty ? true : allowedNames.contains(normalized);
      }).toList();

      final candidates = filtered.isNotEmpty ? filtered : _sections;
      return candidates
          .map((s) => DropdownMenuItem<String>(value: s['id'] as String, child: Text(s['sectionName'] as String)))
          .toList();
    }

    // Fallback to assigned names (A�H) when no Firestore sections are present
    final List<String> sectionNames = _assignedSectionNames.isNotEmpty
        ? _assignedSectionNames
        : const ['A','B','C','D','E','F','G','H'];
    return sectionNames
        .map((sec) => DropdownMenuItem<String>(value: 'ASSIGNED::$sec', child: Text(sec)))
        .toList();
  }
}

class _CustomQuestionEntry {
  final String type; // 'mc' | 'tf' | 'id' | 'ui'
  final dynamic question; // holds the respective question model

  _CustomQuestionEntry({required this.type, required this.question});
}

class _MCQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;

  _MCQuestion({required this.text, required this.options, required this.correctIndex});

  _MCQuestion copyWith({String? text, List<String>? options, int? correctIndex}) {
    return _MCQuestion(
      text: text ?? this.text,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
    );
  }
}

class _TFQuestion {
  final String text;
  final bool answer; // true = True, false = False

  _TFQuestion({required this.text, required this.answer});

  _TFQuestion copyWith({String? text, bool? answer}) {
    return _TFQuestion(text: text ?? this.text, answer: answer ?? this.answer);
  }
}

class _IDQuestion {
  final String text;
  final String answer;

  _IDQuestion({required this.text, required this.answer});

  _IDQuestion copyWith({String? text, String? answer}) {
    return _IDQuestion(text: text ?? this.text, answer: answer ?? this.answer);
  }
}

class _UIImageQuestion {
  final bool questionIsImage;
  final String questionText;
  final String? questionImageUrl;
  final bool identification;
  final String identificationAnswer;
  final bool optionsAreImage;
  final List<String> optionsText;
  final List<String> optionsImageUrls;
  final int correctIndex;

  _UIImageQuestion({
    required this.questionIsImage,
    required this.questionText,
    required this.questionImageUrl,
    required this.identification,
    required this.identificationAnswer,
    required this.optionsAreImage,
    required this.optionsText,
    required this.optionsImageUrls,
    required this.correctIndex,
  });

  _UIImageQuestion copyWith({
    bool? questionIsImage,
    String? questionText,
    String? questionImageUrl,
    bool? identification,
    String? identificationAnswer,
    bool? optionsAreImage,
    List<String>? optionsText,
    List<String>? optionsImageUrls,
    int? correctIndex,
  }) {
    return _UIImageQuestion(
      questionIsImage: questionIsImage ?? this.questionIsImage,
      questionText: questionText ?? this.questionText,
      questionImageUrl: questionImageUrl ?? this.questionImageUrl,
      identification: identification ?? this.identification,
      identificationAnswer: identificationAnswer ?? this.identificationAnswer,
      optionsAreImage: optionsAreImage ?? this.optionsAreImage,
      optionsText: optionsText ?? this.optionsText,
      optionsImageUrls: optionsImageUrls ?? this.optionsImageUrls,
      correctIndex: correctIndex ?? this.correctIndex,
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool previewMode;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.previewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(previewMode ? 'Student View' : 'Editor', style: AppTextStyles.textTheme.labelLarge),
        const SizedBox(width: 8),
        Switch(
          value: previewMode,
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
        ),
      ],
    );
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _LabeledField({required this.label, required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.textTheme.labelLarge),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _NumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.textTheme.labelLarge),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.textTheme.bodyMedium,
              softWrap: true,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryBlue),
        ],
      ),
    );
  }
}

class _QuestionEditorCard extends StatefulWidget {
  final int index;
  final _MCQuestion question;
  final VoidCallback onDelete;
  final ValueChanged<_MCQuestion> onUpdate;

  const _QuestionEditorCard({
    required this.index,
    required this.question,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<_QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<_QuestionEditorCard> {
  late TextEditingController qController;
  late List<TextEditingController> optControllers;

  @override
  void initState() {
    super.initState();
    qController = TextEditingController(text: widget.question.text);
    optControllers = widget.question.options.map((o) => TextEditingController(text: o)).toList();
  }

  @override
  void didUpdateWidget(covariant _QuestionEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep controllers in sync when parent updates question data
    if (qController.text != widget.question.text) {
      qController.text = widget.question.text;
      qController.selection = TextSelection.collapsed(offset: qController.text.length);
    }

    if (optControllers.length != widget.question.options.length) {
      for (final c in optControllers) {
        c.dispose();
      }
      optControllers = widget.question.options.map((o) => TextEditingController(text: o)).toList();
    } else {
      for (int i = 0; i < optControllers.length; i++) {
        final newText = widget.question.options[i];
        if (optControllers[i].text != newText) {
          optControllers[i].text = newText;
          optControllers[i].selection = TextSelection.collapsed(offset: optControllers[i].text.length);
        }
      }
    }
  }

  @override
  void dispose() {
    qController.dispose();
    for (final c in optControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('q-${widget.index}'),
            initialValue: widget.question.text,
            decoration: const InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => widget.onUpdate(widget.question.copyWith(text: v)),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < optControllers.length; i++) ...[
            Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: widget.question.correctIndex,
                  onChanged: (val) => widget.onUpdate(widget.question.copyWith(correctIndex: val)),
                  activeColor: AppColors.primaryBlue,
                ),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('opt-${widget.index}-$i'),
                    initialValue: widget.question.options[i],
                    decoration: const InputDecoration(
                      labelText: 'Option',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final newOptions = List<String>.from(widget.question.options);
                      newOptions[i] = v;
                      widget.onUpdate(widget.question.copyWith(options: newOptions));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove question'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewQuestionCard extends StatefulWidget {
  final int index;
  final _MCQuestion question;

  const _PreviewQuestionCard({required this.index, required this.question});

  @override
  State<_PreviewQuestionCard> createState() => _PreviewQuestionCardState();
}

class _PreviewQuestionCardState extends State<_PreviewQuestionCard> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.question.text, style: AppTextStyles.textTheme.titleSmall),
          const SizedBox(height: 12),
          for (int i = 0; i < widget.question.options.length; i++) ...[
            RadioListTile<int>(
              value: i,
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              title: Text(widget.question.options[i]),
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }
}

// ===== Understand Image Student Preview Card =====
class _UIImagePreviewCard extends StatelessWidget {
  final int index;
  final _UIImageQuestion question;

  const _UIImagePreviewCard({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question content
          if (!question.questionIsImage) ...[
            Text(
              (question.questionText).isNotEmpty ? question.questionText : 'No question text',
              style: AppTextStyles.textTheme.titleSmall,
            ),
          ] else ...[
            if ((question.questionImageUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  question.questionImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text('No question image uploaded', style: AppTextStyles.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          // Identification mode preview
          if (question.identification) ...[
            Text('Identification', style: AppTextStyles.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Student answer input (preview)',
              ),
            ),
          ] else ...[
            // Multiple-choice preview
            Text('Choices', style: AppTextStyles.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (question.optionsAreImage) ...[
              for (int i = 0; i < question.optionsImageUrls.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: question.correctIndex,
                        onChanged: null, // disabled in preview
                        activeColor: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                            color: Colors.grey[100],
                          ),
                          child: (question.optionsImageUrls[i]).isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    question.optionsImageUrls[i],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'No image',
                                    style: AppTextStyles.textTheme.bodySmall,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              for (int i = 0; i < question.optionsText.length; i++)
                RadioListTile<int>(
                  value: i,
                  groupValue: question.correctIndex,
                  onChanged: null,
                  title: Text(question.optionsText[i].isNotEmpty ? question.optionsText[i] : 'Empty choice'),
                  activeColor: AppColors.primaryBlue,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.textTheme.labelLarge?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== True/False Editor Card =====
class _TFQuestionEditorCard extends StatelessWidget {
  final int index;
  final _TFQuestion question;
  final VoidCallback onDelete;
  final ValueChanged<_TFQuestion> onUpdate;

  const _TFQuestionEditorCard({
    required this.index,
    required this.question,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('tf-q-$index'),
            initialValue: question.text,
            decoration: const InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onUpdate(question.copyWith(text: v)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('True'),
                  value: true,
                  groupValue: question.answer,
                  onChanged: (v) => onUpdate(question.copyWith(answer: v ?? true)),
                  activeColor: AppColors.primaryBlue,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('False'),
                  value: false,
                  groupValue: question.answer,
                  onChanged: (v) => onUpdate(question.copyWith(answer: v ?? false)),
                  activeColor: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove question'),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Identification Editor Card =====
class _IDQuestionEditorCard extends StatelessWidget {
  final int index;
  final _IDQuestion question;
  final VoidCallback onDelete;
  final ValueChanged<_IDQuestion> onUpdate;

  const _IDQuestionEditorCard({
    required this.index,
    required this.question,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('id-q-$index'),
            initialValue: question.text,
            decoration: const InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onUpdate(question.copyWith(text: v)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('id-a-$index'),
            initialValue: question.answer,
            decoration: const InputDecoration(
              labelText: 'Answer',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onUpdate(question.copyWith(answer: v)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove question'),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Understand Image Editor Card =====
class _UIImageQuestionEditorCard extends StatefulWidget {
  final int index;
  final _UIImageQuestion question;
  final VoidCallback onDelete;
  final ValueChanged<_UIImageQuestion> onUpdate;
  final Future<void> Function() ensureFolder;
  final Future<String?> Function(XFile file, {String? fileName}) uploadImage;

  const _UIImageQuestionEditorCard({
    required this.index,
    required this.question,
    required this.onDelete,
    required this.onUpdate,
    required this.ensureFolder,
    required this.uploadImage,
  });

  @override
  State<_UIImageQuestionEditorCard> createState() => _UIImageQuestionEditorCardState();
}

class _UIImageQuestionEditorCardState extends State<_UIImageQuestionEditorCard> {
  late TextEditingController qController;
  late TextEditingController idController;
  List<TextEditingController> optControllers = [];
  bool _uploadingQuestionImage = false;
  final Set<int> _uploadingChoices = <int>{};

  @override
  void initState() {
    super.initState();
    qController = TextEditingController(text: widget.question.questionText);
    idController = TextEditingController(text: widget.question.identificationAnswer);
    optControllers = widget.question.optionsText.map((e) => TextEditingController(text: e)).toList();
    if (optControllers.isEmpty) {
      optControllers = [TextEditingController(), TextEditingController()];
    }
  }

  @override
  void dispose() {
    qController.dispose();
    idController.dispose();
    for (final c in optControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickQuestionImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploadingQuestionImage = true);
    try {
      await widget.ensureFolder();
      final url = await widget.uploadImage(
        file,
        fileName: 'q_${widget.index}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url != null) {
        widget.onUpdate(widget.question.copyWith(questionImageUrl: url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload question image')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingQuestionImage = false);
    }
  }

  Future<void> _pickChoiceImage(int optIndex) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploadingChoices.add(optIndex));
    try {
      await widget.ensureFolder();
      final url = await widget.uploadImage(
        file,
        fileName: 'opt_${widget.index}_${optIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url != null) {
        final imgs = List<String>.from(widget.question.optionsImageUrls);
        if (optIndex < imgs.length) {
          imgs[optIndex] = url;
        } else {
          imgs.add(url);
        }
        widget.onUpdate(widget.question.copyWith(optionsImageUrls: imgs));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload choice image #${optIndex + 1}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingChoices.remove(optIndex));
    }
  }

  void _addTextOption() {
    setState(() {
      optControllers.add(TextEditingController());
      final newOpts = List<String>.from(widget.question.optionsText)..add('');
      widget.onUpdate(widget.question.copyWith(optionsText: newOpts));
    });
  }

  void _removeTextOption(int i) {
    if (optControllers.length <= 2) return;
    setState(() {
      optControllers.removeAt(i);
      final newOpts = List<String>.from(widget.question.optionsText)..removeAt(i);
      int newCorrect = widget.question.correctIndex;
      if (newCorrect >= newOpts.length) newCorrect = newOpts.isEmpty ? 0 : newOpts.length - 1;
      widget.onUpdate(widget.question.copyWith(optionsText: newOpts, correctIndex: newCorrect));
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return _SectionCard(
      title: 'Question ${widget.index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Text'),
                selected: !q.questionIsImage,
                onSelected: (sel) {
                  if (sel) widget.onUpdate(q.copyWith(questionIsImage: false));
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Image'),
                selected: q.questionIsImage,
                onSelected: (sel) {
                  if (sel) widget.onUpdate(q.copyWith(questionIsImage: true));
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!q.questionIsImage) ...[
            TextFormField(
              key: ValueKey('ui-q-${widget.index}'),
              controller: qController,
              decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
              onChanged: (v) => widget.onUpdate(q.copyWith(questionText: v)),
            ),
          ] else ...[
            if ((q.questionImageUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(q.questionImageUrl!, height: 150, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _uploadingQuestionImage ? null : _pickQuestionImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_uploadingQuestionImage ? 'Uploading...' : 'Upload question image'),
              ),
            ),
            if (_uploadingQuestionImage)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...')
                  ],
                ),
              ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Identification'),
                selected: q.identification,
                onSelected: (sel) {
                  if (sel) widget.onUpdate(q.copyWith(identification: true));
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Multiple Choice'),
                selected: !q.identification,
                onSelected: (sel) {
                  if (sel) widget.onUpdate(q.copyWith(identification: false));
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          if (q.identification) ...[
            TextFormField(
              key: ValueKey('ui-a-${widget.index}'),
              controller: idController,
              decoration: const InputDecoration(labelText: 'Correct answer (text)', border: OutlineInputBorder()),
              onChanged: (v) => widget.onUpdate(q.copyWith(identificationAnswer: v)),
            ),
          ] else ...[
            for (int i = 0; i < (q.optionsImageUrls.isEmpty ? 2 : q.optionsImageUrls.length); i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: q.correctIndex,
                    onChanged: (val) => widget.onUpdate(q.copyWith(correctIndex: val)),
                    activeColor: AppColors.primaryBlue,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            if (i < q.optionsImageUrls.length && q.optionsImageUrls[i].isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(q.optionsImageUrls[i], height: 120, fit: BoxFit.cover),
                              )
                            else
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text('No image', style: AppTextStyles.textTheme.bodySmall),
                              ),
                            if (_uploadingChoices.contains(i))
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _uploadingChoices.contains(i) ? null : () => _pickChoiceImage(i),
                          icon: const Icon(Icons.image_outlined),
                          label: Text(_uploadingChoices.contains(i) ? 'Uploading...' : 'Upload choice image'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final imgs = List<String>.from(q.optionsImageUrls)..add('');
                  widget.onUpdate(q.copyWith(optionsImageUrls: imgs));
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Add choice slot'),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove question'),
            ),
          ),
        ],
      ),
    );
  }
}








