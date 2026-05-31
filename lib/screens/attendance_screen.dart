import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Attendance statistics
    const int totalClasses = 35;
    const int presentCount = 32;
    const int absentCount = 2;
    const int lateCount = 1;
    const double attendancePercentage = (presentCount / totalClasses) * 100;

    // Calendar setup: March 2026
    // March 1, 2026 is Sunday, so offset is 0.
    final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const int daysInMonth = 31;
    const int todayDate = 16;
    
    // Status mappings
    final Set<int> absentDates = {10, 24};
    final Set<int> lateDates = {13};
    
    // Helper to check weekday (March 1 is Sunday, so March date = index + 1)
    bool isWeekend(int date) {
      // 1 is Sun, 7 is Sat, 8 is Sun, etc.
      final int dayOfWeek = (date - 1) % 7;
      return dayOfWeek == 0 || dayOfWeek == 6;
    }

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
                'Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Main Attendance Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${attendancePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$presentCount of $totalClasses classes attended',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mini statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      'Present',
                      presentCount.toString(),
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Absent',
                      absentCount.toString(),
                      AppColors.urgent.withOpacity(0.1),
                      AppColors.urgent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Late',
                      lateCount.toString(),
                      AppColors.high.withOpacity(0.1),
                      AppColors.high,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calendar Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Month & Year Header
                    const Text(
                      'March 2026',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Weekdays headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekdays.map((day) {
                        return SizedBox(
                          width: 32,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Days grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: daysInMonth,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final int date = index + 1;
                        final bool isToday = date == todayDate;
                        final bool isAbsent = absentDates.contains(date);
                        final bool isLate = lateDates.contains(date);
                        final bool isWeekendDay = isWeekend(date);
                        final bool isPresent = !isAbsent && !isLate && !isWeekendDay && date <= todayDate;

                        // Decorate cell based on status
                        Color? cellBg;
                        Color textCol = AppColors.textPrimary;
                        Border? border;

                        if (isToday) {
                          cellBg = AppColors.primaryDark;
                          textCol = Colors.white;
                        } else if (isAbsent) {
                          cellBg = AppColors.urgent.withOpacity(0.15);
                          textCol = AppColors.urgent;
                        } else if (isLate) {
                          cellBg = AppColors.high.withOpacity(0.15);
                          textCol = AppColors.high;
                        } else if (isPresent) {
                          cellBg = AppColors.primary.withOpacity(0.1);
                          textCol = AppColors.primary;
                        } else if (isWeekendDay) {
                          textCol = AppColors.textSecondary.withOpacity(0.4);
                        } else {
                          // Future dates or weekends without stats
                          textCol = AppColors.textPrimary.withOpacity(0.6);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: cellBg,
                            shape: BoxShape.circle,
                            border: border,
                          ),
                          child: Center(
                            child: Text(
                              date.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday || isAbsent || isLate || isPresent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: textCol,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Present', AppColors.primary),
                        const SizedBox(width: 12),
                        _buildLegendItem('Absent', AppColors.urgent),
                        const SizedBox(width: 12),
                        _buildLegendItem('Late', AppColors.high),
                        const SizedBox(width: 12),
                        _buildLegendItem('Today', AppColors.primaryDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    Color bgIconColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
