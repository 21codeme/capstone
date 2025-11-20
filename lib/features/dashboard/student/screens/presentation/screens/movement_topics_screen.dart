import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
class MovementTopicsScreen extends StatefulWidget {
  const MovementTopicsScreen({super.key});

  @override
  State<MovementTopicsScreen> createState() => _MovementTopicsScreenState();
}

class _MovementTopicsScreenState extends State<MovementTopicsScreen> {
  bool _day1Passed = false;
  bool _day2Passed = false;
  bool _day3Passed = false;
  bool _day4Passed = false;
  bool _loading = true;
  String? _uid;
  StreamSubscription<QuerySnapshot>? _scoresSub;
  bool _day5Passed = false;

  @override
  void initState() {
    super.initState();
    _checkDay1Passed();
  }

  Future<void> _checkDay1Passed() async {
    final user = FirebaseAuthService().currentUser;
    _uid = user?.uid;
    if (_uid == null || _uid!.isEmpty) {
      setState(() {
        _day1Passed = false;
        _day2Passed = false;
        _day3Passed = false;
        _loading = false;
      });
      return;
    }
    _scoresSub?.cancel();
    _scoresSub = FirebaseFirestore.instance
        .collection('studentScores')
        .where('studentId', isEqualTo: _uid)
        .where('quizId', whereIn: [
          'intro_basic_movements_day1',
          'movement_relative_center_day2',
          'specialized_movements_day3',
          'anatomical_planes_day4',
          'movement_review_day5',
        ])
        .snapshots()
        .listen((snapshot) {
      bool d1 = _day1Passed;
      bool d2 = _day2Passed;
      bool d3 = _day3Passed;
      bool d4 = _day4Passed;
      bool d5 = _day5Passed;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final qa = (data['hasAnswered'] as bool?) ?? false;
        final ps = (data['passed'] as bool?) ?? false;
        final qid = data['quizId'] as String?;
        if (qid == 'intro_basic_movements_day1') d1 = qa && ps;
        if (qid == 'movement_relative_center_day2') d2 = qa && ps;
        if (qid == 'specialized_movements_day3') d3 = qa && ps;
        if (qid == 'anatomical_planes_day4') d4 = qa && ps;
        if (qid == 'movement_review_day5') d5 = qa && ps;
      }
      setState(() {
        _day1Passed = d1;
        _day2Passed = d2;
        _day3Passed = d3;
        _day4Passed = d4;
        _day5Passed = d5;
      });
    });
    try {
      final docId = '${_uid}_intro_basic_movements_day1';
      final doc = await FirebaseFirestore.instance
          .collection('studentScores')
          .doc(docId)
          .get(const GetOptions(source: Source.server));
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final hasAnswered = (data['hasAnswered'] as bool?) ?? false;
        final passed = (data['passed'] as bool?) ?? false;
        setState(() {
          _day1Passed = hasAnswered && passed;
          _loading = false;
        });
      } else {
        final query = await FirebaseFirestore.instance
            .collection('studentScores')
            .where('studentId', isEqualTo: _uid)
            .where('quizId', isEqualTo: 'intro_basic_movements_day1')
            .limit(1)
            .get(const GetOptions(source: Source.server));
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          final hasAnswered = (data['hasAnswered'] as bool?) ?? false;
          final passed = (data['passed'] as bool?) ?? false;
          setState(() {
            _day1Passed = hasAnswered && passed;
            _loading = false;
          });
        } else {
          setState(() {
            _day1Passed = false;
            _loading = false;
          });
        }
      }

      try {
        final d2id = '${_uid}_movement_relative_center_day2';
        final d2doc = await FirebaseFirestore.instance
            .collection('studentScores')
            .doc(d2id)
            .get(const GetOptions(source: Source.server));
        if (d2doc.exists) {
          final d2 = d2doc.data() as Map<String, dynamic>;
          final hasAnswered2 = (d2['hasAnswered'] as bool?) ?? false;
          final passed2 = (d2['passed'] as bool?) ?? false;
          _day2Passed = hasAnswered2 && passed2;
        } else {
          final d2q = await FirebaseFirestore.instance
              .collection('studentScores')
              .where('studentId', isEqualTo: _uid)
              .where('quizId', isEqualTo: 'movement_relative_center_day2')
              .limit(1)
              .get(const GetOptions(source: Source.server));
          if (d2q.docs.isNotEmpty) {
            final data2 = d2q.docs.first.data();
            final hasAnswered2 = (data2['hasAnswered'] as bool?) ?? false;
            final passed2 = (data2['passed'] as bool?) ?? false;
            _day2Passed = hasAnswered2 && passed2;
          } else {
            _day2Passed = false;
          }
        }
        setState(() {
          _loading = false;
        });
      } catch (_) {
        setState(() {
          _day2Passed = false;
          _loading = false;
        });
      }

      try {
        final d3id = '${_uid}_specialized_movements_day3';
        final d3doc = await FirebaseFirestore.instance
            .collection('studentScores')
            .doc(d3id)
            .get(const GetOptions(source: Source.server));
        if (d3doc.exists) {
          final d3 = d3doc.data() as Map<String, dynamic>;
          final hasAnswered3 = (d3['hasAnswered'] as bool?) ?? false;
          final passed3 = (d3['passed'] as bool?) ?? false;
          _day3Passed = hasAnswered3 && passed3;
        } else {
          final d3q = await FirebaseFirestore.instance
              .collection('studentScores')
              .where('studentId', isEqualTo: _uid)
              .where('quizId', isEqualTo: 'specialized_movements_day3')
              .limit(1)
              .get(const GetOptions(source: Source.server));
          if (d3q.docs.isNotEmpty) {
            final data3 = d3q.docs.first.data();
            final hasAnswered3 = (data3['hasAnswered'] as bool?) ?? false;
            final passed3 = (data3['passed'] as bool?) ?? false;
            _day3Passed = hasAnswered3 && passed3;
          } else {
            _day3Passed = false;
          }
        }
        setState(() {
          _loading = false;
        });
      } catch (_) {
        setState(() {
          _day3Passed = false;
          _loading = false;
        });
      }

      try {
        final d4id = '${_uid}_anatomical_planes_day4';
        final d4doc = await FirebaseFirestore.instance
            .collection('studentScores')
            .doc(d4id)
            .get(const GetOptions(source: Source.server));
        if (d4doc.exists) {
          final d4 = d4doc.data() as Map<String, dynamic>;
          final hasAnswered4 = (d4['hasAnswered'] as bool?) ?? false;
          final passed4 = (d4['passed'] as bool?) ?? false;
          _day4Passed = hasAnswered4 && passed4;
        } else {
          final d4q = await FirebaseFirestore.instance
              .collection('studentScores')
              .where('studentId', isEqualTo: _uid)
              .where('quizId', isEqualTo: 'anatomical_planes_day4')
              .limit(1)
              .get(const GetOptions(source: Source.server));
          if (d4q.docs.isNotEmpty) {
            final data4 = d4q.docs.first.data();
            final hasAnswered4 = (data4['hasAnswered'] as bool?) ?? false;
            final passed4 = (data4['passed'] as bool?) ?? false;
            _day4Passed = hasAnswered4 && passed4;
          } else {
            _day4Passed = false;
          }
        }
        setState(() {
          _loading = false;
        });
      } catch (_) {
        setState(() {
          _day4Passed = false;
          _loading = false;
        });
      }
      try {
        final d5id = '${_uid}_movement_review_day5';
        final d5doc = await FirebaseFirestore.instance
            .collection('studentScores')
            .doc(d5id)
            .get(const GetOptions(source: Source.server));
        if (d5doc.exists) {
          final d5 = d5doc.data() as Map<String, dynamic>;
          final hasAnswered5 = (d5['hasAnswered'] as bool?) ?? false;
          final passed5 = (d5['passed'] as bool?) ?? false;
          _day5Passed = hasAnswered5 && passed5;
        } else {
          final d5q = await FirebaseFirestore.instance
              .collection('studentScores')
              .where('studentId', isEqualTo: _uid)
              .where('quizId', isEqualTo: 'movement_review_day5')
              .limit(1)
              .get(const GetOptions(source: Source.server));
          if (d5q.docs.isNotEmpty) {
            final data5 = d5q.docs.first.data();
            final hasAnswered5 = (data5['hasAnswered'] as bool?) ?? false;
            final passed5 = (data5['passed'] as bool?) ?? false;
            _day5Passed = hasAnswered5 && passed5;
          } else {
            _day5Passed = false;
          }
        }
        setState(() {
          _loading = false;
        });
      } catch (_) {
        setState(() {
          _day5Passed = false;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _day1Passed = false;
        _day2Passed = false;
        _day3Passed = false;
        _day4Passed = false;
        _day5Passed = false;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scoresSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = const [
      'Introduction and Basic Movements',
      'Movements Relative to the Center',
      'Specialized Movements',
      'Perspectives in Movement (Anatomical Planes)',
      'Comprehensive Movement Review',
      'Comprehensive Final Quiz: Understanding Human Movement',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Understanding the Movements'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final title = topics[index];
          final isUnlocked = index == 0 || (index == 1 && _day1Passed) || (index == 2 && _day2Passed) || (index == 3 && _day3Passed) || (index == 4 && _day4Passed) || (index == 5 && _day1Passed && _day2Passed && _day3Passed && _day4Passed && _day5Passed);
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isUnlocked
                ? () {
                    if (index == 0) {
                      Navigator.pushNamed(context, '/intro-basic-movements');
                    } else if (index == 1) {
                      Navigator.pushNamed(context, '/movement-relative-center');
                    } else if (index == 2) {
                      Navigator.pushNamed(context, '/specialized-movements');
                    } else if (index == 3) {
                      Navigator.pushNamed(context, '/anatomical-planes');
                    } else if (index == 4) {
                      Navigator.pushNamed(context, '/movement-review');
                    } else if (index == 5) {
                      Navigator.pushNamed(context, '/final-quiz');
                    }
                  }
                : () {
                    if (index == 1 && !_loading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pass Day 1 Mini Quiz to unlock')),
                      );
                    } else if (index == 2 && !_loading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pass Day 2 Mini Quiz to unlock')),
                      );
                    } else if (index == 3 && !_loading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pass Day 3 Mini Quiz to unlock')),
                      );
                    } else if (index == 5 && !_loading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Locked · Pass all 5 mini quizzes to unlock the final assessment')),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.primaryBlue.withOpacity(0.12)
                          : AppColors.borderLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isUnlocked ? (index == 5 ? Icons.emoji_events : Icons.directions_run) : Icons.lock,
                      color: isUnlocked ? AppColors.primaryBlue : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!isUnlocked)
                          Text(
                            index == 1
                                ? (_loading ? 'Checking...' : 'Locked · Pass Day 1 Mini Quiz to unlock')
                                : index == 2
                                    ? (_loading ? 'Checking...' : 'Locked · Pass Day 2 Mini Quiz to unlock')
                                    : index == 3
                                        ? (_loading ? 'Checking...' : 'Locked · Pass Day 3 Mini Quiz to unlock')
                                        : index == 4
                                            ? (_loading ? 'Checking...' : 'Locked · Pass Day 4 Mini Quiz to unlock')
                                            : 'Locked · Complete previous topic to unlock',
                            style: AppTextStyles.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}