import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class ContinuousSkillsFinalQuizScreen extends StatefulWidget {
  const ContinuousSkillsFinalQuizScreen({super.key});

  @override
  State<ContinuousSkillsFinalQuizScreen> createState() => _ContinuousSkillsFinalQuizScreenState();
}

class _ContinuousSkillsFinalQuizScreenState extends State<ContinuousSkillsFinalQuizScreen> {
  late List<Map<String, dynamic>> _questions;
  List<dynamic> _answers = [];
  bool _submitted = false;
  bool _alreadyPassed = false;
  bool _passed = false;
  int _score = 0;
  int _maxScore = 0;
  String? _uid;
  String? _studentName;
  String? _course;
  String? _year;
  String? _section;
  int _attemptNumber = 0;
  final String _quizId = 'continuous_skills_final_quiz';
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
      {'type': 'multiple_choice', 'points': 1, 'text': 'A continuous skill is best described as:', 'options': ['A single discrete action', 'A sequence of discrete parts', 'Ongoing cyclic movement without clear begin/end', 'Random movements with pauses'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which is a continuous skill?', 'options': ['Free throw', 'Triple jump', 'Running at steady pace', 'Throwing a dart'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Cadence in running refers to:', 'options': ['Stride length', 'Steps per minute', 'Breathing rate', 'Arm swing speed'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Stroke rate measures:', 'options': ['Breaths per lap', 'Strokes per minute', 'Length of each pool', 'Turns per set'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'An efficient technique mainly:', 'options': ['Increases energy cost per cycle', 'Reduces energy cost per cycle', 'Removes need for pacing', 'Eliminates feedback'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'A negative split means:', 'options': ['First half faster than second', 'Second half faster than first', 'Random pacing', 'Equal distance each minute'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which metrics best support effort management?', 'options': ['Score only', 'Heart rate, pace, RPE', 'Jump height', 'Throw accuracy'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Rhythm in continuous skills is:', 'options': ['Irregular timing', 'Stable temporal pattern across cycles', 'One‑time timing cue', 'No timing at all'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Coordination emphasizes:', 'options': ['Random sequencing', 'Timing and order within each cycle', 'Maximal fatigue only', 'Outcome without mechanics'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Knowledge of performance provides feedback about:', 'options': ['Outcome achieved', 'Movement quality and mechanics', 'Number of attempts', 'Amount of rest'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Knowledge of results focuses on:', 'options': ['How the movement felt', 'Biomechanical efficiency', 'Whether the target outcome was met', 'Internal sensations only'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Steady‑state is best described as:', 'options': ['Constant effort with stabilized respiration and output', 'Maximal sprint effort', 'Random fluctuation of pace', 'Complete rest'], 'correctIndex': 0},

      {'type': 'identification', 'points': 1, 'text': 'Ongoing cyclic movement without clear beginning or end.', 'answer': 'Continuous skill', 'altAnswers': ['continuous skill','continuous skills']},
      {'type': 'identification', 'points': 1, 'text': 'Steps per minute while running.', 'answer': 'Cadence', 'altAnswers': ['cadence']},
      {'type': 'identification', 'points': 1, 'text': 'Second half faster than the first.', 'answer': 'Negative split', 'altAnswers': ['negative split','negativesplit','negative‑split']},
      {'type': 'identification', 'points': 1, 'text': 'Strokes per minute in swimming.', 'answer': 'Stroke rate', 'altAnswers': ['stroke rate','strokerate','strokes per minute','sr']},
      {'type': 'identification', 'points': 1, 'text': 'A practical measure for matching effort to duration.', 'answer': 'Pace', 'altAnswers': ['pace']},
      {'type': 'identification', 'points': 1, 'text': 'Subjective measure of perceived effort.', 'answer': 'RPE', 'altAnswers': ['rpe','rating of perceived exertion']},

      {'type': 'true_false', 'points': 1, 'text': 'Continuous skills typically rely on rhythm and pacing.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Swimming is a discrete skill.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'Efficient technique reduces energy cost per cycle.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Random pacing improves endurance performance.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'Stable cadence reduces variability and improves control.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Knowledge of results focuses on movement feel.', 'answer': false},
    ];
    _answers = List.filled(_questions.length, null);
    _maxScore = _questions.map((q) => (q['points'] as int)).fold(0, (a, b) => a + b);
    _idControllers = List<TextEditingController?>.filled(_questions.length, null);
    _idFocusNodes = List<FocusNode?>.filled(_questions.length, null);
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
      final scoreDocId = '${_uid}_$_quizId';
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
      _idControllers = List<TextEditingController?>.filled(_questions.length, null);
      _idFocusNodes = List<FocusNode?>.filled(_questions.length, null);
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
              Expanded(child: Text(q['text'] as String, style: AppTextStyles.textTheme.titleMedium)),
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
    final missing = <int>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final type = q['type'] as String;
      final ans = _answers[i];
      bool answered = false;
      if (type == 'multiple_choice') {
        answered = ans is int;
      } else if (type == 'true_false') {
        answered = ans is bool;
      } else if (type == 'identification') {
        answered = ans is String && ans.trim().isNotEmpty;
      }
      if (!answered) missing.add(i + 1);
    }
    if (missing.isNotEmpty) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Incomplete'),
          content: Text('Please answer all questions. Unanswered: ${missing.join(', ')}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: const Text('Do you want to submit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldSubmit != true) return;
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
      final studentId = _uid ?? FirebaseAuthService().currentUser?.uid ?? '';
      final attemptNo = _attemptNumber + 1;
      await qs.logQuizAttempt(
        studentId: studentId,
        quizId: _quizId,
        quizTitle: 'Comprehensive Final Quiz: Continuous Skills',
        score: _score.toDouble(),
        maxScore: _maxScore.toDouble(),
        percentage: percentage,
        passed: _passed,
        attemptNumber: attemptNo,
      );
      await qs.submitStudentQuizAttempt(
        studentId: studentId,
        quizId: _quizId,
        quizTitle: 'Comprehensive Final Quiz: Continuous Skills',
        score: _score.toDouble(),
        maxScore: _maxScore.toDouble(),
        percentage: percentage,
        passed: _passed,
        answers: answers,
        timeTakenMinutes: 0,
        studentName: _studentName,
        course: _course,
        year: _year,
        section: _section,
      );
      setState(() {
        _attemptNumber = attemptNo;
        if (_passed) _alreadyPassed = true;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return _submitted;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.primaryBlue,
          title: const Text('Comprehensive Final Quiz: Continuous Skills'),
          automaticallyImplyLeading: false,
          leading: _submitted
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
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
                        child: Icon(Icons.emoji_events, color: AppColors.primaryBlue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Comprehensive Final Quiz: Continuous Skills',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                    if (_submitted) ...[
                      ElevatedButton(
                        onPressed: _alreadyPassed ? null : _retake,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: const Text('Retake', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}