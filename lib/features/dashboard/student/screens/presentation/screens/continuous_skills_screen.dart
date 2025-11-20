import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import 'continuous_skills_day1_screen.dart';
import 'continuous_skills_day2_screen.dart';
import 'continuous_skills_day3_screen.dart';
import 'continuous_skills_day4_screen.dart';
import 'continuous_skills_day5_screen.dart';
import 'continuous_skills_final_quiz_screen.dart';

class ContinuousSkillsScreen extends StatefulWidget {
  const ContinuousSkillsScreen({super.key});

  @override
  State<ContinuousSkillsScreen> createState() => _ContinuousSkillsScreenState();
}

class _ContinuousSkillsScreenState extends State<ContinuousSkillsScreen> {
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
      'continuous_skills_day1',
      'continuous_skills_day2',
      'continuous_skills_day3',
      'continuous_skills_day4',
      'continuous_skills_day5',
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
        if (quizId == 'continuous_skills_day1' && ok) d1 = true;
        if (quizId == 'continuous_skills_day2' && ok) d2 = true;
        if (quizId == 'continuous_skills_day3' && ok) d3 = true;
        if (quizId == 'continuous_skills_day4' && ok) d4 = true;
        if (quizId == 'continuous_skills_day5' && ok) d5 = true;
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
      'Introduction to Continuous Skills',
      'Feedback and Control in Continuous Skills',
      'Energetics, Endurance, and Pacing',
      'Coordination, Rhythm, and Technique',
      'Review & Application',
      'Comprehensive Final Quiz: Continuous Skills',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Continuous Skills'),
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
                          Widget screen;
                          if (index == 0) {
                            screen = const ContinuousSkillsDay1Screen();
                          } else if (index == 1) {
                            screen = const ContinuousSkillsDay2Screen();
                          } else if (index == 2) {
                            screen = const ContinuousSkillsDay3Screen();
                          } else if (index == 3) {
                            screen = const ContinuousSkillsDay4Screen();
                          } else if (index == 4) {
                            screen = const ContinuousSkillsDay5Screen();
                          } else {
                            screen = const ContinuousSkillsFinalQuizScreen();
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => screen),
                          );
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
                            isUnlocked ? Icons.loop : Icons.lock,
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