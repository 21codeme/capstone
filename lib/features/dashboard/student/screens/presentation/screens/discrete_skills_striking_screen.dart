import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class DiscreteSkillsStrikingScreen extends StatelessWidget {
  const DiscreteSkillsStrikingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text('Striking Discrete Skills'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              icon: Icons.sports_martial_arts,
              text: 'Striking applies explosive force with limbs; phased patterns for hands and feet develop from novice to mature.',
            ),

            const SizedBox(height: 16),
            Text(
              'Learning Objectives',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              title: 'What you will learn',
              icon: Icons.auto_awesome,
              lines: const [
                'Three phases of striking with the hands: Preparatory, Force Production, Follow‑Through.',
                'Developmental aspects: Early → Developing (wide base, contralateral action) → Mature (full follow‑through).',
                'Striking with the feet mirrors hand phases; originates from torso/core.',
                'Kicking developmental stages: 1 (Novice) → 2 → 3 (approach steps).',
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'Phases of Striking (Hands)',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _MovementCard(
              icon: Icons.sports_kabaddi,
              title: 'Preparatory Phase',
              description: 'Initial phase; patterns similar to throwing.',
            ),
            const SizedBox(height: 12),
            _MovementCard(
              icon: Icons.flash_on,
              title: 'Force Production',
              description: 'Movement shifts from back to forward to generate explosive force.',
            ),
            const SizedBox(height: 12),
            _MovementCard(
              icon: Icons.track_changes,
              title: 'Follow‑Through Phase',
              description: 'Completion phase ensuring safe deceleration and direction control.',
            ),

            const SizedBox(height: 24),
            Text(
              'Developmental Progression',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              title: 'Throwing/Striking Development',
              icon: Icons.timeline,
              lines: const [
                'Early Stage: stationary stance, minimal trunk rotation.',
                'Developing Stage: wider base of support, contralateral action emerges.',
                'Mature Phase: full follow‑through completed.',
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Kicking (Feet) Phases & Stages',
              icon: Icons.sports_soccer,
              lines: const [
                'Phases identical to hand striking and originate from the torso/core.',
                'Stage 1 (Novice): stationary target; thigh moves forward without countermovement; arms uncoordinated.',
                'Stage 2: countermovement in kicking leg; arms oppose legs.',
                'Stage 3: one or two approach steps are observable.',
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
                'Phase Breakdown: tennis serve or boxing punch; name actions in each phase.',
                'Developmental Observation: novice vs experienced kicking in context of stages.',
                'Torso’s Role: how core strength enables explosive striking and maturation.',
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
  final String _quizId = 'discrete_skills_day4';
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
        'text': 'Which is NOT one of the three phases of striking with the hands?',
        'options': ['Preparatory Phase', 'Stabilization Phase', 'Force Production', 'Follow-Through Phase'],
        'correctIndex': 1,
        'points': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'What is the key characteristic of Stage 1 (Novice) in kicking?',
        'options': ['Approach steps', 'Fully developed follow-through', 'Thigh moves forward without countermovement', 'Arms oppose legs'],
        'correctIndex': 2,
        'points': 2,
      },
      {
        'type': 'identification',
        'text': 'Fundamental motor skill using a body part to apply explosive force to an object.',
        'answer': 'Striking',
        'altAnswers': ['striking'],
        'points': 3,
      },
      {
        'type': 'identification',
        'text': 'Developmental stage where a wide base of support and contralateral action are established.',
        'answer': 'Developing Stage',
        'altAnswers': ['developing stage', 'developing'],
        'points': 3,
      },
      {
        'type': 'true_false',
        'text': 'The phases of the kicking skill are identical to the phases of striking using the hands.',
        'answer': true,
        'points': 0,
      },
      {
        'type': 'true_false',
        'text': 'In the developing stage of throwing/striking, a fully developed follow-through is observed.',
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
    _questions.shuffle(Random());
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
      _questions.shuffle(Random());
      _idControllers = List.generate(_questions.length, (_) => null);
      _idFocusNodes = List.generate(_questions.length, (_) => null);
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
        quizTitle: 'Day 4 Mini Quiz',
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
          quizTitle: 'Day 4 Mini Quiz',
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
                    'Day 4 Mini Quiz',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
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