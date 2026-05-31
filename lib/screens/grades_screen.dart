import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  // Expansion state for categories
  final Map<String, bool> _expandedState = {
    'Activities': true,
    'Quizzes': true,
    'Oral Recit': false,
    'Exams': false,
    'Projects': false,
  };

  @override
  Widget build(BuildContext context) {
    // Math checks out: (88 * 0.2) + (80 * 0.2) + (92 * 0.15) + (85 * 0.3) + (90 * 0.15) = 86.4% (rounds to 87%)
    const double weightedGrade = 86.4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Screen Title
              const Text(
                'Grades',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Weighted Grade Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Circular Progress Indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: weightedGrade / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        Text(
                          '${weightedGrade.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Grade Description
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weighted Grade',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2nd Semester - All categories',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categories List
              _buildCategoryCard(
                categoryName: 'Activities',
                weight: 20,
                averageScore: 88,
                colorKey: 'Activity',
                icon: Icons.assignment_outlined,
                items: [
                  _GradeItem(title: 'Activity 1', score: 92, maxScore: 100),
                  _GradeItem(title: 'Activity 2', score: 85, maxScore: 100),
                  _GradeItem(title: 'Activity 3', score: 88, maxScore: 100),
                ],
              ),
              _buildCategoryCard(
                categoryName: 'Quizzes',
                weight: 20,
                averageScore: 80,
                colorKey: 'Quiz',
                icon: Icons.quiz_outlined,
                items: [
                  _GradeItem(title: 'Quiz 1', score: 39, maxScore: 50),
                  _GradeItem(title: 'Quiz 2', score: 41, maxScore: 50),
                ],
              ),
              _buildCategoryCard(
                categoryName: 'Oral Recit',
                weight: 15,
                averageScore: 92,
                colorKey: 'Personal',
                icon: Icons.record_voice_over_outlined,
                items: [
                  _GradeItem(title: 'Recitation 1', score: 95, maxScore: 100),
                  _GradeItem(title: 'Recitation 2', score: 89, maxScore: 100),
                ],
              ),
              _buildCategoryCard(
                categoryName: 'Exams',
                weight: 30,
                averageScore: 85,
                colorKey: 'Exam',
                icon: Icons.description_outlined,
                items: [
                  _GradeItem(title: 'Prelim Exam', score: 82, maxScore: 100),
                  _GradeItem(title: 'Midterm Exam', score: 88, maxScore: 100),
                  _GradeItem(title: 'Final Exam', score: 85, maxScore: 100),
                ],
              ),
              _buildCategoryCard(
                categoryName: 'Projects',
                weight: 15,
                averageScore: 90,
                colorKey: 'Project',
                icon: Icons.folder_open_outlined,
                items: [
                  _GradeItem(title: 'Capstone Project 1', score: 90, maxScore: 100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String categoryName,
    required int weight,
    required double averageScore,
    required String colorKey,
    required IconData icon,
    required List<_GradeItem> items,
  }) {
    final isExpanded = _expandedState[categoryName] ?? false;
    final bgColor = AppColors.categoryColors[colorKey] ?? AppColors.categoryColors['Others']!;
    final textColor = AppColors.categoryTextColors[colorKey] ?? AppColors.categoryTextColors['Others']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _expandedState[categoryName] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: textColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  // Title and weight
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$weight% weight',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Average percentage
                  Text(
                    '${averageScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Expandable Child Items
          if (isExpanded) ...[
            const Divider(color: AppColors.border, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: items.map((item) {
                  final double pct = item.maxScore > 0 ? (item.score / item.maxScore) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Mini progress bar in middle
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 4,
                                backgroundColor: AppColors.background,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              ),
                            ),
                          ),
                        ),
                        // Score display
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              item.maxScore == 100
                                  ? '${item.score}'
                                  : '${item.score}/${item.maxScore}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeItem {
  final String title;
  final int score;
  final int maxScore;

  const _GradeItem({
    required this.title,
    required this.score,
    required this.maxScore,
  });
}
