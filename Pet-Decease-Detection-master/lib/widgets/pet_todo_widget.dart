import 'package:flutter/material.dart';
import '../screens/todo_screen.dart';
import '../utils/pet_todo_list.dart';
import 'pet_todo_list.dart';

class PetTodoWidget extends StatefulWidget {
  @override
  _PetTodoWidgetState createState() => _PetTodoWidgetState();
}

class _PetTodoWidgetState extends State<PetTodoWidget> {
  final PetTodoListManager _todoManager = PetTodoListManager();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Sample initial tasks
  @override
  void initState() {
    super.initState();
    _initializeSampleTasks();
  }

  void _initializeSampleTasks() {
    final tasks = [
      PetTask(
        id: '1',
        title: 'Grooming Session',
        description: 'Brush fur and trim nails',
        category: PetTaskCategory.grooming,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        dueTime: const TimeOfDay(hour: 10, minute: 30),
        petName: 'Max',
        priority: TaskPriority.medium,
        notes: 'Use the new brush we bought',
      ),
      PetTask(
        id: '2',
        title: 'Vet Checkup',
        description: 'Annual vaccination and checkup',
        category: PetTaskCategory.doctor,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        dueTime: const TimeOfDay(hour: 14, minute: 0),
        petName: 'Bella',
        priority: TaskPriority.high,
        notes: 'Bring medical records',
      ),
      PetTask(
        id: '3',
        title: 'Evening Walk',
        description: '30 minutes walk in the park',
        category: PetTaskCategory.walking,
        dueDate: DateTime.now(),
        dueTime: const TimeOfDay(hour: 18, minute: 0),
        petName: 'Charlie',
        priority: TaskPriority.medium,
        isRecurring: true,
      ),
      PetTask(
        id: '4',
        title: 'Bath Time',
        description: 'Give bath with special shampoo',
        category: PetTaskCategory.washing,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        petName: 'Lucy',
        priority: TaskPriority.low,
        notes: 'Use anti-flea shampoo',
      ),
    ];

    for (var task in tasks) {
      _todoManager.addTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _todoManager.getStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics card
          _buildStatisticsCard(stats),

          // Category tabs
          _buildCategoryTabs(),

          // Task list
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, int> stats) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', stats['total']?.toString() ?? '0'),
            _buildStatItem('Pending', stats['pending']?.toString() ?? '0'),
            _buildStatItem('Overdue', stats['overdue']?.toString() ?? '0'),
            _buildStatItem('Done', stats['completed']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryTab('All', null),
          _buildCategoryTab('Grooming', PetTaskCategory.grooming),
          _buildCategoryTab('Washing', PetTaskCategory.washing),
          _buildCategoryTab('Walking', PetTaskCategory.walking),
          _buildCategoryTab('Doctor', PetTaskCategory.doctor),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, PetTaskCategory? category) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () {
          // Implement category filtering
        },
        child: Text(label),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _todoManager.tasks;

    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet!\nAdd your first pet care task.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(task);
      },
    );
  }

  Widget _buildTaskItem(PetTask task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          PetTodoListHelpers.getCategoryIcon(task.category),
          color: PetTodoListHelpers.getCategoryColor(task.category),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            if (task.petName != null)
              Chip(
                label: Text(task.petName!),
                backgroundColor: Colors.blue[50],
              ),
            Row(
              children: [
                Text(PetTodoListHelpers.formatDate(task.dueDate)),
                if (task.dueTime != null)
                  Text(
                    ' • ${PetTodoListHelpers.formatTime(task.dueTime)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              color: PetTodoListHelpers.getPriorityColor(task.priority),
              size: 12,
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                setState(() {
                  _todoManager.toggleTaskCompletion(task.id);
                });
              },
            ),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTask = PetTask(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _titleController.text,
                  description: _descriptionController.text,
                  category: PetTaskCategory.grooming,
                  dueDate: DateTime.now().add(const Duration(days: 1)),
                );

                setState(() {
                  _todoManager.addTask(newTask);
                  _titleController.clear();
                  _descriptionController.clear();
                });

                Navigator.pop(context);
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(PetTask task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                PetTodoListHelpers.getCategoryIcon(task.category),
                color: PetTodoListHelpers.getCategoryColor(task.category),
              ),
              const SizedBox(width: 8),
              Text(task.title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (task.petName != null)
                Text('Pet: ${task.petName}'),
              Text('Date: ${PetTodoListHelpers.formatDate(task.dueDate)}'),
              if (task.dueTime != null)
                Text('Time: ${PetTodoListHelpers.formatTime(task.dueTime)}'),
              if (task.notes != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(task.notes!),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}