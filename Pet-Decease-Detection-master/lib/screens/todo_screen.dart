import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../main.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/edit_todo_dialog.dart';
import '../services/appointment_manager.dart';
import '../utils/pet_todo_list.dart';

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
    AppointmentManager.instance.addListener(_onAppointmentsChanged);
  }

  @override
  void dispose() {
    AppointmentManager.instance.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  void _onAppointmentsChanged() {
    if (mounted) setState(() {});
  }

  // Get local todos for a day
  List<Todo> _getTodosForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _todos[normalizedDay] ?? [];
  }

  // Get appointments from AppointmentManager for a day
  List<PetTask> _getAppointmentsForDay(DateTime day) {
    return AppointmentManager.instance.getTasksForDate(day);
  }

  // Combined event count for calendar dots
  List<dynamic> _getAllEventsForDay(DateTime day) {
    final localTodos = _getTodosForDay(day);
    final appointments = _getAppointmentsForDay(day);
    return [...localTodos, ...appointments];
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
      final todo = _todos[oldNormalizedDay]![index];
      _todos[oldNormalizedDay]!.removeAt(index);
      if (_todos[oldNormalizedDay]!.isEmpty) {
        _todos.remove(oldNormalizedDay);
      }

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
    final appointmentsForSelectedDay = _getAppointmentsForDay(_selectedDay);

    // Build combined list: todos first, then appointments
    final List<dynamic> combinedItems = [];

    // Sort local todos by time
    final sortedTodos = List<Todo>.from(todosForSelectedDay)
      ..sort((a, b) {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        if (a.time!.hour != b.time!.hour) return a.time!.hour.compareTo(b.time!.hour);
        return a.time!.minute.compareTo(b.time!.minute);
      });

    combinedItems.addAll(sortedTodos);
    combinedItems.addAll(appointmentsForSelectedDay);

    final totalPending = sortedTodos.where((t) => !t.isCompleted).length +
        appointmentsForSelectedDay.where((a) => !a.isCompleted).length;
    final totalCompleted = sortedTodos.where((t) => t.isCompleted).length +
        appointmentsForSelectedDay.where((a) => a.isCompleted).length;

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
            eventLoader: _getAllEventsForDay,
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
                      '$totalPending pending, $totalCompleted completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (combinedItems.isNotEmpty)
                  Chip(
                    label: Text('${combinedItems.length} tasks'),
                    backgroundColor: Colors.teal.withOpacity(0.1),
                  ),
              ],
            ),
          ),
          Expanded(
            child: combinedItems.isEmpty
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
              itemCount: combinedItems.length,
              itemBuilder: (context, index) {
                final item = combinedItems[index];

                // Render PetTask (appointment) items
                if (item is PetTask) {
                  return _buildAppointmentCard(item);
                }

                // Render regular Todo items
                final todo = item as Todo;
                return _buildTodoCard(todo, todosForSelectedDay);
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

  Widget _buildAppointmentCard(PetTask appt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.red.shade100, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: appt.isCompleted ? Colors.green.shade50 : Colors.red.shade50,
          radius: 18,
          child: Icon(
            appt.isCompleted ? Icons.check_circle : Icons.medical_services,
            color: appt.isCompleted ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                appt.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  decoration: appt.isCompleted ? TextDecoration.lineThrough : null,
                  color: appt.isCompleted ? Colors.grey : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Vet',
                style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appt.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  appt.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (appt.dueTime != null) ...[
                  Icon(Icons.access_time, size: 13, color: Colors.red.shade300),
                  const SizedBox(width: 3),
                  Text(
                    PetTodoListHelpers.formatTime(appt.dueTime) ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 10),
                ],
                if (appt.petName != null) ...[
                  Icon(Icons.pets, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(
                    appt.petName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Checkbox(
          value: appt.isCompleted,
          onChanged: (_) {
            AppointmentManager.instance.toggleTaskCompletion(appt.id);
          },
          activeColor: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildTodoCard(Todo todo, List<Todo> todosForSelectedDay) {
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
  }
}
