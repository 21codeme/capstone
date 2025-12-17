import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../widgets/quiz_difficulty_pie_chart.dart';
import 'difficult_questions_screen.dart';
import '../../../../core/services/firebase_auth_service.dart';

class QuizDifficultyAnalysisScreen extends StatefulWidget {
  const QuizDifficultyAnalysisScreen({super.key});

  @override
  State<QuizDifficultyAnalysisScreen> createState() => _QuizDifficultyAnalysisScreenState();
}

class _QuizDifficultyAnalysisScreenState extends State<QuizDifficultyAnalysisScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = true;
  List<PieChartSegment> _segments = [];
  Map<String, List<Map<String, dynamic>>> _difficultQuestionsBySegment = {};

  @override
  void initState() {
    super.initState();
    _loadQuizDifficultyData();
  }

  Future<void> _loadQuizDifficultyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get all quizzes created by this instructor
      final firestore = FirebaseFirestore.instance;
      final quizzesSnapshot = await firestore
          .collection('courseQuizzes')
          .where('instructorId', isEqualTo: currentUser.uid)
          .get();

      // Analyze all quiz attempts to determine question difficulty
      final Map<int, Map<String, dynamic>> questionStats = {};
      int totalQuestions = 0;

      for (final quizDoc in quizzesSnapshot.docs) {
        final quizData = quizDoc.data();
        final questions = List<Map<String, dynamic>>.from(quizData['questions'] ?? []);
        totalQuestions += questions.length;

        // Get all attempts for this quiz
        final attemptsSnapshot = await firestore
            .collection('quizAttempts')
            .where('quizId', isEqualTo: quizDoc.id)
            .get();

        for (final attemptDoc in attemptsSnapshot.docs) {
          final attemptData = attemptDoc.data();
          final answers = List<Map<String, dynamic>>.from(attemptData['answers'] ?? []);

          // Analyze each question
          for (int i = 0; i < questions.length && i < answers.length; i++) {
            final question = questions[i];
            final answer = answers[i];
            final wasCorrect = answer['wasCorrect'] as bool? ?? false;

            if (!questionStats.containsKey(i)) {
              questionStats[i] = {
                'quizId': quizDoc.id,
                'quizTitle': quizData['title'] ?? 'Untitled Quiz',
                'questionIndex': i,
                'question': question,
                'totalAttempts': 0,
                'correctAttempts': 0,
                'wrongAttempts': 0,
              };
            }

            questionStats[i]!['totalAttempts'] = (questionStats[i]!['totalAttempts'] as int) + 1;
            if (wasCorrect) {
              questionStats[i]!['correctAttempts'] = (questionStats[i]!['correctAttempts'] as int) + 1;
            } else {
              questionStats[i]!['wrongAttempts'] = (questionStats[i]!['wrongAttempts'] as int) + 1;
            }
          }
        }
      }

      // Categorize questions by difficulty
      final List<Map<String, dynamic>> veryDifficult = [];
      final List<Map<String, dynamic>> difficult = [];
      final List<Map<String, dynamic>> moderate = [];
      final List<Map<String, dynamic>> easy = [];

      questionStats.forEach((index, stats) {
        final total = stats['totalAttempts'] as int;
        if (total == 0) return;

        final wrongRate = (stats['wrongAttempts'] as int) / total;
        stats['wrongRate'] = wrongRate;
        stats['errorRate'] = (wrongRate * 100).round();

        if (wrongRate >= 0.7) {
          veryDifficult.add(stats);
        } else if (wrongRate >= 0.5) {
          difficult.add(stats);
        } else if (wrongRate >= 0.3) {
          moderate.add(stats);
        } else {
          easy.add(stats);
        }
      });

      // Create pie chart segments
      final total = questionStats.length;
      if (total > 0) {
        _segments = [
          PieChartSegment(
            label: 'Very Difficult',
            value: veryDifficult.length,
            color: Colors.red,
            percentage: (veryDifficult.length / total * 100),
          ),
          PieChartSegment(
            label: 'Difficult',
            value: difficult.length,
            color: Colors.orange,
            percentage: (difficult.length / total * 100),
          ),
          PieChartSegment(
            label: 'Moderate',
            value: moderate.length,
            color: Colors.blue,
            percentage: (moderate.length / total * 100),
          ),
          PieChartSegment(
            label: 'Easy',
            value: easy.length,
            color: Colors.green,
            percentage: (easy.length / total * 100),
          ),
        ];

        // Store difficult questions by segment
        _difficultQuestionsBySegment = {
          'Very Difficult': veryDifficult,
          'Difficult': difficult,
          'Moderate': moderate,
          'Easy': easy,
        };
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quiz difficulty data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSegmentTap(PieChartSegment segment) {
    final questions = _difficultQuestionsBySegment[segment.label] ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DifficultQuestionsScreen(
          segmentLabel: segment.label,
          questions: questions,
        ),
      ),
    );
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
          'Quiz Difficulty Analysis',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _segments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No quiz data available',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pie Chart
                      Center(
                        child: QuizDifficultyPieChart(
                          segments: _segments,
                          size: 300,
                          onSegmentTap: _onSegmentTap,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Legend
                      Text(
                        'Difficulty Distribution',
                        style: AppTextStyles.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._segments.map((segment) => _buildLegendItem(segment)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLegendItem(PieChartSegment segment) {
    return GestureDetector(
      onTap: () => _onSegmentTap(segment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: segment.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.label,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${segment.value} questions (${segment.percentage.toStringAsFixed(1)}%)',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

