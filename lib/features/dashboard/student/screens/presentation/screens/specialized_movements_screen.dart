import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class SpecializedMovementsScreen extends StatelessWidget {
  const SpecializedMovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text('Specialized Movements'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Icon(Icons.auto_awesome_motion, color: AppColors.primaryBlue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Some body parts exhibit specialized movements due to unique musculoskeletal structures. Understanding these helps analyze functional motion and joint mechanics.',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Specialized Movements',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _InfoCard(
                title: 'Overview',
                icon: Icons.auto_awesome,
                lines: const [
                  'Certain body parts have unique movement names',
                  'These arise from specialized musculoskeletal structures',
                  'Helps analyze function and joint mechanics precisely',
                  'Grouped by primary location and effect',
                ],
              ),

              const SizedBox(height: 24),

              _MovementCard(
                icon: Icons.arrow_upward,
                title: 'Elevation',
                description: 'Upward movement of the scapula (shoulder blade).',
                location: 'Scapula (Upper Back)'
              ),

              const SizedBox(height: 12),

              _MovementCard(
                icon: Icons.arrow_downward,
                title: 'Depression',
                description: 'Downward movement of the scapula.',
                location: 'Scapula (Upper Back)'
              ),

              const SizedBox(height: 12),

              _MovementCard(
                icon: Icons.pan_tool,
                title: 'Pronation',
                description: 'Facing-down movement of the palm via radioulnar rotation at the elbow.',
                location: 'Forearm'
              ),

              const SizedBox(height: 12),

              _MovementCard(
                icon: Icons.back_hand,
                title: 'Supination',
                description: 'Facing-up movement of the palm via radioulnar rotation at the elbow.',
                location: 'Forearm'
              ),

              const SizedBox(height: 12),

              _MovementCard(
                icon: Icons.circle,
                title: 'Circumduction',
                description: 'Movement in ball-and-socket joints combining lateral flexion and flexion-hyperextension to create a circular motion.',
                location: 'Shoulder and Hip Joints'
              ),

              const SizedBox(height: 12),

              _InfoCard(
                title: 'Observation Tip',
                icon: Icons.visibility,
                lines: const [
                  'Scapular movement is hard to observe directly',
                  'Use shoulder elevation and depression as indicators',
                ],
              ),

              const SizedBox(height: 24),
              _MiniQuizSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String location;

  const _MovementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Primary Location: $location',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.primaryBlue,
                fontStyle: FontStyle.italic,
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
  const _InfoCard({super.key, required this.title, required this.icon, required this.lines});

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
                  color: AppColors.primaryBlue.withOpacity(0.1),
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

class _ChipLabel extends StatelessWidget {
  final String label;
  const _ChipLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniQuizSection extends StatefulWidget {
  @override
  State<_MiniQuizSection> createState() => _MiniQuizSectionState();
}

class _MiniQuizSectionState extends State<_MiniQuizSection> {
  late List<Map<String, dynamic>> _questions;
  List<dynamic> _answers = [];
  bool _submitted = false;
  bool _alreadyPassed = false;
  bool _passed = false;
  int _score = 0;
  int _maxScore = 10;
  int _attempts = 0;
  String? _uid;
  String? _studentName;
  String? _course;
  String? _year;
  String? _section;
  int _attemptNumber = 0;

  @override
  void initState() {
    super.initState();
    _initQuestions();
    _loadUserData();
  }

  void _initQuestions() {
    _questions = [
      {
        'text': 'Pronation and Supination are specialized movements specific to which body part?',
        'type': 'multiple_choice',
        'options': ['Scapula', 'Trunk', 'Forearm', 'Hip'],
        'correctIndex': 2,
        'explanation': 'These are forearm rotational movements.',
      },
      {
        'text': 'Circumduction is a specialized movement that happens in which type of joint?',
        'type': 'multiple_choice',
        'options': ['Hinge joint', 'Pivot joint', 'Ball and socket articulation', 'Saddle joint'],
        'correctIndex': 2,
        'explanation': 'Ball and socket joints permit circumduction.',
      },
      {
        'text': 'The specialized movement of the scapula that involves moving the shoulder upward is called:',
        'type': 'multiple_choice',
        'options': ['Retraction', 'Elevation', 'Protraction', 'Depression'],
        'correctIndex': 1,
        'explanation': 'Elevation raises the shoulder.',
      },
      {
        'text': 'The movement of the forearm where the palm is facing down is called:',
        'type': 'multiple_choice',
        'options': ['Supination', 'Pronation', 'Inversion', 'Rotation'],
        'correctIndex': 1,
        'explanation': 'Pronation faces the palm downward.',
      },
      {
        'text': 'Which movement refers to moving the scapula forward around the rib cage?',
        'type': 'multiple_choice',
        'options': ['Protraction', 'Retraction', 'Elevation', 'Downward rotation'],
        'correctIndex': 0,
        'explanation': 'Protraction moves the scapula forward.',
      },
      {
        'text': 'Which movement refers to bringing a limb horizontally toward the midline?',
        'type': 'multiple_choice',
        'options': ['Horizontal Abduction', 'Horizontal Extension', 'Horizontal Adduction', 'Circumduction'],
        'correctIndex': 2,
        'explanation': 'Horizontal adduction moves toward the midline.',
      },
      {
        'text': 'Elevation and Depression are movements that are easily observed in the scapula itself.',
        'type': 'true_false',
        'answer': false,
        'explanation': 'They are better inferred via shoulder movement.',
      },
      {
        'text': 'Horizontal Adduction and Abduction are the same as Pronation and Supination.',
        'type': 'true_false',
        'answer': false,
        'explanation': 'They describe different motions and joints.',
      },
      {
        'text': 'Which movement occurs when the scapula moves downward from an elevated position?',
        'type': 'multiple_choice',
        'options': ['Upward rotation', 'Depression', 'Flexion', 'Protraction'],
        'correctIndex': 1,
        'explanation': 'Depression lowers the scapula.',
      },
      {
        'text': 'Supination results in the palm facing:',
        'type': 'multiple_choice',
        'options': ['Downward', 'Toward the body', 'Upward', 'Posteriorly'],
        'correctIndex': 2,
        'explanation': 'Supination faces the palm upward.',
      },
    ];
    _questions.shuffle();
    _answers = List.filled(_questions.length, null);
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
      final scoreDocId = '${_uid}_specialized_movements_day3';
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
            _maxScore = _questions.length;
          });
        }
      } else {
        setState(() {
          _alreadyPassed = false;
          _submitted = false;
          _passed = false;
          _score = 0;
          _maxScore = _questions.length;
        });
      }
      final attemptsQuery = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('studentId', isEqualTo: _uid)
          .where('quizId', isEqualTo: 'specialized_movements_day3')
          .get(const GetOptions(source: Source.server));
      _attemptNumber = attemptsQuery.docs.length;
    } catch (_) {}
  }

  void _retake() {
    _questions.shuffle();
    _answers = List.filled(_questions.length, null);
    setState(() {
      _submitted = false;
      _score = 0;
      _passed = false;
    });
  }

  Future<void> _resetQuizState() async {
    if (_uid == null || _uid!.isEmpty) return;
    final scoreDocId = '${_uid}_specialized_movements_day3';
    try {
      await FirebaseFirestore.instance.collection('studentScores').doc(scoreDocId).delete();
    } catch (_) {
      try {
        await FirebaseFirestore.instance.collection('studentScores').doc(scoreDocId).set({
          'hasAnswered': false,
          'passed': false,
          'score': 0,
          'maxScore': _questions.length,
          'percentage': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    try {
      final attemptsQuery = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('studentId', isEqualTo: _uid)
          .where('quizId', isEqualTo: 'specialized_movements_day3')
          .get();
      for (final d in attemptsQuery.docs) {
        await d.reference.delete();
      }
    } catch (_) {}
    _questions.shuffle();
    _answers = List.filled(_questions.length, null);
    setState(() {
      _alreadyPassed = false;
      _submitted = false;
      _passed = false;
      _score = 0;
      _maxScore = _questions.length;
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
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(q['text'] as String, style: AppTextStyles.textTheme.titleMedium),
              ),
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
          ],
        ],
      ),
    );
  }

  void _submit() async {
    if (_submitted) return;
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final type = q['type'] as String;
      final ans = _answers[i];
      bool isCorrect = false;
      if (type == 'multiple_choice') {
        isCorrect = (ans is int) && ans == (q['correctIndex'] as int);
      } else if (type == 'true_false') {
        isCorrect = (ans is bool) && ans == (q['answer'] as bool);
      }
      if (isCorrect) correct++;
    }
    setState(() {
      _submitted = true;
      _score = correct;
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
      }
    }
    try {
      final qs = QuizService();
      final attemptNo = _attemptNumber + 1;
      await qs.logQuizAttempt(
        studentId: _uid ?? FirebaseAuthService().currentUser?.uid ?? '',
        quizId: 'specialized_movements_day3',
        quizTitle: 'Day 3 Mini Quiz',
        score: _score.toDouble(),
        maxScore: _maxScore.toDouble(),
        percentage: percentage,
        passed: _passed,
        attemptNumber: attemptNo,
      );
      if (_passed) {
        await qs.submitStudentQuizAttempt(
          studentId: _uid ?? FirebaseAuthService().currentUser?.uid ?? '',
          quizId: 'specialized_movements_day3',
          quizTitle: 'Day 3 Mini Quiz',
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
          final docId = '${sid}_specialized_movements_day3';
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
            color: Colors.black.withOpacity(0.05),
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
                    'Day 3 Mini Quiz',
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
                  children: [
                    _ChipLabel('Multiple Choice'),
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
                  if (!_passed && !_alreadyPassed)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retake,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text('Retake'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/anatomical-planes');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Continue', style: TextStyle(color: Colors.white)),
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