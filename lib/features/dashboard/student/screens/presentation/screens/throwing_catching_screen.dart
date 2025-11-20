import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import 'throwing_catching_day1_screen.dart';
import 'throwing_catching_day2_screen.dart';
import 'throwing_catching_day3_screen.dart';
import 'throwing_catching_day4_screen.dart';
import 'throwing_catching_day5_screen.dart';
import 'throwing_catching_final_quiz_screen.dart';

class ThrowingCatchingScreen extends StatefulWidget {
  const ThrowingCatchingScreen({super.key});

  @override
  State<ThrowingCatchingScreen> createState() => _ThrowingCatchingScreenState();
}

class _ThrowingCatchingScreenState extends State<ThrowingCatchingScreen> {
  String? _uid;
  bool _loading = true;
  StreamSubscription<QuerySnapshot>? _scoresSub;
  bool _day1Passed = false;
  bool _day2Passed = false;
  bool _day3Passed = false;
  bool _day4Passed = false;
  bool _day5Passed = false;

  @override
  void initState() {
    super.initState();
    _initProgress();
  }

  Future<void> _initProgress() async {
    final auth = FirebaseAuthService();
    _uid = auth.currentUser?.uid;
    if (_uid == null) {
      setState(() => _loading = false);
      return;
    }
    final ids = [
      'throw_catch_day1',
      'throw_catch_day2',
      'throw_catch_day3',
      'throw_catch_day4',
      'throw_catch_day5',
    ];
    _scoresSub = FirebaseFirestore.instance
        .collection('studentScores')
        .where('studentId', isEqualTo: _uid)
        .where('quizId', whereIn: ids)
        .snapshots()
        .listen((snapshot) {
      bool d1 = _day1Passed;
      bool d2 = _day2Passed;
      bool d3 = _day3Passed;
      bool d4 = _day4Passed;
      bool d5 = _day5Passed;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quizId = data['quizId'] as String?;
        final hasAnswered = (data['hasAnswered'] as bool?) ?? false;
        final passed = (data['passed'] as bool?) ?? false;
        final ok = hasAnswered && passed;
        if (quizId == 'throw_catch_day1' && ok) d1 = true;
        if (quizId == 'throw_catch_day2' && ok) d2 = true;
        if (quizId == 'throw_catch_day3' && ok) d3 = true;
        if (quizId == 'throw_catch_day4' && ok) d4 = true;
        if (quizId == 'throw_catch_day5' && ok) d5 = true;
      }
      setState(() {
        _day1Passed = d1;
        _day2Passed = d2;
        _day3Passed = d3;
        _day4Passed = d4;
        _day5Passed = d5;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _scoresSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = const [
      'Introduction to Throwing and the Phases of Throwing',
      'Developmental Stages of Throwing - Stages 1 and 2',
      'Developmental Stages of Throwing - Stages 3, 4, and 5',
      'Factors Influencing Throwing Performance',
      'Review & Application',
      'Comprehensive Final Quiz: Throwing & Catching',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Throwing & Catching'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final title = topics[index];
                final isUnlocked = index == 0 ||
                    (index == 1 && _day1Passed) ||
                    (index == 2 && _day2Passed) ||
                    (index == 3 && _day3Passed) ||
                    (index == 4 && _day4Passed) ||
                    (index == 5 && _day5Passed);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isUnlocked
                      ? () {
                          if (index == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThrowingCatchingDay1Screen(),
                              ),
                            );
                          } else if (index == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThrowingCatchingDay2Screen(),
                              ),
                            );
                          } else if (index == 2) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThrowingCatchingDay3Screen(),
                              ),
                            );
                          } else if (index == 3) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThrowingCatchingDay4Screen(),
                              ),
                            );
                          } else if (index == 4) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThrowingCatchingDay5Screen(),
                              ),
                            );
                          } else if (index == 5) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThrowingCatchingFinalQuizScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _TopicPlaceholderScreen(title: title),
                              ),
                            );
                          }
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Locked · Complete previous topic to unlock')),
                          );
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
                            isUnlocked ? Icons.sports_baseball : Icons.lock,
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
                                  'Locked · Complete previous topic to unlock',
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