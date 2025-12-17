import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/services/firebase_auth_service.dart';

class DifficultQuestionsScreen extends StatefulWidget {
  final String segmentLabel;
  final List<Map<String, dynamic>> questions;

  const DifficultQuestionsScreen({
    super.key,
    required this.segmentLabel,
    required this.questions,
  });

  @override
  State<DifficultQuestionsScreen> createState() => _DifficultQuestionsScreenState();
}

class _DifficultQuestionsScreenState extends State<DifficultQuestionsScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String? _selectedSection;
  List<Map<String, dynamic>> _filteredQuestions = [];
  Map<String, List<Map<String, dynamic>>> _questionsBySection = {};

  @override
  void initState() {
    super.initState();
    _organizeQuestionsBySection();
  }

  Future<void> _organizeQuestionsBySection() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final firestore = FirebaseFirestore.instance;
      final Map<String, List<Map<String, dynamic>>> questionsBySection = {};

      for (final questionData in widget.questions) {
        final quizId = questionData['quizId'] as String?;
        if (quizId == null) continue;

        // Get quiz to find sections
        final quizDoc = await firestore.collection('courseQuizzes').doc(quizId).get();
        if (!quizDoc.exists) continue;

        final quizData = quizDoc.data()!;
        final course = quizData['course'] as String? ?? '';
        final year = quizData['year'] as String? ?? '';
        final section = quizData['section'] as String? ?? '';
        final sectionKey = '$course - $year $section';

        if (!questionsBySection.containsKey(sectionKey)) {
          questionsBySection[sectionKey] = [];
        }

        questionsBySection[sectionKey]!.add({
          ...questionData,
          'section': sectionKey,
          'course': course,
          'year': year,
          'sectionName': section,
        });
      }

      setState(() {
        _questionsBySection = questionsBySection;
        if (_questionsBySection.isNotEmpty) {
          _selectedSection = _questionsBySection.keys.first;
          _filteredQuestions = _questionsBySection[_selectedSection!] ?? [];
        }
      });
    } catch (e) {
      print('Error organizing questions by section: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.segmentLabel,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _questionsBySection.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No questions found',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Section Filter
                if (_questionsBySection.length > 1)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: DropdownButton<String>(
                      value: _selectedSection,
                      isExpanded: true,
                      hint: const Text('Select Section'),
                      items: _questionsBySection.keys.map((section) {
                        return DropdownMenuItem(
                          value: section,
                          child: Text(section),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection = value;
                          _filteredQuestions = _questionsBySection[value!] ?? [];
                        });
                      },
                    ),
                  ),
                // Questions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredQuestions.length,
                    itemBuilder: (context, index) {
                      final questionData = _filteredQuestions[index];
                      return _buildQuestionCard(questionData);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> questionData) {
    final question = questionData['question'] as Map<String, dynamic>? ?? {};
    final questionText = question['question'] as String? ?? 'No question text';
    final questionType = question['type'] as String? ?? 'multiple_choice';
    final errorRate = questionData['errorRate'] as int? ?? 0;
    final totalAttempts = questionData['totalAttempts'] as int? ?? 0;
    final wrongAttempts = questionData['wrongAttempts'] as int? ?? 0;
    final quizTitle = questionData['quizTitle'] as String? ?? 'Untitled Quiz';
    final section = questionData['section'] as String? ?? 'Unknown Section';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$errorRate% Error Rate',
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                questionType.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quiz Title
          Text(
            quizTitle,
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Section
          Text(
            'Section: $section',
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Question Text
          Text(
            questionText,
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Statistics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Attempts', totalAttempts.toString()),
                _buildStatItem('Wrong Answers', wrongAttempts.toString()),
                _buildStatItem('Error Rate', '$errorRate%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

