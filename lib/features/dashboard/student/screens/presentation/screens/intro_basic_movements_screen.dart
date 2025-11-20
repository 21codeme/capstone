import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class IntroBasicMovementsScreen extends StatelessWidget {
  const IntroBasicMovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        title: const Text('Introduction and Basic Movements'),
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
                    child: Icon(Icons.directions_run, color: AppColors.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Movement is fundamentally the only way the human brain can connect to and interact with the world. It enables functional actions for survival, signals messages, and connects us socially. Movement carries meaning shaped by a person\'s history and ethnicity.',
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
                'Bending and Straightening Movements',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _InfoCard(
                title: 'Why These Movements Matter',
                icon: Icons.unfold_more,
                lines: const [
                  'Most common movements: bending and straightening',
                  'Foundation for daily activities and sports skills',
                  'Changes in joint angle drive muscle length changes',
                  'Combine with rotation and abduction/adduction for complex motion',
                ],
              ),

            const SizedBox(height: 24),

            Text(
              'Primary Movement Categories',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _MovementCard(
              icon: Icons.unfold_more,
              title: 'Bending and Straightening',
              description: 'Movements that involve increasing or decreasing the angle between two body parts.',
            ),
            const SizedBox(height: 12),
            _MovementCard(
              icon: Icons.swap_horiz,
              title: 'Moving Away from the Center',
              description: 'Movements that involve swinging body parts toward or away from the center line of the body.',
            ),
            const SizedBox(height: 12),
            _MovementCard(
              icon: Icons.sync,
              title: 'Rotation',
              description: 'Movements that involve body parts rotating in place.',
            ),

            const SizedBox(height: 24),

            _Flashcard(
              title: 'Flexion',
              description: 'A bending movement where a muscle or group of muscles pulls a segment towards another. This decreases the angle of the joint.',
              example: 'Bending the elbow to bring the hand to the shoulder.',
            ),
            const SizedBox(height: 12),
            _Flashcard(
              title: 'Extension',
              description: 'The straightening movement where an opposite muscle pulls the segment back to a straightened or neutral position. This increases the angle of the joint.',
              example: 'Straightening the elbow from a bent position.',
            ),
            const SizedBox(height: 12),
            _Flashcard(
              title: 'Hyperextension',
              description: 'A movement where the extension passes over the neutral or straight line formation of the part, moving beyond the normal range of motion.',
              example: 'Bending the head backward past the neutral position.',
            ),

            const SizedBox(height: 24),

              Text(
                'Rotation',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _InfoCard(
                title: 'Rotation Basics',
                icon: Icons.rotate_right,
                lines: const [
                  'Joint pivots in place around an axis',
                  'Often subtle to observe compared to bending',
                  'Crucial for speed and throwing sports',
                  'Common in dance spinning and turning skills',
                ],
              ),

            const SizedBox(height: 24),

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

class _Flashcard extends StatefulWidget {
  final String title;
  final String description;
  final String example;

  const _Flashcard({
    required this.title,
    required this.description,
    required this.example,
  });

  @override
  State<_Flashcard> createState() => _FlashcardState();
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

class _FlashcardState extends State<_Flashcard> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isRevealed = !_isRevealed;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isRevealed ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _isRevealed ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ],
            ),
            if (_isRevealed) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Example:',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.example,
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _MovementCard({
    required this.icon,
    required this.title,
    required this.description,
  });

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
            color: Colors.black.withOpacity(0.05),
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
                  AppColors.primaryBlue.withOpacity(0.16),
                  AppColors.primaryBlue.withOpacity(0.08),
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
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryBlue,
            ),
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
  bool _submitted = false;
  int _score = 0;
  int _maxScore = 0;
  bool _passed = false;
  final String _quizId = 'intro_basic_movements_day1';
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
    _loadExistingStatus();
  }

  void _initQuestions() {
    _questions = [
      {
        'type': 'multiple_choice',
        'text': 'Which movement is described as a muscle or group of muscles pulling a segment towards another, resulting in a bending movement?',
        'options': ['Extension', 'Rotation', 'Flexion', 'Hyperextension'],
        'correctIndex': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'The movement where the extension passes over the neutral or straight line formation of the part is called:',
        'options': ['Flexion', 'Hyperextension', 'Abduction', 'Adduction'],
        'correctIndex': 1,
      },
      {
        'type': 'multiple_choice',
        'text': 'The movement that involves an opposite muscle pulling a segment back to a straightened or neutral position is called:',
        'options': ['Flexion', 'Rotation', 'Extension', 'Circumduction'],
        'correctIndex': 2,
      },
      {
        'type': 'multiple_choice',
        'text': 'A movement where a joint can pivot, often used for speed and in sports featuring throwing skills, is called:',
        'options': ['Extension', 'Rotation', 'Flexion', 'Elevation'],
        'correctIndex': 1,
      },
      {
        'type': 'true_false',
        'text': 'According to the text, movement is the only way a human brain can connect to the world.',
        'answer': true,
      },
      {
        'type': 'true_false',
        'text': 'Rotation movements are usually hard to recognize but are highly used for speed and sports that feature throwing skills.',
        'answer': true,
      },
    ];
    _questions.shuffle();
    _answers = List.filled(_questions.length, null);
    _submitted = false;
    _score = 0;
    _maxScore = _questions.length;
    _passed = false;
  }

  Future<void> _loadExistingStatus() async {
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
      final scoreDocId = '${_uid}_$_quizId';
      print('Checking score document ID: $scoreDocId'); // Debug print
      final scoreDoc = await FirebaseFirestore.instance.collection('studentScores').doc(scoreDocId).get(const GetOptions(source: Source.server));
      print('Score document exists: ${scoreDoc.exists}'); // Debug print
      if (scoreDoc.exists) {
        final sdata = scoreDoc.data() as Map<String, dynamic>;
        print('Score data: $sdata'); // Debug print
        final hasAnswered = (sdata['hasAnswered'] as bool?) ?? false;
        final passed = (sdata['passed'] as bool?) ?? false;
        print('hasAnswered: $hasAnswered, passed: $passed'); // Debug print
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
          .where('quizId', isEqualTo: _quizId)
          .get(const GetOptions(source: Source.server));
      _attemptNumber = attemptsQuery.docs.length;
    } catch (e) {
      print('Error loading existing status: $e'); // Debug print
    }
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
        quizId: _quizId,
        quizTitle: 'Day 1 Mini Quiz',
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
          quizTitle: 'Day 1 Mini Quiz',
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
          final docId = '${sid}_$_quizId';
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
    final scoreDocId = '${_uid}_$_quizId';
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
          .where('quizId', isEqualTo: _quizId)
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

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  'Day 1 Mini Quiz',
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
                            Navigator.pushReplacementNamed(context, '/movement-relative-center');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Proceed to Next Topic', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
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