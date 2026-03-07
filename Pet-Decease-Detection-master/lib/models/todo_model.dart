import 'package:flutter/material.dart';

class Todo {
  String title;
  bool isCompleted;
  DateTime date;
  TimeOfDay? time;
  String? description;
  DateTime? reminderTime;

  Todo({
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.time,
    this.description,
    this.reminderTime,
  });

  // Optional: Add copyWith method for easier updates
  Todo copyWith({
    String? title,
    bool? isCompleted,
    DateTime? date,
    TimeOfDay? time,
    String? description,
    DateTime? reminderTime,
  }) {
    return Todo(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      time: time ?? this.time,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}