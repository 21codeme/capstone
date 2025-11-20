import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/quiz_service.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class MusculoskeletalFinalQuizScreen extends StatefulWidget {
  const MusculoskeletalFinalQuizScreen({super.key});

  @override
  State<MusculoskeletalFinalQuizScreen> createState() => _MusculoskeletalFinalQuizScreenState();
}

class _MusculoskeletalFinalQuizScreenState extends State<MusculoskeletalFinalQuizScreen> {
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
  final String _quizId = 'final_quiz_musculoskeletal_basis';
  List<TextEditingController?> _idControllers = [];
  List<FocusNode?> _idFocusNodes = [];
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _initQuestions();
    _loadUserData();
  }

  void _initQuestions() {
    _questions = [
      {'type': 'multiple_choice', 'points': 1, 'text': 'The most observable function of bones is to:', 'options': ['Produce blood cells', 'Store fat and minerals', 'Protect internal organs', 'Give shape to the body'], 'correctIndex': 3},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which joint type is best exemplified by the cervical vertebrae 1 and 2?', 'options': ['Hinge', 'Ball-and-socket', 'Pivot', 'Saddle'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The primary mechanism for muscles to create movement is:', 'options': ['Lengthening the tendon', 'Shortening the muscle via concentric contraction', 'Isometric force neutralization', 'Eccentric lengthening'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which characteristic is typical of slow-twitch (Type I) muscle fibers?', 'options': ['Produce greater force', 'Fatigue faster', 'Resistant to fatigue', 'High lactic acid production'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The ACTN3 gene is primarily associated with:', 'options': ['Endurance abilities', 'Sprint abilities', 'Core stability', 'Injury prevention'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'The Biceps Brachii is an example of which muscle architecture?', 'options': ['Unipennate', 'Bipennate', 'Circular', 'Parallel (Fusiform)'], 'correctIndex': 3},
      {'type': 'multiple_choice', 'points': 1, 'text': 'What is the primary function of isometric contraction in core muscles?', 'options': ['To shorten the muscle for movement', 'To lengthen the muscle against gravity', 'To hold movements and achieve movement isolation', 'To produce myokines for immunity'], 'correctIndex': 2},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Which type of muscle contraction is dominant when a person is going down into a squat?', 'options': ['Concentric', 'Eccentric', 'Isometric', 'Sphincter'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Adding both arms for support during landing is an example of which landing variation?', 'options': ['Landing with both feet', 'Landing with four-point support', 'Landing with three-point support', 'Landing with one leg'], 'correctIndex': 1},
      {'type': 'multiple_choice', 'points': 1, 'text': 'Excessive side rotation in the trunk and hips during landing is a factor contributing to:', 'options': ['Patellofemoral Pain (PFP)', 'Exertional Medial Tibial Pain (EMTP)', 'Knee Overuse Injuries', 'Groin Injuries'], 'correctIndex': 1},

      {'type': 'identification', 'points': 1, 'text': 'The overall goal of physical activity that is seen as a prerequisite for acquiring basic motor skills.', 'answer': 'movement competency', 'altAnswers': ['competency in movement', 'movement literacy']},
      {'type': 'identification', 'points': 1, 'text': 'The process in the body where bones are significant producers of blood cells.', 'answer': 'hematopoiesis', 'altAnswers': ['blood cell production']},
      {'type': 'identification', 'points': 1, 'text': 'The type of joint that allows for the greatest degrees of freedom, such as the hip.', 'answer': 'ball-and-socket joint', 'altAnswers': ['ball and socket', 'ball and socket joint']},
      {'type': 'identification', 'points': 1, 'text': 'The protein messengers released by muscles that contribute to an individual\'s immunity.', 'answer': 'myokines', 'altAnswers': []},
      {'type': 'identification', 'points': 1, 'text': 'The muscle fiber type that is divided into fast oxidative (IIa) and fast glycolytic (IIb).', 'answer': 'fast-twitch (type ii)', 'altAnswers': ['fast twitch type ii', 'type ii fibers', 'fast-twitch']},
      {'type': 'identification', 'points': 1, 'text': 'The muscle architecture that is not involved with skeletal movements and works for constriction.', 'answer': 'circular (sphincter)', 'altAnswers': ['circular', 'sphincter']},
      {'type': 'identification', 'points': 1, 'text': 'The term for the angle of attachment of muscle fibers that affects force production.', 'answer': 'pennation', 'altAnswers': []},
      {'type': 'identification', 'points': 1, 'text': 'The term for a muscle contraction without motion.', 'answer': 'isometric contraction', 'altAnswers': ['isometric']},
      {'type': 'identification', 'points': 1, 'text': 'The biomechanical factor in landing where greater hip and knee flexion angles are considered functionally safer.', 'answer': 'landing with both feet', 'altAnswers': ['both feet landing', 'two-foot landing']},
      {'type': 'identification', 'points': 1, 'text': 'The injury commonly called \"runner\'s knee.\"', 'answer': 'patellofemoral pain (pfp)', 'altAnswers': ['pfp', 'patellofemoral pain', 'runner\'s knee']},

      {'type': 'true_false', 'points': 1, 'text': 'The hip joint\'s range of motion is limited by the greater trochanter.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'The R577X gene is found to be more common among elite sprinters.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'Unipennate muscles have fibers arranged parallel to the direction of resistance.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'The core is considered the base of all movement.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Isometric contractions are harder to observe compared to their concentric equivalents.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Landing with one leg is considered functionally safer than landing with both feet.', 'answer': false},
      {'type': 'true_false', 'points': 1, 'text': 'Eccentric contraction is the muscle-activated action of controlling the center of gravity.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Knee overuse injuries are observed when the hips are bent inward (adduction) during ground contact.', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Shin splints are technically known as Exertional Medial Tibial Pain (EMTP).', 'answer': true},
      {'type': 'true_false', 'points': 1, 'text': 'Core stability is an integral part of movement literacy, especially for injury prevention.', 'answer': true},
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
              Expanded(
                child: Text(q['text'] as String, style: AppTextStyles.textTheme.titleMedium),
              ),
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
        quizTitle: 'Comprehensive Final Quiz: Musculoskeletal Basis',
        score: _score.toDouble(),
        maxScore: _maxScore.toDouble(),
        percentage: percentage,
        passed: _passed,
        attemptNumber: attemptNo,
      );
      await qs.submitStudentQuizAttempt(
        studentId: studentId,
        quizId: _quizId,
        quizTitle: 'Comprehensive Final Quiz: Musculoskeletal Basis',
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
          title: const Text('Comprehensive Final Quiz: Musculoskeletal Basis'),
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
                          'This comprehensive final quiz covers all five days in Musculoskeletal Basis. Ensure you have passed all mini quizzes before taking this assessment.',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(Icons.repeat, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Attempts left: ${(_maxAttempts - _attemptNumber) < 0 ? 0 : (_maxAttempts - _attemptNumber)}',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
                        onPressed: (_submitted || (!_passed && _attemptNumber >= _maxAttempts)) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Submit', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                if (_submitted)
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
                        Text('Score: $_score / $_maxScore', style: AppTextStyles.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(_passed ? 'Status: Passed' : 'Status: Failed', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: _passed ? AppColors.successGreen : AppColors.errorRed)),
                        const SizedBox(height: 8),
                        if (!_passed && _attemptNumber < _maxAttempts)
                          ElevatedButton(
                            onPressed: _retake,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                            child: const Text('Retake', style: TextStyle(color: Colors.white)),
                          ),
                        if (!_passed && _attemptNumber >= _maxAttempts)
                          Text('Attempt limit reached. Please review topics and contact your instructor.', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}