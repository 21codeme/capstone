import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class AnatomicalPlanesScreen extends StatelessWidget {
  const AnatomicalPlanesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text('Perspectives in Movement (Anatomical Planes)'),
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
                      child: Icon(Icons.view_in_ar, color: AppColors.primaryBlue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'To describe movement accurately, we use anatomical planes as two-dimensional views of the body within 3D space. Recognizing the correct plane helps interpret motion consistently.',
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
                'Perspectives in Movement (Anatomical Planes)',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Terminology is applied within a three-dimensional setting using anatomical planes and axes. These planes are two-dimensional slices or "views" extracted from the 3D space to understand movements better.',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 24),

              _InfoCard(
                title: 'Planes Simplified',
                icon: Icons.splitscreen,
                lines: const [
                  'Frontal: side-to-side movements (front/back view)',
                  'Sagittal: forward/backward movements (side view)',
                  'Transverse: twisting/turning movements (top/bottom view)',
                  'Always declare the observed view to describe motion clearly',
                ],
              ),
              const SizedBox(height: 16),

              _PlaneCard(
                title: 'Frontal Plane',
                altName: 'Coronal Plane',
                meaning: 'Divides the body into front and back sections.',
                view: 'Front View',
                icon: Icons.view_day,
              ),
              const SizedBox(height: 12),
              _PlaneCard(
                title: 'Sagittal Plane',
                meaning: 'Divides the body into left and right sections.',
                view: 'Side View',
                icon: Icons.view_sidebar,
              ),
              const SizedBox(height: 12),
              _PlaneCard(
                title: 'Transverse Plane',
                meaning: 'Divides the body into upper and lower sections.',
                view: 'Top View',
                icon: Icons.view_quilt,
              ),

              const SizedBox(height: 16),

              Text(
                'Observation and Degrees of Freedom',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _InfoCard(
                title: 'Observation Tips',
                icon: Icons.visibility,
                lines: const [
                  'Declare the plane where a movement is observed',
                  'Different viewers can interpret imagery differently',
                  'Degrees of freedom relate to movement complexity',
                  'A movement not seen in one plane may be visible in another',
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

class _PlaneCard extends StatelessWidget {
  final String title;
  final String? altName;
  final String meaning;
  final String view;
  final IconData icon;

  const _PlaneCard({
    required this.title,
    this.altName,
    required this.meaning,
    required this.view,
    required this.icon,
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
              if (altName != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Also: $altName',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text('Meaning: $meaning', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue)),
          const SizedBox(height: 6),
          Text('View Provided: $view', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue)),
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
  List<TextEditingController?> _idControllers = [];
  List<FocusNode?> _idFocusNodes = [];

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
        'points': 1,
        'text': 'Which anatomical plane separates the left and right sides and provides a side view?',
        'options': ['Frontal Plane', 'Transverse Plane', 'Sagittal Plane', 'Coronal Plane'],
        'correctIndex': 2,
      },
      {
        'type': 'multiple_choice',
        'points': 1,
        'text': 'The Transverse Plane captures visual information from which perspective?',
        'options': ['Front view', 'Side view', 'Top view', 'Bottom view'],
        'correctIndex': 2,
      },
      {
        'type': 'identification',
        'points': 3,
        'text': '[TERM] The anatomical plane also known as the coronal plane, providing a front view.',
        'answer': 'frontal plane',
        'altAnswers': ['coronal plane', 'frontal'],
      },
      {
        'type': 'identification',
        'points': 3,
        'text': '[TERM] Concept that movements are seen differently in perspectives; complexity can be seen in other planes.',
        'answer': 'degrees of freedom',
        'altAnswers': ['df', 'degree of freedom', 'degrees of freedoms'],
      },
      {
        'type': 'true_false',
        'points': 1,
        'text': 'Anatomical planes are 3-dimensional slices or "views" extracted from a 2-dimensional space.',
        'answer': false,
      },
      {
        'type': 'true_false',
        'points': 1,
        'text': 'The three main anatomical planes are Frontal, Sagittal, and Coronal.',
        'answer': false,
      },
    ];
    _answers = List.filled(_questions.length, null);
    _maxScore = _questions.map((q) => (q['points'] as int)).fold(0, (a, b) => a + b);
    _idControllers = List<TextEditingController?>.filled(_questions.length, null);
    _idFocusNodes = List<FocusNode?>.filled(_questions.length, null);
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
      final scoreDocId = '${_uid}_anatomical_planes_day4';
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
            final ms = sdata['maxScore'];
            _maxScore = ms is int ? ms : _maxScore;
          });
        } else {
          setState(() {
            _alreadyPassed = false;
            _submitted = false;
            _passed = false;
            _score = 0;
          });
        }
      } else {
        setState(() {
          _alreadyPassed = false;
          _submitted = false;
          _passed = false;
          _score = 0;
        });
      }
      final attemptsQuery = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('studentId', isEqualTo: _uid)
          .where('quizId', isEqualTo: 'anatomical_planes_day4')
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
    final scoreDocId = '${_uid}_anatomical_planes_day4';
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
          .where('quizId', isEqualTo: 'anatomical_planes_day4')
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
              if (type == 'identification')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Points: ${q['points']}', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.primaryBlue)),
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
          ] else if (type == 'identification') ...[
            Builder(
              builder: (context) {
                _idControllers[index] ??= TextEditingController(text: _answers[index] as String? ?? '');
                _idFocusNodes[index] ??= FocusNode();
                final controller = _idControllers[index]!;
                final focusNode = _idFocusNodes[index]!;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !_submitted,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type your answer...',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => FocusScope.of(context).requestFocus(focusNode),
                  onChanged: (v) => _answers[index] = v,
                );
              },
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
        answers.add({'index': i, 'selectedIndex': _answers[i], 'points': q['points']});
      } else if (type == 'true_false') {
        answers.add({'index': i, 'selectedBool': _answers[i], 'points': q['points']});
      } else if (type == 'identification') {
        answers.add({'index': i, 'typed': _answers[i], 'points': q['points']});
      }
    }
    try {
      final qs = QuizService();
      final attemptNo = _attemptNumber + 1;
      await qs.logQuizAttempt(
        studentId: _uid ?? FirebaseAuthService().currentUser?.uid ?? '',
        quizId: 'anatomical_planes_day4',
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
          quizId: 'anatomical_planes_day4',
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
          final docId = '${sid}_anatomical_planes_day4';
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
                  children: [
                    _ChipLabel('Multiple Choice'),
                    _ChipLabel('Identification (3 pts)'),
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
                              Navigator.pushReplacementNamed(context, '/movement-review');
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