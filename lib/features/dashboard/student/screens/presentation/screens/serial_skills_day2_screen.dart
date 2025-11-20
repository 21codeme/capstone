import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class SerialSkillsDay2Screen extends StatelessWidget {
  const SerialSkillsDay2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text('The Importance of Transitions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroCard(
              icon: Icons.sync_alt,
              text: 'Transitions are the most difficult part of serial skills to learn. They require mindful recognition of cues and coaching to blend discrete skills smoothly.',
            ),

            const SizedBox(height: 16),
            Text(
              'Core Lesson',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const _InfoCard(
              title: 'Mastering the Junctions',
              icon: Icons.auto_awesome,
              lines: [
                'Transitions demand attention to cues and guided practice.',
                'The performer must be mindful during the junction between discrete skills.',
                'Coaching helps identify the right adjustments at the transition phase.',
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'Key Aspects of Transitions',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _MovementCard(
              icon: Icons.textsms,
              title: 'Cues',
              description: 'Feedback indicating if adjustments are needed for the whole skill; cues come from the environment or implement dynamics.',
            ),
            const SizedBox(height: 12),
            const _MovementCard(
              icon: Icons.sensors,
              title: 'Training Goal',
              description: 'Coordinate two discrete skills so the transition is seamless, minimizing recognizable change in execution patterns.',
            ),
            const SizedBox(height: 12),
            const _MovementCard(
              icon: Icons.speed,
              title: 'Performance Improvement',
              description: 'Smoothness, efficiency, and speed improve as transitions are trained and practiced well.',
            ),

            const SizedBox(height: 24),
            Text(
              'Self-Paced Learning & Discussion',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const _InfoCard(
              title: 'Reflection and Prompts',
              icon: Icons.psychology,
              lines: [
                'Reflection: Was it harder to learn steps or to link them smoothly?',
                'Discussion: How does minimizing recognizable change improve efficiency and speed?',
                'Discussion: Tennis transition cues between forehand and backhand (environmental and internal).',
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

class _MovementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _MovementCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.16),
                  AppColors.primaryBlue.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),
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
  final String _quizId = 'serial_skills_day2';
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
        'text': 'Compared to discrete and continuous skills, serial skills are more difficult to learn because they involve:',
        'options': ['More muscle groups', 'Transitions', 'Faster movements', 'Less practice'],
        'correctIndex': 1,
        'points': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'Cues during the transition phase serve as feedback to the performer for:',
        'options': [
          'Adjustments needed for the whole skill.',
          'The speed of the next discrete skill.',
          'The end of the entire serial skill.',
          'The positioning of opponents.',
        ],
        'correctIndex': 0,
        'points': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'The main goal in coordinating two discrete skills is to make the transition:',
        'options': [
          'As fast as possible.',
          'As powerful as possible.',
          'As seamless as possible.',
          'As recognizable as possible.',
        ],
        'correctIndex': 2,
        'points': 2,
      },
      {
        'type': 'identification',
        'text': 'The elements that can come from the performer\'s environment and help in the transition phase.',
        'answer': 'Cues',
        'altAnswers': ['cue', 'environmental cues', 'internal cues'],
        'points': 3,
      },
      {
        'type': 'identification',
        'text': 'The characteristic of execution that is improved as transitions are trained and practiced well.',
        'answer': 'Smoothness',
        'altAnswers': ['efficiency', 'speed', 'smoothness of execution'],
        'points': 3,
      },
      {
        'type': 'identification',
        'text': 'The type of change in patterns that should be minimized in a successful transition.',
        'answer': 'Recognizable change',
        'altAnswers': ['recognizable changes', 'recognizable pattern change', 'change in patterns'],
        'points': 3,
      },
      {
        'type': 'true_false',
        'text': 'Cues at the transition phase dictate the discrete skill to fit and sequence with the first one.',
        'answer': true,
        'points': 0,
      },
      {
        'type': 'true_false',
        'text': 'Serial skills are more difficult to learn compared to discrete skills because they involve more changes in positioning, stance, and balance.',
        'answer': true,
        'points': 0,
      },
      {
        'type': 'true_false',
        'text': 'The primary focus of training transitions is to increase the speed of the discrete skills involved.',
        'answer': false,
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
        quizTitle: 'Day 2 Mini Quiz: Serial Skills',
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
          quizTitle: 'Day 2 Mini Quiz: Serial Skills',
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: _resetQuizState,
                  child: Text(
                    'Day 2 Mini Quiz',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipLabel('Multiple Choice'),
                    _ChipLabel('Identification'),
                    _ChipLabel('True or False'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_alreadyPassed) ...[
            for (int i = 0; i < _questions.length; i++) ...[
              _buildQuestionCard(i, _questions[i]),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitted || _alreadyPassed ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          if (_submitted) ...[
            const SizedBox(height: 12),
            Container(
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
                      Icon(_passed ? Icons.check_circle : Icons.cancel, color: _passed ? AppColors.successGreen : AppColors.errorRed),
                      const SizedBox(width: 8),
                      Text(
                        _passed ? 'Passed' : 'Failed',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: _passed ? AppColors.successGreen : AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Score: $_score / $_maxScore', style: AppTextStyles.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Back to Topics', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  const _ChipLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(label, style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
    );
  }
}