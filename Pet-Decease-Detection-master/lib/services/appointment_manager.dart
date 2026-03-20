import 'package:flutter/material.dart';
import '../utils/pet_todo_list.dart';

class AppointmentManager extends ChangeNotifier {
  AppointmentManager._internal();
  static final AppointmentManager instance = AppointmentManager._internal();

  final PetTodoListManager _manager = PetTodoListManager();

  List<PetTask> get tasks => _manager.tasks;

  List<PetTask> getDoctorAppointments() => _manager.getDoctorAppointments();

  List<PetTask> getTasksByCategory(PetTaskCategory category) =>
      _manager.getTasksByCategory(category);

  Map<String, int> getStatistics() => _manager.getStatistics();

  List<PetTask> getTasksForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _manager.tasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate == normalized;
    }).toList();
  }

  void addTask(PetTask task) {
    _manager.addTask(task);
    notifyListeners();
  }

  void removeTask(String taskId) {
    _manager.removeTask(taskId);
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    _manager.toggleTaskCompletion(taskId);
    notifyListeners();
  }

  void updateTask(PetTask task) {
    _manager.updateTask(task);
    notifyListeners();
  }
}
