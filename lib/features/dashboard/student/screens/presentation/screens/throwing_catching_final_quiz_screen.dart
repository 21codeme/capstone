import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class ThrowingCatchingFinalQuizScreen extends StatefulWidget {
  const ThrowingCatchingFinalQuizScreen({super.key});

  @override
  State<ThrowingCatchingFinalQuizScreen> createState() => _ThrowingCatchingFinalQuizScreenState();
}

class _ThrowingCatchingFinalQuizScreenState extends State<ThrowingCatchingFinalQuizScreen> {
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
  final String _quizId = 'throw_catch_final_quiz';
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
      {'type': 'multiple_choice', 'points': 1, 'text': 'Throwing is classified as a motor skill that has a clear beginning and end. It is therefore a:', 'options': ['Continuous skill', 'Serial skill', 'Discrete skill', 'Open skill'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The phase where force is applied in the direction of the throw is the:', 'options': ['Preparatory phase', 'Execution phase', 'Follow-through phase', 'Release phase'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The phase responsible for safely decelerating the momentum of the body is the:', 'options': ['Preparatory phase', 'Execution phase', 'Follow-through phase', 'Acceleration phase'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'In Stage 1 of throwing development, the performer’s feet:', 'options': ['Take a contralateral step', 'Are primarily stationary', 'Take a large forward stride', 'Switch weight rapidly'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'A key movement seen in Stage 1 is:', 'options': ['Trunk rotation', 'Ipsilateral step', 'Hip flexion with elbow extension', 'Extensive countermovement'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Stage 2 introduces a more efficient motion, shown by a shift from:', 'options': ['Transverse to sagittal plane', 'Sagittal/vertical to transverse/horizontal plane', 'Horizontal to rotational plane', 'Frontal to sagittal plane'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Stage 3 is characterized by:', 'options': ['Contralateral movements', 'No foot movement', 'Ipsilateral arm–leg action', 'Fully integrated trunk rotation'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Stage 4 first shows:', 'options': ['Ipsilateral stepping', 'Contralateral arm–leg movements', 'No rotation in the follow-through', 'Sagittal-only arm movement'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Stage 5 includes which mature feature?', 'options': ['No trunk rotation', 'Minimal countermovement', 'Extensive countermovement', 'Only elbow extension'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The factor that forms the performer\'s brain on the correct motor output is:', 'options': ['Instruction', 'Knowledge', 'Critical Cues', 'Implement Size and Shape'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Sensory inputs that help a performer repeat successful movements are known as:', 'options': ['Instruction', 'Gender Differences', 'Critical Cues', 'Implement Weight Factor'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'A mature thrower typically releases the object at approximately:', 'options': ['5°', '15°', '30°', '45°'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'A performer needing to use two hands to grip a large object is mainly affected by:', 'options': ['Knowledge', 'Angle of Release', 'Implement Size, Shape, and Weight', 'Gender Differences'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The developmental stage where the ball is placed high but trunk rotation is minimal during the throw is:', 'options': ['Stage 1', 'Stage 2', 'Stage 3', 'Stage 4'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'A more integrated trunk flexion and rotation in the follow-through, but still limited during the throw itself, is seen in:', 'options': ['Stage 1', 'Stage 3', 'Stage 4', 'Stage 5'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Fully integrated trunk rotation and ipsilateral post-release movement are hallmarks of:', 'options': ['Stage 2', 'Stage 3', 'Stage 4', 'Stage 5'], 'correctIndex': 3},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which factor is considered the most complex to change across ages?', 'options': ['Critical Cues', 'Knowledge', 'Gender Differences', 'Instruction'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The three phases of throwing that summarize the entire motion are:', 'options': ['Stance, Release, Recovery', 'Wind-up, Contact, Stop', 'Preparatory, Execution, Follow-through', 'Begin, Middle, End'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which stage begins showing rotation only after the ball is released, not during the throw?', 'options': ['Stage 1', 'Stage 2', 'Stage 3', 'Stage 5'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which is NOT one of the six factors influencing throwing performance?', 'options': ['Instruction', 'Knowledge', 'Age of Performer', 'Angle of Release'], 'correctIndex': 2},

      {'type': 'identification', 'points': 1, 'text': 'The phase where the body moves opposite the target to build force.', 'answer': 'Preparatory phase', 'altAnswers': ['preparatory phase', 'preparatory']},
      {'type': 'identification', 'points': 1, 'text': 'The stage where feet remain stationary and no trunk rotation occurs.', 'answer': 'Stage 1', 'altAnswers': ['stage 1', 'stage one', 'first stage']},
      {'type': 'identification', 'points': 1, 'text': 'The researcher who established the developmental stages of throwing.', 'answer': 'Dr. Monica Wild', 'altAnswers': ['monica wild', 'dr monica wild', 'monica j wild']},
      {'type': 'identification', 'points': 1, 'text': 'The stage where ipsilateral arm–leg action is first observed.', 'answer': 'Stage 3', 'altAnswers': ['stage 3', 'stage three', 'intermediate performer']},
      {'type': 'identification', 'points': 1, 'text': 'The stage showing observable contralateral arm–leg movements.', 'answer': 'Stage 4', 'altAnswers': ['stage 4', 'stage four', 'pre‑mature stage', 'premature stage']},
      {'type': 'identification', 'points': 1, 'text': 'The stage characterized by an extensive countermovement.', 'answer': 'Stage 5', 'altAnswers': ['stage 5', 'stage five', 'mature throwing skill']},
      {'type': 'identification', 'points': 1, 'text': 'The factor affected when the object is too large or heavy, requiring a technique change.', 'answer': 'Implement Size, Shape, and Weight', 'altAnswers': ['implement size, shape, and weight', 'implement size shape and weight', 'size shape and weight', 'implement']},
      {'type': 'identification', 'points': 1, 'text': 'The factor determined by how high and how far the implement travels after release.', 'answer': 'Angle of Release', 'altAnswers': ['angle of release', 'release angle', 'angle']},
      {'type': 'identification', 'points': 1, 'text': 'Sensory inputs that help reinforce successful movement patterns.', 'answer': 'Critical Cues', 'altAnswers': ['critical cues', 'cues']},
      {'type': 'identification', 'points': 1, 'text': 'The category of throwing skill defined by object manipulation and explosive movement.', 'answer': 'Discrete skill', 'altAnswers': ['discrete motor skill', 'discrete skill']},

      {'type': 'true_false', 'points': 1, 'text': 'The follow-through phase is important because it controls the projectile and prevents injury.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'In the execution phase, the thrower acquires momentum by moving away from the target.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'Stage 2 shows the beginning of transverse or horizontal arm motion.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Stage 3 still demonstrates little to no trunk rotation during the throw.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Stage 4 performers stride with the ipsilateral leg as a key characteristic.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'Stage 5 includes stable integration of trunk flexion and rotation.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Knowledge forms the performer’s correct motor output for the throw.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Gender Differences is the easiest factor to adjust in training.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'A 15° release angle is commonly observed in mature throwers.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Throwing is considered a discrete skill because it has a clear beginning and end.', 'answer': true},
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
        quizTitle: 'Comprehensive Final Quiz: Throwing & Catching',
        score: _score.toDouble(),
        maxScore: _maxScore.toDouble(),
        percentage: percentage,
        passed: _passed,
        attemptNumber: attemptNo,
      );
      await qs.submitStudentQuizAttempt(
        studentId: studentId,
        quizId: _quizId,
        quizTitle: 'Comprehensive Final Quiz: Throwing & Catching',
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
          title: const Text('Comprehensive Final Quiz: Throwing & Catching'),
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
                          'Comprehensive Final Quiz: Throwing & Catching',
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