// lib/models/pet_todo_list.dart
import 'package:flutter/material.dart';

enum PetTaskCategory {
  grooming,
  washing,
  walking,
  doctor,
  feeding,
  medication,
  training
}

enum TaskPriority { low, medium, high }

class PetTask {
  final String id;
  final String title;
  final String description;
  final PetTaskCategory category;
  final DateTime dueDate;
  final TimeOfDay? dueTime;
  final bool isCompleted;
  final TaskPriority priority;
  final String? notes;
  final String? petName;
  final bool isRecurring;
  final int? reminderMinutesBefore;

  PetTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.notes,
    this.petName,
    this.isRecurring = false,
    this.reminderMinutesBefore,
  });

  PetTask copyWith({
    String? id,
    String? title,
    String? description,
    PetTaskCategory? category,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    TaskPriority? priority,
    String? notes,
    String? petName,
    bool? isRecurring,
    int? reminderMinutesBefore,
  }) {
    return PetTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      petName: petName ?? this.petName,
      isRecurring: isRecurring ?? this.isRecurring,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
}

class PetTodoListManager {
  List<PetTask> _tasks = [];

  List<PetTask> get tasks => List.unmodifiable(_tasks);

  List<PetTask> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  List<PetTask> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  void addTask(PetTask task) {
    _tasks.add(task);
    _sortTasks();
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  void updateTask(PetTask updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _sortTasks();
    }
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      _sortTasks();
    }
  }

  List<PetTask> getTasksByCategory(PetTaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  List<PetTask> getUpcomingTasks() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _tasks.where((task) =>
    task.dueDate.isAfter(now) &&
        task.dueDate.isBefore(nextWeek) &&
        !task.isCompleted
    ).toList();
  }

  List<PetTask> getOverdueTasks() {
    final now = DateTime.now();
    return _tasks.where((task) =>
    task.dueDate.isBefore(now) &&
        !task.isCompleted
    ).toList();
  }

  List<PetTask> getDoctorAppointments() {
    return getTasksByCategory(PetTaskCategory.doctor);
  }

  List<PetTask> getGroomingTasks() {
    return getTasksByCategory(PetTaskCategory.grooming);
  }

  List<PetTask> getWashingTasks() {
    return getTasksByCategory(PetTaskCategory.washing);
  }

  List<PetTask> getWalkingTasks() {
    return getTasksByCategory(PetTaskCategory.walking);
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      final dateComparison = a.dueDate.compareTo(b.dueDate);
      if (dateComparison != 0) return dateComparison;

      final priorityOrder = {
        TaskPriority.high: 0,
        TaskPriority.medium: 1,
        TaskPriority.low: 2,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });
  }

  void clearCompletedTasks() {
    _tasks.removeWhere((task) => task.isCompleted);
  }

  Map<String, int> getStatistics() {
    final total = _tasks.length;
    final completed = completedTasks.length;
    final pending = pendingTasks.length;
    final overdue = getOverdueTasks().length;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    };
  }
}

class PetTodoListHelpers {
  static IconData getCategoryIcon(PetTaskCategory category) {
    switch (category) {
      case PetTaskCategory.grooming:
        return Icons.cut;
      case PetTaskCategory.washing:
        return Icons.shower;
      case PetTaskCategory.walking:
        return Icons.directions_walk;
      case PetTaskCategory.doctor:
        return Icons.medical_services;
      case PetTaskCategory.feeding:
        return Icons.restaurant;
      case PetTaskCategory.medication:
        return Icons.medication;
      case PetTaskCategory.training:
        return Icons.school;
      default:
        return Icons.pets;
    }
  }

  static Color getCategoryColor(PetTaskCategory category) {
    switch (category) {
      case PetTaskCategory.grooming:
        return Colors.purple;
      case PetTaskCategory.washing:
        return Colors.blue;
      case PetTaskCategory.walking:
        return Colors.green;
      case PetTaskCategory.doctor:
        return Colors.red;
      case PetTaskCategory.feeding:
        return Colors.orange;
      case PetTaskCategory.medication:
        return Colors.pink;
      case PetTaskCategory.training:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final difference = taskDate.difference(today).inDays;
      if (difference < 7 && difference > 0) {
        return 'In $difference days';
      } else {
        return '${_getMonthAbbreviation(date.month)} ${date.day}, ${date.year}';
      }
    }
  }

  static String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  static String? formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String getCategoryName(PetTaskCategory category) {
    return category.toString().split('.').last;
  }
}