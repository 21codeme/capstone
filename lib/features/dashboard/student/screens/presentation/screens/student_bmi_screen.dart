import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/bmi_service.dart';

class StudentBmiScreen extends StatefulWidget {
  const StudentBmiScreen({super.key});

  @override
  State<StudentBmiScreen> createState() => _StudentBmiScreenState();
}

class _StudentBmiScreenState extends State<StudentBmiScreen> {
  final BmiService _bmiService = BmiService();
  
  bool _isLoading = true;
  
  // BMI tracking variables
  double _currentBMI = 0.0;
  final double _targetBMI = 22.0; // Healthy BMI range
  double _bmiProgress = 0.0;
  List<Map<dynamic, dynamic>> _bmiHistory = [];
  bool _canUpdateBMI = true; // Whether user can update BMI this month

  @override
  void initState() {
    super.initState();
    _loadBMIData();
  }

  Future<void> _loadBMIData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load BMI data from service
      final bmiData = await _bmiService.getLatestBmiData();
      
      if (bmiData != null) {
        setState(() {
          _currentBMI = (bmiData['bmi'] ?? 0.0).toDouble();
        });
      }

      // Load BMI history
      final bmiHistory = await _bmiService.getBmiHistory();
      setState(() {
        _bmiHistory = bmiHistory;
        // Recalculate progress after history is loaded using baseline
        _calculateBMIProgress();
      });

