import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';

class TodoCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Determine due status
    String dueText = '';
    Color dueColor = AppColors.textSecondary;
    bool isOverdue = false;

    if (!todo.isCompleted) {
      if (todo.dueDate.isBefore(todayStart)) {
        dueText = 'Overdue';
        dueColor = AppColors.urgent;
        isOverdue = true;
      } else if (todo.dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          todo.dueDate.isBefore(todayEnd.add(const Duration(seconds: 1)))) {
        dueText = 'Due Today';
        dueColor = AppColors.high;
      } else {
        dueText = DateFormat('MMM d').format(todo.dueDate);
      }
    } else {
      dueText = 'Completed';
      dueColor = AppColors.primary;
    }

    final categoryBgColor = AppColors.categoryColors[todo.category] ?? AppColors.categoryColors['Others']!;
    final categoryTextColor = AppColors.categoryTextColors[todo.category] ?? AppColors.categoryTextColors['Others']!;

    return Dismissible(
      key: Key(todo.todoId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.urgent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue ? AppColors.urgent.withOpacity(0.3) : AppColors.border,
              width: isOverdue ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completed Checkbox
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (_) => onToggleComplete(),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: todo.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (todo.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              todo.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: categoryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Due Date
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: dueColor),
                              const SizedBox(width: 4),
                              Text(
                                dueText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: dueColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Priority Badge on the right
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.getPriorityColor(todo.priority).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    todo.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPriorityColor(todo.priority),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
