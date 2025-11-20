import 'package:flutter/material.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final List<String> _quizTopics = const [
    'Understanding Movements',
    'Musculoskeletal Basis',
    'Discrete Skills',
    'Throwing & Catching',
    'Serial Skills',
    'Continuous Skills',
  ];

  String _searchQuery = '';

  final List<Color> _cardColors = const [
    AppColors.warningOrange,
    AppColors.primaryBlue,
    AppColors.successGreen,
    AppColors.errorRed,
    AppColors.darkBlue,
    AppColors.secondaryBlue,
  ];

  final List<IconData> _cardIcons = const [
    Icons.list_alt_outlined,
    Icons.assignment_outlined,
    Icons.center_focus_strong_outlined,
    Icons.forum_outlined,
    Icons.grid_view_outlined,
    Icons.quiz_outlined,
  ];

  final List<String> _lastUsed = const [
    'Last used 5 days ago',
    'Last used 2 days ago',
    'Last used 2 weeks ago',
    'Last used 5 hours ago',
    'Last used yesterday',
    'Last used 3 days ago',
  ];

  List<String> get _filteredTopics {
    final query = _searchQuery.trim().toLowerCase();
    return _quizTopics.where((t) => t.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Remove AppBar and header per request
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Expanded(child: _buildColoredCardList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildColoredCardList() {
    final items = _filteredTopics;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No quizzes found',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final topic = items[index];
        final lastText = _lastUsed[index % _lastUsed.length];
        final icon = _iconForTopic(topic);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/quiz-create',
                arguments: {
                  'topic': topic,
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Blue accent bar
                    Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic,
                              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastText,
                              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Trailing icons
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        icon,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2, // Quiz tab active
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushNamed(context, '/instructor-dashboard');
              break;
            case 1: // Modules
              // Navigate to instructor modules (upload/manage), not student modules
              Navigator.pushNamed(context, '/module-upload');
              break;
            case 2: // Quiz (current)
              break;
            case 3: // Settings
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.textTheme.bodySmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Modules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

Widget _buildHeader() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Create Quiz',
        style: AppTextStyles.textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Design and manage assessments',
        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}

IconData _iconForTopic(String topic) {
  switch (topic) {
    case 'Understanding Movements':
      return Icons.list_alt_outlined;
    case 'Musculoskeletal Basis':
      return Icons.assignment_outlined;
    case 'Discrete Skills':
      return Icons.center_focus_strong_outlined;
    case 'Throwing & Catching':
      return Icons.forum_outlined;
    case 'Serial Skills':
      return Icons.grid_view_outlined;
    case 'Continuous Skills':
      return Icons.quiz_outlined;
    default:
      return Icons.quiz_outlined;
  }
}