      // Check if user can update BMI this month
      final canUpdateResult = await _bmiService.canUpdateBMI();
      setState(() {
        _canUpdateBMI = canUpdateResult['canUpdate'] ?? true;
      });

    } catch (e) {
      print('Error loading BMI data: $e');
      // Set some mock data for testing
      setState(() {
        _currentBMI = 23.5;
        _bmiProgress = 75.0;
        _bmiHistory = [
          {'date': DateTime.now().subtract(const Duration(days: 30)), 'bmi': 24.2},
          {'date': DateTime.now().subtract(const Duration(days: 20)), 'bmi': 23.8},
          {'date': DateTime.now().subtract(const Duration(days: 10)), 'bmi': 23.5},
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateBMIProgress() {
    // Compute progress against personal baseline (earliest BMI in history) towards target
    double progress = 0.0;

    try {
      if (_currentBMI <= 0) {
        _bmiProgress = 0.0;
        return;
      }

      // Determine baseline from earliest history entry; fall back to current BMI
      double baselineBMI = _currentBMI;
      if (_bmiHistory.isNotEmpty) {
        Map<dynamic, dynamic>? earliestEntry;
        DateTime? earliestDate;

        for (final entry in _bmiHistory) {
          DateTime? d;
          final ts = entry['timestamp'];
          if (ts != null) {
            try {
              d = (ts as dynamic).toDate();
            } catch (_) {
              if (ts is DateTime) {
                d = ts;
              } else if (ts is String) {
                // Try ISO8601 parse
                try { d = DateTime.parse(ts); } catch (_) {}
              }
            }
          }
          if (d == null && entry['date'] is DateTime) {
            d = entry['date'] as DateTime;
          }
          if (d == null && entry['updateDate'] is String) {
            try { d = DateTime.parse(entry['updateDate'] as String); } catch (_) {}
          }

          if (d != null && (earliestDate == null || d.isBefore(earliestDate))) {
            earliestDate = d;
            earliestEntry = entry;
          }
        }

        final source = earliestEntry ?? _bmiHistory.last;
        baselineBMI = (source['bmi'] as num?)?.toDouble() ?? _currentBMI;
      }

      final double baselineDistance = (baselineBMI - _targetBMI).abs();
      final double currentDistance = (_currentBMI - _targetBMI).abs();

      if (baselineDistance <= 0.0) {
        progress = currentDistance <= 0.0 ? 100.0 : 0.0;
      } else {
        progress = ((baselineDistance - currentDistance) / baselineDistance) * 100.0;
      }

      _bmiProgress = progress.clamp(0.0, 100.0);
    } catch (_) {
      // Fallback to 0 progress on error
      _bmiProgress = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('BMI Tracking'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBMIOverviewCard(),
                  const SizedBox(height: 24),
                  _buildBMICalendarCard(),
                  const SizedBox(height: 24),
                  _buildFitnessRecommendationsCard(),
                  const SizedBox(height: 24),
                  if (_bmiHistory.isNotEmpty) _buildBMIHistoryChart(),
                  const SizedBox(height: 24),
                  _buildUpdateBMICard(),
                ],
              ),
            ),
    );
  }

  Widget _buildBMIOverviewCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current BMI Status',
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current BMI',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currentBMI.toStringAsFixed(1),
                        style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target BMI',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _targetBMI.toStringAsFixed(1),
                        style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getBMICategoryColor(_currentBMI),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getBMICategory(_currentBMI),
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIProgressCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.successGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Progress to Target',
                  style: AppTextStyles.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${_bmiProgress.toStringAsFixed(1)}%',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _bmiProgress / 100,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
              minHeight: 12,
            ),
          ],
        ),
      ),
    );
  }

  // New calendar card showing old and new BMI per month
  Widget _buildBMICalendarCard() {
    // Build ascending history to compute previous (old) vs new BMI per entry
    final List<Map<dynamic, dynamic>> historyAsc = List<Map<dynamic, dynamic>>.from(_bmiHistory);
    historyAsc.sort((a, b) => _safeToDate(_extractTimestamp(a)).compareTo(_safeToDate(_extractTimestamp(b))));

    double? previousBmi;
    final tiles = <Widget>[];

    for (final data in historyAsc) {
      final DateTime date = _safeToDate(_extractTimestamp(data));
      final double newBmi = ((data['bmi'] ?? _currentBMI) as num).toDouble();
      final double? oldBmi = previousBmi;
      previousBmi = newBmi;

      tiles.add(_buildMonthTile(date, oldBmi, newBmi));
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'BMI Calendar',
                  style: AppTextStyles.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (tiles.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No BMI entries yet. Your calendar will appear after the first update.',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: tiles,
              ),
          ],
        ),
      ),
    );
  }

  dynamic _extractTimestamp(Map<dynamic, dynamic> data) {
    return data['timestamp'] ?? data['date'] ?? data['updateDate'] ?? data['createdAt'];
  }

  DateTime _safeToDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      // Handle Firestore Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }
    } catch (_) {}
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is Map) {
      // Handle serialized timestamps
      if (value.containsKey('_seconds')) {
        final seconds = (value['_seconds'] as num).toInt();
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
      if (value.containsKey('seconds')) {
        final seconds = (value['seconds'] as num).toInt();
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    // Fallback for objects with toDate()
    try {
      final dynamic maybeDate = (value as dynamic).toDate();
      if (maybeDate is DateTime) return maybeDate;
    } catch (_) {}
    return DateTime.now();
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildMonthTile(DateTime date, double? oldBmi, double newBmi) {
    final Color badgeColor = _getBMICategoryColor(newBmi);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatMonthYear(date),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Old BMI',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                oldBmi != null ? oldBmi.toStringAsFixed(1) : '-',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New BMI',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getBMICategory(newBmi),
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    newBmi.toStringAsFixed(1),
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessRecommendationsCard() {
    // Build actionable advice based on BMI category
    String category = _getBMICategory(_currentBMI);
    Color recommendationColor;
    IconData recommendationIcon;
    List<String> tips;

    if (_currentBMI >= 40) {
      // Class III obesity
      recommendationColor = AppColors.errorRed;
      recommendationIcon = Icons.health_and_safety;
      tips = [
        'Medical clearance recommended before exercise; start low-impact (walking, cycling, pool).',
        'Aim 250–400 min/week moderate cardio; begin with 10–15 min blocks and add weekly.',
        '2–3 strength sessions/week focusing on full-body, chair-supported or machines.',
        'Nutrition: 500–750 kcal/day deficit, high protein (~1.6 g/kg), high fiber (25–38 g).',
        'Sleep 7–9 hours; manage stress; limit sugary drinks and ultra-processed snacks.',
      ];
    } else if (_currentBMI >= 35) {
      // Class II obesity
      recommendationColor = AppColors.warningOrange;
      recommendationIcon = Icons.directions_walk;
      tips = [
        'Start with 200–300 min/week moderate cardio (walk, bike); increase pace gradually.',
        'Strength train 2–3x/week: push, pull, squat/hinge; 2–3 sets of 8–12 reps.',
        'Create a 500 kcal/day deficit; prioritize protein (1.6 g/kg) and fiber-rich foods.',
        'Hydration: 2–3 L/day; reduce liquid calories and late-night snacking.',
        'Weekly weigh-ins; update BMI monthly to track progress.',
      ];
    } else if (_currentBMI >= 30) {
      // Class I obesity
      recommendationColor = AppColors.warningOrange;
      recommendationIcon = Icons.directions_run;
      tips = [
        '150–300 min/week moderate cardio (brisk walk, cycling, elliptical).',
        'Strength train 2–3x/week focusing on major muscle groups; prioritize technique.',
        'Nutrition: 300–500 kcal/day deficit; protein ~1.6 g/kg; fiber 25–38 g.',
        'Lifestyle: aim 8–10k steps/day; sleep 7–9 hours; reduce sedentary time.',
        'Monitor portions; track meals 3–4 days/week; re-check BMI monthly.',
      ];
    } else if (_currentBMI >= 25) {
      // Overweight
      recommendationColor = AppColors.warningOrange;
      recommendationIcon = Icons.fitness_center;
      tips = [
        'Cardio 150–200 min/week (e.g., 30–40 min × 5 days).',
        'Strength training 2–3x/week to preserve muscle; progressive overload.',
        'Nutrition: modest 300–400 kcal/day deficit; high-protein meals and plenty of veg.',
        'Swap sugary drinks for water; plan snacks; eat slowly and mindfully.',
        'Track steps (7–9k/day) and update BMI monthly to confirm trend.',
      ];
    } else if (_currentBMI < 16) {
      // Severe underweight
      recommendationColor = AppColors.primaryBlue;
      recommendationIcon = Icons.health_and_safety;
      tips = [
        'Seek medical guidance; rule out underlying issues before aggressive training.',
        'Strength training 2–3x/week; minimal cardio, focus on recovery.',
        'Nutrition: 400–600 kcal/day surplus; protein 1.6–2.2 g/kg; energy-dense snacks.',
        'Include healthy fats (nuts, avocado, olive oil) and structured meals.',
        'Sleep 8 hours; monitor appetite and weight weekly; update BMI monthly.',
      ];
    } else if (_currentBMI < 18.5) {
      // Underweight
      recommendationColor = AppColors.primaryBlue;
      recommendationIcon = Icons.fitness_center;
      tips = [
        'Strength train 3x/week with compound lifts; progressive overload.',
        'Keep cardio light (≤60 min/week) to prioritize weight gain.',
        'Nutrition: 300–500 kcal/day surplus; protein 1.6–2.0 g/kg; carbs around training.',
        'Add 2 snacks/day; smoothies and yogurt bowls help hit calories easily.',
        'Track weight weekly and BMI monthly; adjust surplus if gain stalls.',
      ];
    } else {
      // Healthy range
      recommendationColor = AppColors.successGreen;
      recommendationIcon = Icons.check_circle;
      tips = [
        'Maintain 150 min/week moderate cardio or 75 min vigorous.',
        'Strength train 2–3x/week; rotate push/pull/legs; include core.',
        'Balanced meals: protein at each meal, colorful veg, whole grains.',
        'Sleep 7–9 hours; manage stress; keep daily steps 7–10k.',
        'Reassess goals quarterly; keep monthly BMI update to monitor trends.',
      ];
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  recommendationIcon,
                  color: recommendationColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fitness Recommendations',
                  style: AppTextStyles.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: recommendationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: recommendationColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$category Guidance',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: recommendationColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...tips.map((t) => _buildSuggestionRow(Icons.check, t, recommendationColor)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIHistoryChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'BMI History',
                  style: AppTextStyles.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _bmiHistory.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<dynamic, dynamic> data = entry.value;
                  double bmi = (data['bmi'] ?? 0.0).toDouble();
                  double height = ((bmi - 18) / (30 - 18)) * 120; // Normalize to 0-120 height
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 32,
                        height: height.clamp(10, 120),
                        decoration: BoxDecoration(
                          color: _getBMICategoryColor(bmi),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bmi.toStringAsFixed(1),
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Entry ${index + 1}',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateBMICard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.update,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Update BMI',
                  style: AppTextStyles.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _canUpdateBMI 
                  ? 'You can update your BMI this month. Enter your current weight and height to track your progress.'
                  : 'You have already updated your BMI this month. You can update again next month.',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canUpdateBMI ? _showUpdateBMIDialog : null,
                icon: Icon(
                  Icons.monitor_weight,
                  size: 20,
                ),
                label: Text(
                  _canUpdateBMI ? 'Update BMI' : 'BMI Updated This Month',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canUpdateBMI ? AppColors.primaryBlue : AppColors.surface,
                  foregroundColor: _canUpdateBMI ? Colors.white : AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _canUpdateBMI ? 4 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateMonthlyBMI(double newBMI) async {
    // Validate BMI input
    if (newBMI <= 0 || newBMI > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid BMI value. Please enter a valid BMI between 10-100.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Check if user can update BMI this month
    final canUpdateResult = await _bmiService.canUpdateBMI();
    if (!canUpdateResult['canUpdate']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(canUpdateResult['reason'] ?? 'You can only update BMI once per month'),
          backgroundColor: AppColors.warningOrange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    try {
      // Save BMI to Firebase
      final success = await _bmiService.saveBmiData(
        height: 170.0, // Default height - you may want to get this from user profile
        weight: newBMI * 1.7 * 1.7, // Calculate weight from BMI (BMI = weight/height²)
        bmi: newBMI,
      );

      if (success['success'] == true) {
        // Also persist to history for progress tracking
        await _bmiService.saveBmiToHistory(
          height: 170.0,
          weight: newBMI * 1.7 * 1.7,
          bmi: newBMI,
        );
        setState(() {
          _currentBMI = newBMI;
          
          // Calculate new BMI progress against baseline
          _calculateBMIProgress();
          
          // Add to history
          _bmiHistory.add({
            'date': DateTime.now(),
            'bmi': newBMI,
          });
          
          _canUpdateBMI = false; // User has updated for this month
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BMI updated successfully! New BMI: ${newBMI.toStringAsFixed(1)}'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to save BMI data');
      }
    } catch (e) {
      print('Error updating BMI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating BMI. Please try again.'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showUpdateBMIDialog() {
    final TextEditingController weightController = TextEditingController();
    final TextEditingController heightController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.monitor_weight,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Update BMI',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your current weight and height to calculate your new BMI.',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter your weight',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'Enter your height',
                  prefixIcon: Icon(Icons.height),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text);
                final height = double.tryParse(heightController.text);
                
                if (weight != null && height != null && weight > 0 && height > 0) {
                  // Calculate BMI: weight (kg) / (height (m))^2
                  final heightInMeters = height / 100;
                  final newBMI = weight / (heightInMeters * heightInMeters);
                  
                  Navigator.of(context).pop();
                  updateMonthlyBMI(newBMI);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter valid weight and height values'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Update BMI'),
            ),
          ],
        );
      },
    );
  }
  
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
  
  Color _getBMICategoryColor(double bmi) {
    if (bmi < 18.5) return AppColors.warningOrange;
    if (bmi < 25) return AppColors.successGreen;
    if (bmi < 30) return AppColors.warningOrange;
    return AppColors.errorRed;
  }
}