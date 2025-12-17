import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class InstructorQuizReviewScreen extends StatefulWidget {
  final String quizId;
  final String studentId;
  final String studentName;

  const InstructorQuizReviewScreen({
    super.key,
    required this.quizId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<InstructorQuizReviewScreen> createState() => _InstructorQuizReviewScreenState();
}

class _InstructorQuizReviewScreenState extends State<InstructorQuizReviewScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _studentAnswers = [];
  bool _isLoading = true;
  String? _error;
  String _quizTitle = 'Quiz Review';
  double _score = 0;
  double _maxScore = 0;
  double _percentage = 0;

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

      final firestore = FirebaseFirestore.instance;

      // Load quiz questions
      DocumentSnapshot? quizDoc;
      Map<String, dynamic>? quizData;

      // Try courseQuizzes first
      quizDoc = await firestore.collection('courseQuizzes').doc(widget.quizId).get();
      if (quizDoc.exists) {
        quizData = quizDoc.data() as Map<String, dynamic>?;
        _quizTitle = quizData?['title'] ?? 'Quiz Review';
      } else {
        // Try quizzes collection (may have permission issues)
        try {
          quizDoc = await firestore.collection('quizzes').doc(widget.quizId).get();
          if (quizDoc.exists) {
            quizData = quizDoc.data() as Map<String, dynamic>?;
            _quizTitle = quizData?['title'] ?? 'Quiz Review';
          }
        } catch (e) {
          print('⚠️ Cannot access quizzes collection: $e');
        }
      }

      if (quizData == null) {
        setState(() {
          _error = 'Quiz not found';
          _isLoading = false;
        });
        return;
      }

      _questions = List<Map<String, dynamic>>.from(quizData['questions'] ?? []);

      print('🔍 Looking for quiz attempt:');
      print('   Student ID: ${widget.studentId}');
      print('   Quiz ID: ${widget.quizId}');
      print('   Quiz Title: $_quizTitle');

      // Load student answers from quizAttempts
      // Query by studentId only to avoid composite index requirement
      // Then filter by quizId OR quizTitle and sort in memory
      final attemptsQuery = await firestore
          .collection('quizAttempts')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      print('📋 Found ${attemptsQuery.docs.length} total attempts for student');

      if (attemptsQuery.docs.isEmpty) {
        print('⚠️ No attempts found in quizAttempts, checking studentScores as fallback...');
        
        // Fallback: Try to get from studentScores (but won't have detailed answers)
        final scoreDoc = await firestore
            .collection('studentScores')
            .doc('${widget.studentId}_${widget.quizId}')
            .get();
        
        if (scoreDoc.exists) {
          final scoreData = scoreDoc.data()!;
          print('✅ Found in studentScores, but no detailed answers available');
          setState(() {
            _error = 'Quiz attempt found but detailed answers are not available. Please retake the quiz to see answer details.';
            _score = (scoreData['score'] as num?)?.toDouble() ?? 0;
            _maxScore = (scoreData['maxScore'] as num?)?.toDouble() ?? 0;
            _percentage = _maxScore > 0 ? (_score / _maxScore * 100) : 0;
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _error = 'No quiz attempt found for this student. Make sure the student has completed the quiz.';
          _isLoading = false;
        });
        return;
      }

      // Debug: Print all quizIds found
      print('📋 Quiz IDs found in attempts:');
      for (final doc in attemptsQuery.docs) {
        final data = doc.data();
        final foundQuizId = data['quizId'] as String?;
        final foundQuizTitle = data['quizTitle'] as String?;
        print('   - ID: $foundQuizId, Title: $foundQuizTitle');
      }

      // Filter by quizId OR quizTitle (in case IDs don't match)
      final matchingAttempts = attemptsQuery.docs
          .where((doc) {
            final data = doc.data();
            final foundQuizId = data['quizId'] as String?;
            final foundQuizTitle = data['quizTitle'] as String?;
            
            // Match by ID first
            if (foundQuizId == widget.quizId) {
              return true;
            }
            
            // Match by title as fallback (case-insensitive)
            if (foundQuizTitle != null && _quizTitle.isNotEmpty) {
              final titleMatch = foundQuizTitle.trim().toLowerCase() == _quizTitle.trim().toLowerCase();
              if (titleMatch) {
                print('   ✅ Matched by title: "$foundQuizTitle"');
                return true;
              }
            }
            
            return false;
          })
          .toList();

      print('📊 Found ${matchingAttempts.length} matching attempts for quiz ${widget.quizId}');

      if (matchingAttempts.isEmpty) {
        // Try to get from studentScores as final fallback
        final scoreDoc = await firestore
            .collection('studentScores')
            .doc('${widget.studentId}_${widget.quizId}')
            .get();
        
        if (scoreDoc.exists) {
          final scoreData = scoreDoc.data()!;
          print('✅ Found in studentScores, checking if answers are available...');
          print('   Score data keys: ${scoreData.keys.toList()}');
          
          // Check if answers are stored in studentScores (some old format might have it)
          final answersInScore = scoreData['answers'];
          print('   Answers field type: ${answersInScore.runtimeType}');
          print('   Answers field value: $answersInScore');
          
          if (answersInScore != null) {
            if (answersInScore is List) {
              print('✅ Found answers list in studentScores with ${answersInScore.length} items!');
              _studentAnswers = answersInScore.map((a) {
                if (a is Map) {
                  return Map<String, dynamic>.from(a);
                } else {
                  print('   ⚠️ Warning: Answer item is not a Map: ${a.runtimeType}');
                  return <String, dynamic>{};
                }
              }).toList();
              
              _score = (scoreData['score'] as num?)?.toDouble() ?? 0;
              _maxScore = (scoreData['maxScore'] as num?)?.toDouble() ?? 0;
              _percentage = _maxScore > 0 ? (_score / _maxScore * 100) : 0;
              
              print('   Loaded ${_studentAnswers.length} answers, score: $_score/$_maxScore');
              
              setState(() {
                _isLoading = false;
              });
              return;
            } else {
              print('   ⚠️ Answers field exists but is not a List: ${answersInScore.runtimeType}');
            }
          } else {
            print('   ❌ No answers field in studentScores document');
          }
          
          // No answers available
          print('⚠️ No answers in studentScores - quiz was likely submitted before answer tracking was enabled');
          setState(() {
            _error = 'Quiz attempt found but detailed answers are not available. The quiz may have been submitted before the answer tracking feature was enabled. Please ask the student to retake the quiz to see detailed answers.';
            _score = (scoreData['score'] as num?)?.toDouble() ?? 0;
            _maxScore = (scoreData['maxScore'] as num?)?.toDouble() ?? 0;
            _percentage = _maxScore > 0 ? (_score / _maxScore * 100) : 0;
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _error = 'No quiz attempt found for quiz "${widget.quizId}" (Title: "$_quizTitle"). Found ${attemptsQuery.docs.length} attempts for this student but none match this quiz.';
          _isLoading = false;
        });
        return;
      }

      // Sort by submittedAt descending to get the latest attempt
      matchingAttempts.sort((a, b) {
        final aTime = a.data()['submittedAt'] as Timestamp?;
        final bTime = b.data()['submittedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      // Get the latest attempt
      final attemptData = matchingAttempts.first.data();
      _studentAnswers = List<Map<String, dynamic>>.from(attemptData['answers'] ?? []);
      _score = (attemptData['score'] as num?)?.toDouble() ?? 0;
      _maxScore = (attemptData['maxScore'] as num?)?.toDouble() ?? 0;
      _percentage = _maxScore > 0 ? (_score / _maxScore * 100) : 0;

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

    // Check if wasCorrect is already stored (from student submission)
    final wasCorrect = studentAnswerData['wasCorrect'] as bool?;
    if (wasCorrect != null) {
      return wasCorrect;
    }

    // Otherwise, calculate correctness based on answer type
    if (questionType == 'multiple_choice') {
      // Try both 'selectedIndex' and 'selected' (student saves as 'selected')
      final studentIndex = (studentAnswerData['selectedIndex'] as int?) ?? 
                          (studentAnswerData['selected'] as int?);
      final correctIndex = question['correctIndex'] as int?;
      return studentIndex == correctIndex;
    } else if (questionType == 'true_false') {
      // Try both 'selectedBool' and 'selected' (student saves as 'selected')
      final studentAnswerValue = (studentAnswerData['selectedBool'] as bool?) ?? 
                                 (studentAnswerData['selected'] as bool?);
      final correctAnswer = question['answer'] as bool?;
      return studentAnswerValue == correctAnswer;
    } else if (questionType == 'identification') {
      // Try both 'typed' and 'selected' (student saves as 'selected')
      final studentAnswerValue = ((studentAnswerData['typed'] as String?) ?? 
                                  (studentAnswerData['selected'] as String?))?.trim().toLowerCase() ?? '';
      final correctAnswer = ((question['answer'] as String?) ?? '').trim().toLowerCase();
      return studentAnswerValue.isNotEmpty && studentAnswerValue == correctAnswer;
    } else if (questionType == 'understand_image') {
      if ((question['identification'] as bool?) == true) {
        final studentAnswerValue = ((studentAnswerData['typed'] as String?) ?? 
                                    (studentAnswerData['selected'] as String?))?.trim().toLowerCase() ?? '';
        final correctAnswer = ((question['answer'] as String?) ?? '').trim().toLowerCase();
        return studentAnswerValue.isNotEmpty && studentAnswerValue == correctAnswer;
      } else {
        final studentIndex = (studentAnswerData['selectedIndex'] as int?) ?? 
                            (studentAnswerData['selected'] as int?);
        final correctIndex = question['correctIndex'] as int?;
        return studentIndex == correctIndex;
      }
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
            question['question']?.toString() ?? question['questionText']?.toString() ?? 'Question',
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
          ] else if (questionType == 'understand_image') ...[
            _buildUnderstandImageReview(question, studentAnswer, isCorrect),
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
    // Student saves as 'selected', not 'selectedIndex'
    final studentIndex = (studentAnswer?['selectedIndex'] as int?) ?? 
                        (studentAnswer?['selected'] as int?);

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
                      'Student Answer:',
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
    // Student saves as 'selected', not 'selectedBool'
    final studentAnswerValue = (studentAnswer?['selectedBool'] as bool?) ?? 
                              (studentAnswer?['selected'] as bool?);

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
                'Student Answer: ${studentAnswerValue == true ? "True" : "False"}',
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
    // Student saves as 'selected', not 'typed'
    final studentAnswerValue = ((studentAnswer?['typed'] as String?) ?? 
                                (studentAnswer?['selected'] as String?)) ?? '';

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
                      'Student Answer:',
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

  Widget _buildUnderstandImageReview(
    Map<String, dynamic> question,
    Map<String, dynamic>? studentAnswer,
    bool isCorrect,
  ) {
    final isIdentification = (question['identification'] as bool?) == true;

    if (isIdentification) {
      return _buildIdentificationReview(question, studentAnswer, isCorrect);
    } else {
      return _buildMultipleChoiceReview(question, studentAnswer, isCorrect);
    }
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
          'Quiz Review - ${widget.studentName}',
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
                              _quizTitle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Student: ${widget.studentName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
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
                                        '${_score.toStringAsFixed(0)}/${_maxScore.toStringAsFixed(0)}',
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
                                        '${_percentage.toStringAsFixed(1)}%',
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

