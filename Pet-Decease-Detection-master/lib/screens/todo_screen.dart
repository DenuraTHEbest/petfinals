import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../main.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/edit_todo_dialog.dart';
import 'package:pet_care_app/models/todo_model.dart' hide Todo;
import 'package:pet_care_app/widgets/edit_todo_dialog.dart';
import 'package:pet_care_app/widgets/add_todo_dialog.dart'; // Optional if you create this

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final Map<DateTime, List<Todo>> _todos = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _focusedDay = _selectedDay;
  }

  List<Todo> _getTodosForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _todos[normalizedDay] ?? [];
  }

  void _addTodo(String title, String? description, DateTime date, TimeOfDay? time) {
    final normalizedDay = DateTime(date.year, date.month, date.day);

    setState(() {
      if (_todos[normalizedDay] == null) {
        _todos[normalizedDay] = [];
      }
      _todos[normalizedDay]!.add(
        Todo(
          title: title,
          date: normalizedDay,
          time: time,
          description: description,
        ),
      );
    });
  }

  void _updateTodo(int index, String title, String? description, DateTime date, TimeOfDay? time) {
    final oldNormalizedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final newNormalizedDay = DateTime(date.year, date.month, date.day);

    setState(() {
      // Remove from old date
      final todo = _todos[oldNormalizedDay]![index];
      _todos[oldNormalizedDay]!.removeAt(index);
      if (_todos[oldNormalizedDay]!.isEmpty) {
        _todos.remove(oldNormalizedDay);
      }

      // Add to new date with updated info
      if (_todos[newNormalizedDay] == null) {
        _todos[newNormalizedDay] = [];
      }
      _todos[newNormalizedDay]!.add(
        Todo(
          title: title,
          date: newNormalizedDay,
          time: time,
          description: description,
          isCompleted: todo.isCompleted,
        ),
      );
    });
  }

  void _toggleTodo(int index) {
    final normalizedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    setState(() {
      _todos[normalizedDay]![index].isCompleted =
      !_todos[normalizedDay]![index].isCompleted;
    });
  }

  void _deleteTodo(int index) {
    final normalizedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    setState(() {
      _todos[normalizedDay]!.removeAt(index);
      if (_todos[normalizedDay]!.isEmpty) {
        _todos.remove(normalizedDay);
      }
    });
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        initialDate: _selectedDay,
        onAdd: _addTodo,
      ),
    );
  }

  void _showEditTodoDialog(int index) {
    final normalizedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final todo = _todos[normalizedDay]![index];

    showDialog(
      context: context,
      builder: (context) => EditTodoDialog(
        todo: todo,
        index: index,
        selectedDay: normalizedDay,
        onUpdate: _updateTodo,
        onDelete: _deleteTodo,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final todosForSelectedDay = _getTodosForDay(_selectedDay);

    // Sort todos by time
    final sortedTodos = List.from(todosForSelectedDay)
      ..sort((a, b) {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        final aHour = a.time!.hour;
        final bHour = b.time!.hour;
        final aMinute = a.time!.minute;
        final bMinute = b.time!.minute;
        if (aHour != bHour) return aHour.compareTo(bHour);
        return aMinute.compareTo(bMinute);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do & Reminders'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getTodosForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markerSize: 6,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(_selectedDay),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${sortedTodos.where((todo) => !todo.isCompleted).length} pending, ${sortedTodos.where((todo) => todo.isCompleted).length} completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (sortedTodos.isNotEmpty)
                  Chip(
                    label: Text('${sortedTodos.length} tasks'),
                    backgroundColor: Colors.teal.withOpacity(0.1),
                  ),
              ],
            ),
          ),
          Expanded(
            child: sortedTodos.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks for this day',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a new task',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedTodos.length,
              itemBuilder: (context, index) {
                final todo = sortedTodos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) => _toggleTodo(
                        todosForSelectedDay.indexOf(todo),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted ? Colors.grey : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (todo.description != null && todo.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              todo.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: todo.isCompleted ? Colors.grey : Colors.grey[700],
                              ),
                            ),
                          ),
                        if (todo.time != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                size: 14,
                                color: todo.isCompleted
                                    ? Colors.grey
                                    : Colors.teal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                todo.time!.format(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: todo.isCompleted
                                      ? Colors.grey
                                      : Colors.teal,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: todo.isCompleted ? Colors.grey : null,
                          ),
                          onPressed: todo.isCompleted
                              ? null
                              : () => _showEditTodoDialog(
                            todosForSelectedDay.indexOf(todo),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteTodo(
                            todosForSelectedDay.indexOf(todo),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!todo.isCompleted) {
                        _showEditTodoDialog(
                          todosForSelectedDay.indexOf(todo),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}