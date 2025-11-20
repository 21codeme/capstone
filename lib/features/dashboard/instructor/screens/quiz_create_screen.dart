import 'package:flutter/material.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';

class QuizCreateScreen extends StatelessWidget {
  final String topic;

  const QuizCreateScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final quizTypes = [
      {'label': 'Multiple Choice', 'icon': Icons.fact_check, 'type': 'multiple-choice', 'color': AppColors.primaryBlue},
      {'label': 'True or False', 'icon': Icons.check_circle_outline, 'type': 'true-false', 'color': AppColors.successGreen},
      {'label': 'Identification', 'icon': Icons.text_fields, 'type': 'identification', 'color': AppColors.warningOrange},
      {'label': 'Understand the Image', 'icon': Icons.image_outlined, 'type': 'understand-image', 'color': AppColors.secondaryBlue},
      {'label': 'Custom Quiz', 'icon': Icons.auto_fix_high, 'type': 'custom', 'color': AppColors.darkBlue},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.topic_outlined, color: AppColors.primaryBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          topic,
                          style: AppTextStyles.textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Quiz types',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a quiz type to start. (Placeholder)',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95, // slightly taller tiles to avoid overflow
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: quizTypes.length,
                  itemBuilder: (context, index) {
                    final item = quizTypes[index];
                    final Color color = item['color'] as Color;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/quiz-type',
                          arguments: {
                            'topic': topic,
                            'type': item['type'],
                            'label': item['label'],
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['label'] as String,
                              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create ${item['label']} Quiz.',
                              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}