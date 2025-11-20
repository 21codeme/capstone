import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/firebase_auth_service.dart';

class MusculoskeletalBasisScreen extends StatefulWidget {
  const MusculoskeletalBasisScreen({super.key});

  @override
  State<MusculoskeletalBasisScreen> createState() => _MusculoskeletalBasisScreenState();
}

class _MusculoskeletalBasisScreenState extends State<MusculoskeletalBasisScreen> {
  bool _day1Passed = false;
  bool _day2Passed = false;
  bool _day3Passed = false;
  bool _day4Passed = false;
  bool _day5Passed = false;
  bool _loading = true;
  String? _uid;
  StreamSubscription<QuerySnapshot>? _scoresSub;

  @override
  void initState() {
    super.initState();
    _checkProgress();
  }

  Future<void> _checkProgress() async {
    final user = FirebaseAuthService().currentUser;
    _uid = user?.uid;
    if (_uid == null || _uid!.isEmpty) {
      setState(() {
        _day1Passed = false;
        _day2Passed = false;
        _day3Passed = false;
        _day4Passed = false;
        _day5Passed = false;
        _loading = false;
      });
      return;
    }
    _scoresSub?.cancel();
    _scoresSub = FirebaseFirestore.instance
        .collection('studentScores')
        .where('studentId', isEqualTo: _uid)
        .where('quizId', whereIn: [
          'musculoskeletal_basis_day1',
          'musculoskeletal_basis_day2',
          'musculoskeletal_basis_day3',
          'musculoskeletal_basis_day4',
          'musculoskeletal_basis_day5',
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
        if (qid == 'musculoskeletal_basis_day1') d1 = qa && ps;
        if (qid == 'musculoskeletal_basis_day2') d2 = qa && ps;
        if (qid == 'musculoskeletal_basis_day3') d3 = qa && ps;
        if (qid == 'musculoskeletal_basis_day4') d4 = qa && ps;
        if (qid == 'musculoskeletal_basis_day5') d5 = qa && ps;
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
      final ids = [
        'musculoskeletal_basis_day1',
        'musculoskeletal_basis_day2',
        'musculoskeletal_basis_day3',
        'musculoskeletal_basis_day4',
        'musculoskeletal_basis_day5',
      ];
      final setters = [
        (bool v) => _day1Passed = v,
        (bool v) => _day2Passed = v,
        (bool v) => _day3Passed = v,
        (bool v) => _day4Passed = v,
        (bool v) => _day5Passed = v,
      ];
      for (int i = 0; i < ids.length; i++) {
        final qid = ids[i];
        final docId = '${_uid}_$qid';
        final doc = await FirebaseFirestore.instance
            .collection('studentScores')
            .doc(docId)
            .get(const GetOptions(source: Source.server));
        bool passed = false;
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final hasAnswered = (data['hasAnswered'] as bool?) ?? false;
          final ps = (data['passed'] as bool?) ?? false;
          passed = hasAnswered && ps;
        } else {
          final query = await FirebaseFirestore.instance
              .collection('studentScores')
              .where('studentId', isEqualTo: _uid)
              .where('quizId', isEqualTo: qid)
              .limit(1)
              .get(const GetOptions(source: Source.server));
          if (query.docs.isNotEmpty) {
            final data = query.docs.first.data();
            final hasAnswered = (data['hasAnswered'] as bool?) ?? false;
            final ps = (data['passed'] as bool?) ?? false;
            passed = hasAnswered && ps;
          } else {
            passed = false;
          }
        }
        setters[i](passed);
      }
      setState(() {
        _loading = false;
      });
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
      'Introduction to Musculoskeletal Basis of Movement & The Skeleton',
      'Muscle Physiology and Fiber Types',
      'Muscle Architecture and Core Stability',
      'Types of Muscle Contraction and Landing Mechanics',
      'Movement Injuries and Prevention',
      'Comprehensive Final Quiz: Musculoskeletal Basis',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Musculoskeletal Basis'),
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
                      Navigator.pushNamed(context, '/musculo-intro');
                    } else if (index == 1) {
                      Navigator.pushNamed(context, '/muscle-physiology');
                    } else if (index == 2) {
                      Navigator.pushNamed(context, '/muscle-architecture');
                    } else if (index == 3) {
                      Navigator.pushNamed(context, '/muscle-contractions-landing');
                    } else if (index == 4) {
                      Navigator.pushNamed(context, '/movement-injuries-prevention');
                    } else if (index == 5) {
                      Navigator.pushNamed(context, '/musculoskeletal-final-quiz');
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
                    } else if (index == 4 && !_loading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pass Day 4 Mini Quiz to unlock')),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                          ? AppColors.primaryBlue.withValues(alpha: 0.12)
                          : AppColors.borderLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isUnlocked ? Icons.healing : Icons.lock,
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
                                            : (_loading ? 'Checking...' : 'Locked · Pass all previous Mini Quizzes to unlock'),
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

class _TopicPlaceholderScreen extends StatelessWidget {
  final String title;
  const _TopicPlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Content coming soon',
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}