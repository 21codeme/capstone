import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class ThrowingCatchingDay5Screen extends StatelessWidget {
  const ThrowingCatchingDay5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text('Review & Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              icon: Icons.sports_baseball,
              text: 'Final review and synthesis: phases, developmental stages, and key performance factors for a mature throwing skill.',
            ),

            const SizedBox(height: 16),
            Text(
              'Core Lesson: Synthesis and Application',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              title: 'Key Review Points',
              icon: Icons.fact_check,
              lines: const [
                'Phases: Preparatory (build force), Execution (apply force), Follow-Through (decelerate/control).',
                'Stages: 1 (stationary) → 3 (ipsilateral) → 5 (fully integrated contralateral).',
                'Factors: Instruction, Knowledge, Critical Cues, Implement, Angle of Release, Gender Differences.',
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'Discussion and Reflection',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              title: 'Prompts',
              icon: Icons.psychology,
              lines: const [
                'Reflection: Imagine you are a physical education teacher. How would you use the knowledge of the five developmental stages to assess and create personalized throwing drills for your students?',
                'Discussion: Design a simple experiment to test the effect of Implement Size, Shape, and Weight on the throwing performance of an adult. What would be your hypothesis?',
                'Discussion: Based on all the material, formulate a single, comprehensive definition of a "mature throwing skill" that incorporates elements from the phases, stages, and influencing factors.',
              ],
            ),

            const SizedBox(height: 24),
            const _MiniQuizSection(),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;
  const _InfoCard({required this.title, required this.icon, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final l in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fiber_manual_record, size: 10, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniQuizSection extends StatefulWidget {
  const _MiniQuizSection();
  @override
  State<_MiniQuizSection> createState() => _MiniQuizSectionState();
}

class _MiniQuizSectionState extends State<_MiniQuizSection> {
  late List<Map<String, dynamic>> _questions;
  late List<dynamic> _answers;
  List<TextEditingController?> _idControllers = [];
  List<FocusNode?> _idFocusNodes = [];
  bool _submitted = false;
  int _score = 0;
  int _maxScore = 0;
  bool _passed = false;
  final String _quizId = 'throw_catch_day5';
  int _attemptNumber = 0;
  bool _alreadyPassed = false;
  String? _uid;
  String? _studentName;
  String? _course;
  String? _year;
  String? _section;

  @override
  void initState() {
    super.initState();
    _initQuestions();
    _loadUserData();
  }

  void _initQuestions() {
    _questions = [
      {
        'type': 'multiple_choice',
        'text': 'The three phases of throwing are:',
        'options': ['Stance, Wind-up, Release', 'Preparatory, Execution, Follow-through', 'Stage 1, Stage 3, Stage 5', 'Instruction, Knowledge, Cues'],
        'correctIndex': 1,
        'points': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'Which developmental stage is characterized by an ipsilateral arm-leg action with little to no trunk rotation?',
        'options': ['Stage 1', 'Stage 2', 'Stage 3', 'Stage 4'],
        'correctIndex': 2,
        'points': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'Which of the following is NOT a factor that influences throwing performance?',
        'options': ['Knowledge', 'Critical Cues', 'Age of Performer', 'Angle of Release'],
        'correctIndex': 2,
        'points': 2,
      },
      {
        'type': 'identification',
        'text': "Stage where feet are primarily stationary and no trunk rotation is observed.",
        'answer': 'Stage 1',
        'altAnswers': ['stage 1', 'stage one', 'first stage', 'newly learned skill'],
        'points': 3,
      },
      {
        'type': 'identification',
        'text': 'Factor requiring a knowledgeable instructor to provide proper points like trunk rotation and stride length.',
        'answer': 'Instruction',
        'altAnswers': ['instruction', 'teacher instruction', 'coaching instruction'],
        'points': 3,
      },
      {
        'type': 'identification',
        'text': 'Stage that dramatically shows an extensive countermovement in the preparatory phase.',
        'answer': 'Stage 5',
        'altAnswers': ['stage 5', 'stage five', 'fully integrated contralateral'],
        'points': 3,
      },
      {
        'type': 'true_false',
        'text': 'Stage 4 (Pre-Mature Stage) involves observable contralateral arm-leg movements.',
        'answer': true,
        'points': 0,
      },
      {
        'type': 'true_false',
        'text': 'Angle of Release determines the size, shape, and weight of the implement.',
        'answer': false,
        'points': 0,
      },
      {
        'type': 'true_false',
        'text': 'Throwing is considered a discrete skill because it combines object manipulation and explosive movements.',
        'answer': true,
        'points': 0,
      },
    ];
    _answers = List.filled(_questions.length, null);
    _idControllers = List.generate(_questions.length, (_) => null);
    _idFocusNodes = List.generate(_questions.length, (_) => null);
    _submitted = false;
    _score = 0;
    _maxScore = _questions.fold<int>(0, (p, e) => p + (e['points'] as int));
    _passed = false;
  }

  Future<void> _loadUserData() async {
    final auth = FirebaseAuthService();
    final user = auth.currentUser;
    if (user == null) return;
    _uid = user.uid;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get(const GetOptions(source: Source.server));
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _studentName = (data['fullName'] as String?) ?? ((data['firstName'] ?? '') + ' ' + (data['lastName'] ?? ''));
        _course = data['course'] as String?;
        _year = data['year'] as String?;
        _section = data['section'] as String?;
      }
      final scoreDocId = '${_uid}_${_quizId}';
      final scoreDoc = await FirebaseFirestore.instance.collection('studentScores').doc(scoreDocId).get(const GetOptions(source: Source.server));
      if (scoreDoc.exists) {
        final sdata = scoreDoc.data() as Map<String, dynamic>;
        final hasAnswered = (sdata['hasAnswered'] as bool?) ?? false;
        final passed = (sdata['passed'] as bool?) ?? false;
        if (hasAnswered && passed) {
          setState(() {
            _alreadyPassed = true;
            _submitted = true;
            _passed = true;
            final sc = sdata['score'];
            _score = sc is int ? sc : (sc is double ? sc.round() : 0);
            _maxScore = (sdata['maxScore'] is int) ? (sdata['maxScore'] as int) : _maxScore;
          });
        } else {
          setState(() {
            _alreadyPassed = false;
            _submitted = false;
            _passed = false;
            _score = 0;
          });
        }
      }
      final attemptsQuery = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('studentId', isEqualTo: _uid)
          .where('quizId', isEqualTo: _quizId)
          .get(const GetOptions(source: Source.server));
      _attemptNumber = attemptsQuery.docs.length;
    } catch (_) {}
  }

  void _retake() {
    _answers = List.filled(_questions.length, null);
    setState(() {
      _submitted = false;
      _score = 0;
      _passed = false;
    });
  }

  Future<void> _resetQuizState() async {
    if (_uid == null || _uid!.isEmpty) return;
    final scoreDocId = '${_uid}_${_quizId}';
    try {
      await FirebaseFirestore.instance.collection('studentScores').doc(scoreDocId).delete();
    } catch (_) {
      try {
        await FirebaseFirestore.instance.collection('studentScores').doc(scoreDocId).set({
          'hasAnswered': false,
          'passed': false,
          'score': 0,
          'maxScore': _maxScore,
          'percentage': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    try {
      final attemptsQuery = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('studentId', isEqualTo: _uid)
          .where('quizId', isEqualTo: _quizId)
          .get();
      for (final d in attemptsQuery.docs) {
        await d.reference.delete();
      }
    } catch (_) {}
    _answers = List.filled(_questions.length, null);
    setState(() {
      _alreadyPassed = false;
      _submitted = false;
      _passed = false;
      _score = 0;
    });
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    final type = q['type'] as String;
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
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(q['text'] as String, style: AppTextStyles.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 12),
          if (type == 'multiple_choice') ...[
            for (int i = 0; i < (q['options'] as List<String>).length; i++) ...[
              RadioListTile<int>(
                value: i,
                groupValue: _answers[index] as int?,
                onChanged: _submitted ? null : (v) => setState(() => _answers[index] = v),
                title: Text((q['options'] as List<String>)[i]),
              ),
            ],
          ] else if (type == 'true_false') ...[
            RadioListTile<bool>(
              value: true,
              groupValue: _answers[index] as bool?,
              onChanged: _submitted ? null : (v) => setState(() => _answers[index] = v),
              title: const Text('True'),
            ),
            RadioListTile<bool>(
              value: false,
              groupValue: _answers[index] as bool?,
              onChanged: _submitted ? null : (v) => setState(() => _answers[index] = v),
              title: const Text('False'),
            ),
          ] else if (type == 'identification') ...[
            TextField(
              controller: _idControllers[index] ??= TextEditingController(),
              focusNode: _idFocusNodes[index] ??= FocusNode(),
              enabled: !_submitted,
              decoration: const InputDecoration(hintText: 'Type your answer'),
              onChanged: (v) => _answers[index] = v,
            ),
          ],
        ],
      ),
    );
  }

  void _submit() async {
    if (_submitted) return;
    int scored = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final type = q['type'] as String;
      final ans = _answers[i];
      final points = q['points'] as int;
      bool isCorrect = false;
      if (type == 'multiple_choice') {
        isCorrect = (ans is int) && ans == (q['correctIndex'] as int);
      } else if (type == 'true_false') {
        isCorrect = (ans is bool) && ans == (q['answer'] as bool);
      } else if (type == 'identification') {
        final expected = (q['answer'] as String).toLowerCase().trim();
        final alts = ((q['altAnswers'] as List?) ?? []).map((e) => (e as String).toLowerCase().trim()).toList();
        final given = (ans is String) ? ans.toLowerCase().trim() : '';
        isCorrect = given == expected || alts.contains(given);
      }
      if (isCorrect) scored += points;
    }
    setState(() {
      _submitted = true;
      _score = scored;
      _passed = (_score / _maxScore) * 100.0 >= 60.0;
    });

    final percentage = (_score / _maxScore) * 100.0;
    final answers = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final type = q['type'] as String;
      if (type == 'multiple_choice') {
        answers.add({'index': i, 'selectedIndex': _answers[i]});
      } else if (type == 'true_false') {
        answers.add({'index': i, 'selectedBool': _answers[i]});
      } else if (type == 'identification') {
        answers.add({'index': i, 'text': (_answers[i] ?? '')});
      }
    }
    try {
      final qs = QuizService();
      final attemptNo = _attemptNumber + 1;
      await qs.logQuizAttempt(
        studentId: _uid ?? FirebaseAuthService().currentUser?.uid ?? '',
        quizId: _quizId,
        quizTitle: 'Day 5 Mini Quiz: Throwing & Catching',
        score: _score.toDouble(),
        maxScore: _maxScore.toDouble(),
        percentage: percentage,
        passed: _passed,
        attemptNumber: attemptNo,
      );
      if (_passed) {
        await qs.submitStudentQuizAttempt(
          studentId: _uid ?? FirebaseAuthService().currentUser?.uid ?? '',
          quizId: _quizId,
          quizTitle: 'Day 5 Mini Quiz: Throwing & Catching',
          score: _score.toDouble(),
          maxScore: _maxScore.toDouble(),
          percentage: percentage,
          passed: true,
          answers: answers,
          timeTakenMinutes: 0,
          studentName: _studentName,
          course: _course,
          year: _year,
          section: _section,
        );
        try {
          final sid = _uid ?? FirebaseAuthService().currentUser?.uid ?? '';
          final docId = '${sid}_${_quizId}';
          await FirebaseFirestore.instance.collection('studentScores').doc(docId).set({'attempts': attemptNo}, SetOptions(merge: true));
        } catch (_) {}
        setState(() {
          _alreadyPassed = true;
        });
      } else {
        _attemptNumber = attemptNo;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Mini Quiz · Day 5', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.primaryBlue)),
              ),
              const Spacer(),
              if (_submitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_passed ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_passed ? 'Passed' : 'Failed', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: _passed ? Colors.green : Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 12),
              if (_submitted)
                ElevatedButton(
                  onPressed: _alreadyPassed ? null : _retake,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  child: const Text('Retake', style: TextStyle(color: Colors.white)),
                ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _resetQuizState,
                child: const Text('Reset quiz state'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}