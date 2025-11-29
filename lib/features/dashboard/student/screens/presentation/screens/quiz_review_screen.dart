import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../features/auth/presentation/providers/auth_provider.dart';

class QuizReviewScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final double score;
  final double maxScore;
  final double percentage;

  const QuizReviewScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.maxScore,
    required this.percentage,
  });

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _studentAnswers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuizReview();
  }

  Future<void> _loadQuizReview() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = context.read<AuthProvider>();
      final studentId = authProvider.currentUser?.uid;
      
      if (studentId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load quiz questions
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (!quizDoc.exists) {
        // Try courseQuizzes collection
        final courseQuizDoc = await FirebaseFirestore.instance
            .collection('courseQuizzes')
            .doc(widget.quizId)
            .get();
        
        if (!courseQuizDoc.exists) {
          setState(() {
            _error = 'Quiz not found';
            _isLoading = false;
          });
          return;
        }
        
        final quizData = courseQuizDoc.data()!;
        _questions = List<Map<String, dynamic>>.from(quizData['questions'] ?? []);
      } else {
        final quizData = quizDoc.data()!;
        _questions = List<Map<String, dynamic>>.from(quizData['questions'] ?? []);
      }

      // Load student answers from quizAttempts
      final attemptsQuery = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('studentId', isEqualTo: studentId)
          .where('quizId', isEqualTo: widget.quizId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (attemptsQuery.docs.isEmpty) {
        setState(() {
          _error = 'No quiz attempt found';
          _isLoading = false;
        });
        return;
      }

      final attemptData = attemptsQuery.docs.first.data();
      _studentAnswers = List<Map<String, dynamic>>.from(attemptData['answers'] ?? []);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quiz review: $e');
      setState(() {
        _error = 'Error loading quiz review: $e';
        _isLoading = false;
      });
    }
  }

  bool _isAnswerCorrect(int questionIndex) {
    if (questionIndex >= _questions.length || questionIndex >= _studentAnswers.length) {
      return false;
    }

    final question = _questions[questionIndex];
    final studentAnswerData = _studentAnswers[questionIndex];
    final questionType = (question['type'] as String?) ?? 'multiple_choice';

    if (questionType == 'multiple_choice') {
      final studentIndex = studentAnswerData['selectedIndex'] as int?;
      final correctIndex = question['correctIndex'] as int?;
      return studentIndex == correctIndex;
    } else if (questionType == 'true_false') {
      final studentAnswerValue = studentAnswerData['selectedBool'] as bool?;
      final correctAnswer = question['answer'] as bool?;
      return studentAnswerValue == correctAnswer;
    } else if (questionType == 'identification') {
      final studentAnswerValue = (studentAnswerData['typed'] as String?)?.trim().toLowerCase() ?? '';
      final correctAnswer = ((question['answer'] as String?) ?? '').trim().toLowerCase();
      return studentAnswerValue == correctAnswer;
    }

    return false;
  }

  Widget _buildQuestionReview(int index) {
    if (index >= _questions.length) return const SizedBox.shrink();

    final question = _questions[index];
    final questionType = (question['type'] as String?) ?? 'multiple_choice';
    final isCorrect = _isAnswerCorrect(index);
    final studentAnswer = index < _studentAnswers.length ? _studentAnswers[index] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? AppColors.successGreen : AppColors.errorRed,
          width: 2,
        ),
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
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.successGreen : AppColors.errorRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Question ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                isCorrect ? 'Correct' : 'Incorrect',
                style: TextStyle(
                  color: isCorrect ? AppColors.successGreen : AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Question text
          Text(
            question['question']?.toString() ?? 'Question',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Answer display based on question type
          if (questionType == 'multiple_choice') ...[
            _buildMultipleChoiceReview(question, studentAnswer, isCorrect),
          ] else if (questionType == 'true_false') ...[
            _buildTrueFalseReview(question, studentAnswer, isCorrect),
          ] else if (questionType == 'identification') ...[
            _buildIdentificationReview(question, studentAnswer, isCorrect),
          ],
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceReview(
    Map<String, dynamic> question,
    Map<String, dynamic>? studentAnswer,
    bool isCorrect,
  ) {
    final options = List<String>.from(question['options'] ?? []);
    final correctIndex = question['correctIndex'] as int? ?? -1;
    final studentIndex = studentAnswer?['selectedIndex'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student's answer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.errorRed,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.errorRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Answer:',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentIndex != null && studentIndex < options.length
                          ? options[studentIndex]
                          : 'No answer',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Correct answer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.successGreen,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Answer:',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correctIndex >= 0 && correctIndex < options.length
                          ? options[correctIndex]
                          : 'No correct answer',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseReview(
    Map<String, dynamic> question,
    Map<String, dynamic>? studentAnswer,
    bool isCorrect,
  ) {
    final correctAnswer = question['answer'] as bool? ?? false;
    final studentAnswerValue = studentAnswer?['selectedBool'] as bool?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.errorRed,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.errorRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Answer: ${studentAnswerValue == true ? "True" : "False"}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.successGreen,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Correct Answer: ${correctAnswer ? "True" : "False"}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentificationReview(
    Map<String, dynamic> question,
    Map<String, dynamic>? studentAnswer,
    bool isCorrect,
  ) {
    final correctAnswer = (question['answer'] as String?) ?? '';
    final studentAnswerValue = (studentAnswer?['typed'] as String?) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.errorRed,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.errorRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Answer:',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentAnswerValue.isEmpty ? 'No answer' : studentAnswerValue,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.successGreen,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Answer:',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correctAnswer.isEmpty ? 'No correct answer' : correctAnswer,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          'Quiz Review',
          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                        _error!,
                        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quiz summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                            Text(
                              widget.quizTitle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Score',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        '${widget.score.toStringAsFixed(0)}/${widget.maxScore.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Percentage',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        '${widget.percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                      
                      // Questions review
                      Text(
                        'Questions Review',
                        style: AppTextStyles.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ...List.generate(_questions.length, (index) => _buildQuestionReview(index)),
                    ],
                  ),
                ),
    );
  }
}

