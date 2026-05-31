import 'package:flutter/material.dart';

class AppColors {
  // Theme Palette
  static const Color primary = Color(0xFF5E8566); // Sage Green
  static const Color primaryLight = Color(0xFF8CAF94);
  static const Color primaryDark = Color(0xFF3B5241);
  static const Color background = Color(0xFFF3F7F4); // Soft pastel background
  static const Color surface = Color(0xFFFFFFFF); // Clean cards
  static const Color textPrimary = Color(0xFF2C3E30); // Slate Text
  static const Color textSecondary = Color(0xFF758A7A); // Subdued Text
  static const Color border = Color(0xFFE1E8E3);

  // Status & Priority Colors
  static const Color urgent = Color(0xFFE57373); // Soft Coral
  static const Color high = Color(0xFFFFB74D); // Soft Amber
  static const Color medium = Color(0xFF64B5F6); // Soft Blue
  static const Color low = Color(0xFFB0BEC5); // Soft Slate/Grey

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Activity': Color(0xFFE8F5E9),
    'Quiz': Color(0xFFFFF3E0),
    'Assignment': Color(0xFFE3F2FD),
    'Project': Color(0xFFF3E5F5),
    'Exam': Color(0xFFFFEBEE),
    'Personal': Color(0xFFE8EAF6),
    'Others': Color(0xFFECEFF1),
  };

  static const Map<String, Color> categoryTextColors = {
    'Activity': Color(0xFF2E7D32),
    'Quiz': Color(0xFFEF6C00),
    'Assignment': Color(0xFF1565C0),
    'Project': Color(0xFF6A1B9A),
    'Exam': Color(0xFFC62828),
    'Personal': Color(0xFF283593),
    'Others': Color(0xFF37474F),
  };

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return urgent;
      case 'High':
        return high;
      case 'Medium':
        return medium;
      case 'Low':
      default:
        return low;
    }
  }
}

class AppConstants {
  static const List<String> categories = [
    'Activity',
    'Quiz',
    'Assignment',
    'Project',
    'Exam',
    'Personal',
    'Others',
  ];

  static const List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  static const List<String> roles = [
    'Student',
    'Teacher',
    'Guest',
  ];
}
