import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class QuizDifficultyPieChart extends StatelessWidget {
  final List<PieChartSegment> segments;
  final double size;
  final Function(PieChartSegment)? onSegmentTap;

  const QuizDifficultyPieChart({
    super.key,
    required this.segments,
    this.size = 100,
    this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out segments with 0 value
    final validSegments = segments.where((s) => s.value > 0 && s.percentage > 0).toList();
    final totalQuestions = validSegments.fold<int>(0, (sum, s) => sum + s.value);

    if (validSegments.isEmpty || totalQuestions == 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart, size: 32, color: AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                'No Data',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (onSegmentTap != null && validSegments.isNotEmpty) {
          // Show full screen on tap
        }
      },
      child: CustomPaint(
        size: Size(size, size),
        painter: PieChartPainter(
          segments: validSegments,
          onSegmentTap: onSegmentTap,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quiz Difficulty',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalQuestions Questions',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PieChartSegment {
  final String label;
  final int value;
  final Color color;
  final double percentage;

  PieChartSegment({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });
}

class PieChartPainter extends CustomPainter {
  final List<PieChartSegment> segments;
  final Function(PieChartSegment)? onSegmentTap;

  PieChartPainter({
    required this.segments,
    this.onSegmentTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (final segment in segments) {
      if (segment.percentage <= 0) continue;
      
      final sweepAngle = (segment.percentage / 100) * 2 * 3.14159;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

