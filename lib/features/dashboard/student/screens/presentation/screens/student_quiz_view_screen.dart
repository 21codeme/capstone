import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/features/auth/presentation/providers/auth_provider.dart';
import 'package:pathfitcapstone/core/services/quiz_service.dart';

class StudentQuizViewScreen extends StatefulWidget {
  final String quizId;
  const StudentQuizViewScreen({super.key, required this.quizId});

  @override
  State<StudentQuizViewScreen> createState() => _StudentQuizViewScreenState();
}

class _StudentQuizViewScreenState extends State<StudentQuizViewScreen> {
  Map<String, dynamic>? _quiz;
  List<Map<String, dynamic>> _questions = [];
  List<dynamic> _answers = []; // per-index: int|bool|String
  bool _loading = true;
  String? _error;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _submitted = false;
  List<TextEditingController?> _idControllers = [];
  List<FocusNode?> _idFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _idControllers) {
      c?.dispose();
    }
    for (final f in _idFocusNodes) {
      f?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      // Prevent re-answer: check if the student has already answered this quiz
      try {
        final auth = context.read<AuthProvider>();
        final uid = auth.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          final lockDoc = await FirebaseFirestore.instance
              .collection('studentScores')
              .doc('${uid}_${widget.quizId}')
              .get();
          final hasAnswered = lockDoc.exists && ((lockDoc.data()?['hasAnswered'] as bool?) ?? false);
          if (hasAnswered) {
            setState(() {
              _error = 'You have already answered this quiz.';
              _loading = false;
            });
            return;
          }
        }
      } catch (_) {}

      final doc = await FirebaseFirestore.instance.collection('courseQuizzes').doc(widget.quizId).get();
      if (!doc.exists) {
        setState(() {
          _error = 'Quiz not found or access denied';
          _loading = false;
        });
        return;
      }
      final data = doc.data()!;
      // Enforce availability window if configured
      try {
        final fromTs = data['availableFrom'] as Timestamp?;
        final untilTs = data['availableUntil'] as Timestamp?;
        final now = DateTime.now();
        if (fromTs != null && now.isBefore(fromTs.toDate())) {
          setState(() {
            _error = 'This quiz is not yet open.';
            _loading = false;
          });
          return;
        }
        if (untilTs != null && now.isAfter(untilTs.toDate())) {
          setState(() {
            _error = 'This quiz has closed.';
            _loading = false;
          });
          return;
        }
      } catch (_) {}
      final type = (data['type'] as String?) ?? 'multiple_choice';
      final shuffleQuestions = (data['shuffleQuestions'] as bool?) ?? false;
      final shuffleOptions = (data['shuffleOptions'] as bool?) ?? false;
      final timeLimitMinutes = (data['timeLimitMinutes'] as int?) ?? 0;

      List<Map<String, dynamic>> questionsRaw = List<Map<String, dynamic>>.from(data['questions'] ?? const []);
      if (type == 'custom') {
        // questions have per-item type
      }
      // Shuffle questions if enabled
      if (shuffleQuestions) {
        questionsRaw.shuffle(Random());
      }

      // Normalize questions for rendering/scoring; keep option index mapping when shuffling
      final normalized = <Map<String, dynamic>>[];
      final rnd = Random();
      for (final q in questionsRaw) {
        final qType = (q['type'] as String?) ?? type;
        final base = {'type': qType};
        if (qType == 'multiple_choice') {
          final options = List<String>.from((q['options'] as List?) ?? const []);
          int correctIndex = (q['correctIndex'] as int?) ?? 0;
          List<Map<String, dynamic>> display = [for (int i = 0; i < options.length; i++) {'text': options[i], 'origIndex': i}];
          if (shuffleOptions) display.shuffle(rnd);
          // locate new correct index by original index match
          final newCorrect = display.indexWhere((e) => e['origIndex'] == correctIndex);
          normalized.add({
            ...base,
            'text': (q['text'] as String?) ?? '',
            'options': display,
            'correctIndex': max(0, newCorrect),
          });
        } else if (qType == 'true_false') {
          normalized.add({
            ...base,
            'text': (q['text'] as String?) ?? '',
            'answer': (q['answer'] as bool?) ?? false,
          });
        } else if (qType == 'identification') {
          normalized.add({
            ...base,
            'text': (q['text'] as String?) ?? '',
            'answer': (q['answer'] as String?) ?? '',
          });
        } else if (qType == 'understand_image') {
          final isIdentification = (q['answer'] as String?) != null;
          if (isIdentification) {
            normalized.add({
              ...base,
              'text': (q['text'] as String?) ?? '',
              'imageUrl': (q['imageUrl'] as String?) ?? '',
              'answer': (q['answer'] as String?) ?? '',
              'identification': true,
            });
          } else {
            final optionsImages = List<String>.from((q['optionsImages'] as List?) ?? const []);
            final optionsText = List<String>.from((q['options'] as List?) ?? const []);
            int correctIndex = (q['correctIndex'] as int?) ?? 0;
            List<Map<String, dynamic>> display;
            if (optionsImages.isNotEmpty) {
              display = [for (int i = 0; i < optionsImages.length; i++) {'image': optionsImages[i], 'origIndex': i}];
            } else {
              display = [for (int i = 0; i < optionsText.length; i++) {'text': optionsText[i], 'origIndex': i}];
            }
            if (shuffleOptions) display.shuffle(rnd);
            final newCorrect = display.indexWhere((e) => e['origIndex'] == correctIndex);
            normalized.add({
              ...base,
              'text': (q['text'] as String?) ?? '',
              'imageUrl': (q['imageUrl'] as String?) ?? '',
              'options': display,
              'correctIndex': max(0, newCorrect),
              'identification': false,
            });
          }
        }
      }

      setState(() {
        _quiz = data;
        _questions = normalized;
        _answers = List.filled(_questions.length, null);
        _loading = false;
        _remainingSeconds = timeLimitMinutes > 0 ? timeLimitMinutes * 60 : 0;
        _idControllers = List<TextEditingController?>.filled(_questions.length, null);
        _idFocusNodes = List<FocusNode?>.filled(_questions.length, null);
      });

      if (_remainingSeconds > 0) {
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              _remainingSeconds = 0;
              _timer?.cancel();
            }
          });
          if (_remainingSeconds == 0 && !_submitted) {
            _submit();
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load quiz: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitted) return;
    setState(() => _submitted = true);

    final points = (_quiz?['pointsPerQuestion'] as int?) ?? 1;
    int correct = 0;
    final answerRecords = <Map<String, dynamic>>[];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final qType = (q['type'] as String?) ?? 'multiple_choice';
      final ans = _answers[i];
      bool isCorrect = false;

      if (qType == 'multiple_choice') {
        isCorrect = (ans is int) && ans == (q['correctIndex'] as int? ?? -1);
      } else if (qType == 'true_false') {
        isCorrect = (ans is bool) && ans == (q['answer'] as bool? ?? false);
      } else if (qType == 'identification') {
        final correctAns = ((q['answer'] as String?) ?? '').trim().toLowerCase();
        final studentAns = (ans is String) ? ans.trim().toLowerCase() : '';
        isCorrect = studentAns.isNotEmpty && studentAns == correctAns;
      } else if (qType == 'understand_image') {
        if ((q['identification'] as bool?) == true) {
          final correctAns = ((q['answer'] as String?) ?? '').trim().toLowerCase();
          final studentAns = (ans is String) ? ans.trim().toLowerCase() : '';
          isCorrect = studentAns.isNotEmpty && studentAns == correctAns;
        } else {
          isCorrect = (ans is int) && ans == (q['correctIndex'] as int? ?? -1);
        }
      }

      if (isCorrect) correct++;
      answerRecords.add({
        'type': qType,
        'selected': ans,
        'correctIndex': q['correctIndex'],
        'correctAnswer': q['answer'],
        'wasCorrect': isCorrect,
      });
    }

    final maxScore = points * _questions.length;
    final score = points * correct;
    final percentage = maxScore > 0 ? (score / maxScore) * 100.0 : 0.0;
    final passed = percentage >= 60.0;

    try {
      final student = context.read<AuthProvider>().currentUser;
      final studentModel = context.read<AuthProvider>().currentUserModel;
      final studentId = student?.uid ?? '';
      final service = QuizService();
      final res = await service.submitStudentQuizAttempt(
        studentId: studentId,
        quizId: widget.quizId,
        quizTitle: (_quiz?['title'] as String?) ?? 'Quiz',
        score: score.toDouble(),
        maxScore: maxScore.toDouble(),
        percentage: percentage,
        passed: passed,
        answers: answerRecords,
        timeTakenMinutes: _computeTimeTakenMinutes(),
        status: 'submitted',
        // Extra student details for analytics tracking
        studentName: studentModel?.fullName,
        course: studentModel?.course,
        year: studentModel?.year,
        section: studentModel?.section,
      );

      if (!mounted) return;
      if (res['success'] == true) {
        _showResultDialog(score, maxScore, percentage, passed);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attempt: ${res['error']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission error: $e')),
      );
    }
  }

  int _computeTimeTakenMinutes() {
    final total = ((_quiz?['timeLimitMinutes'] as int?) ?? 0) * 60;
    if (total <= 0) return 0;
    final spent = max(0, total - _remainingSeconds);
    return (spent / 60).ceil();
  }

  void _showResultDialog(int score, int maxScore, double percentage, bool passed) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: $score / $maxScore'),
            const SizedBox(height: 8),
            Text('Percentage: ${percentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text(passed ? 'Status: Passed' : 'Status: Failed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(child: Text(_error!)),
      );
    }

    final title = (_quiz?['title'] as String?) ?? 'Quiz';
    final instructions = (_quiz?['instructions'] as String?) ?? '';
    final timeLimitMinutes = (_quiz?['timeLimitMinutes'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (instructions.isNotEmpty)
                    Text(
                      instructions,
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        timeLimitMinutes > 0
                            ? 'Time limit: $timeLimitMinutes min  •  Remaining: ${_formatRemaining()}'
                            : 'No time limit',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Questions
            for (int i = 0; i < _questions.length; i++) ...[
              _buildQuestionCard(i, _questions[i]),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitted ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRemaining() {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    final qType = (q['type'] as String?) ?? 'multiple_choice';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((q['imageUrl'] as String?)?.isNotEmpty == true)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(q['imageUrl'], height: 140, fit: BoxFit.cover),
                      ),
                    if ((q['text'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(q['text'], style: AppTextStyles.textTheme.titleMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (qType == 'multiple_choice') ...[
            for (int i = 0; i < (q['options'] as List).length; i++) ...[
              RadioListTile<int>(
                value: i,
                groupValue: _answers[index] as int?,
                onChanged: (v) => setState(() => _answers[index] = v),
                title: Text(((q['options'] as List)[i]['text'] as String?) ?? ''),
              ),
            ],
          ] else if (qType == 'true_false') ...[
            RadioListTile<bool>(
              value: true,
              groupValue: _answers[index] as bool?,
              onChanged: (v) => setState(() => _answers[index] = v),
              title: const Text('True'),
            ),
            RadioListTile<bool>(
              value: false,
              groupValue: _answers[index] as bool?,
              onChanged: (v) => setState(() => _answers[index] = v),
              title: const Text('False'),
            ),
          ] else if (qType == 'identification' || ((q['identification'] as bool?) == true)) ...[
            Builder(
              builder: (context) {
                _idControllers[index] ??= TextEditingController(text: _answers[index] as String? ?? '');
                _idFocusNodes[index] ??= FocusNode();
                final controller = _idControllers[index]!;
                final focusNode = _idFocusNodes[index]!;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type your answer'),
                  onTap: () => FocusScope.of(context).requestFocus(focusNode),
                  onChanged: (v) => setState(() => _answers[index] = v),
                );
              },
            ),
          ] else if (qType == 'understand_image') ...[
            for (int i = 0; i < (q['options'] as List).length; i++) ...[
              Builder(
                builder: (context) {
                  final opt = (q['options'] as List)[i] as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: opt.containsKey('image')
                        ? Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: _answers[index] as int?,
                                onChanged: (v) => setState(() => _answers[index] = v),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(opt['image'], height: 100, fit: BoxFit.cover),
                                ),
                              ),
                            ],
                          )
                        : RadioListTile<int>(
                            value: i,
                            groupValue: _answers[index] as int?,
                            onChanged: (v) => setState(() => _answers[index] = v),
                            title: Text((opt['text'] as String?) ?? ''),
                          ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}