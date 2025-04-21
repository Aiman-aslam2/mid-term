import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TaskManagementApp());
}

class TaskManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: TaskHomePage(),
    );
  }
}

class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  bool isRepeating;
  List<int> repeatDays; // 1-7 for Monday-Sunday
  List<Subtask> subtasks;

  Task({
    required this.title,
    this.description = '',
    DateTime? dueDate,
    this.isCompleted = false,
    this.isRepeating = false,
    this.repeatDays = const [],
    List<Subtask>? subtasks,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        dueDate = dueDate ?? DateTime.now(),
        subtasks = subtasks ?? [];

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return completedCount / subtasks.length;
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isRepeating,
    List<int>? repeatDays,
    List<Subtask>? subtasks,
  }) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatDays: repeatDays ?? this.repeatDays,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}

class Subtask {
  String title;
  bool isCompleted;

  Subtask({required this.title, this.isCompleted = false});
}

class TaskHomePage extends StatefulWidget {
  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  List<Task> tasks = [];
  int _currentIndex = 0;
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayTasks = tasks.where((task) {
      return !task.isCompleted &&
          (task.dueDate.year == now.year &&
              task.dueDate.month == now.month &&
              task.dueDate.day == now.day);
    }).toList();

    final completedTasks = tasks.where((task) => task.isCompleted).toList();

    final repeatingTasks = tasks.where((task) => task.isRepeating).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Management'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TaskListView(
            tasks: todayTasks,
            emptyMessage: 'No tasks for today!',
            onTaskTapped: _showTaskDetails,
          ),
          TaskListView(
            tasks: completedTasks,
            emptyMessage: 'No completed tasks yet!',
            onTaskTapped: _showTaskDetails,
          ),
          TaskListView(
            tasks: repeatingTasks,
            emptyMessage: 'No repeating tasks!',
            onTaskTapped: _showTaskDetails,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.done_all),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Repeating',
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime dueDate = DateTime.now();
    bool isRepeating = false;
    List<int> repeatDays = [];
    final subtaskControllers = <TextEditingController>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title*'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Due Date: '),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() => dueDate = pickedDate);
                            }
                          },
                          child: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      title: Text('Repeating Task'),
                      value: isRepeating,
                      onChanged: (value) => setState(() => isRepeating = value!),
                    ),
                    if (isRepeating) ...[
                      Text('Repeat on:'),
                      Wrap(
                        children: List.generate(7, (index) {
                          final dayName = DateFormat.E().format(DateTime(2023, 1, index + 2));
                          return FilterChip(
                            label: Text(dayName),
                            selected: repeatDays.contains(index + 1),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  repeatDays.add(index + 1);
                                } else {
                                  repeatDays.remove(index + 1);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    SizedBox(height: 10),
                    Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...subtaskControllers.map((controller) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(hintText: 'Subtask'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                subtaskControllers.remove(controller);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          subtaskControllers.add(TextEditingController());
                        });
                      },
                      child: Text('Add Subtask'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;
                    
                    final subtasks = subtaskControllers
                        .where((c) => c.text.isNotEmpty)
                        .map((c) => Subtask(title: c.text))
                        .toList();
                    
                    final newTask = Task(
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: dueDate,
                      isRepeating: isRepeating,
                      repeatDays: repeatDays,
                      subtasks: subtasks,
                    );
                    
                    setState(() {
                      tasks.add(newTask);
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskDetails(Task task) {
    final taskIndex = tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(task.title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(task.description),
                    SizedBox(height: 10),
                    Text('Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}'),
                    if (task.isRepeating) ...[
                      SizedBox(height: 5),
                      Text('Repeats on: ${task.repeatDays.map((d) => DateFormat.E().format(DateTime(2023, 1, d + 1))).join(', ')}'),
                    ],
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: task.progress,
                      minHeight: 10,
                    ),
                    Text('${(task.progress * 100).toStringAsFixed(0)}% complete'),
                    SizedBox(height: 10),
                    if (task.subtasks.isNotEmpty) ...[
                      Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...task.subtasks.map((subtask) {
                        final subtaskIndex = task.subtasks.indexOf(subtask);
                        return CheckboxListTile(
                          title: Text(subtask.title),
                          value: subtask.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              task.subtasks[subtaskIndex].isCompleted = value!;
                              tasks[taskIndex] = task.copyWith(subtasks: task.subtasks);
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      tasks[taskIndex] = task.copyWith(isCompleted: !task.isCompleted);
                    });
                    Navigator.pop(context);
                  },
                  child: Text(task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                ),
                TextButton(
                  onPressed: () => _showEditTaskDialog(task, taskIndex),
                  child: Text('Edit'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      tasks.removeAt(taskIndex);
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(Task task, int taskIndex) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime dueDate = task.dueDate;
    bool isRepeating = task.isRepeating;
    List<int> repeatDays = List.from(task.repeatDays);
    final subtaskControllers = task.subtasks.map((s) => TextEditingController(text: s.title)).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title*'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Due Date: '),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() => dueDate = pickedDate);
                            }
                          },
                          child: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      title: Text('Repeating Task'),
                      value: isRepeating,
                      onChanged: (value) => setState(() => isRepeating = value!),
                    ),
                    if (isRepeating) ...[
                      Text('Repeat on:'),
                      Wrap(
                        children: List.generate(7, (index) {
                          final dayName = DateFormat.E().format(DateTime(2023, 1, index + 2));
                          return FilterChip(
                            label: Text(dayName),
                            selected: repeatDays.contains(index + 1),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  repeatDays.add(index + 1);
                                } else {
                                  repeatDays.remove(index + 1);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    SizedBox(height: 10),
                    Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...subtaskControllers.map((controller) {
                      final subtaskIndex = subtaskControllers.indexOf(controller);
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(hintText: 'Subtask'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                subtaskControllers.removeAt(subtaskIndex);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          subtaskControllers.add(TextEditingController());
                        });
                      },
                      child: Text('Add Subtask'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;
                    
                    final subtasks = subtaskControllers
                        .where((c) => c.text.isNotEmpty)
                        .map((c) => Subtask(title: c.text))
                        .toList();
                    
                    final updatedTask = task.copyWith(
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: dueDate,
                      isRepeating: isRepeating,
                      repeatDays: repeatDays,
                      subtasks: subtasks,
                    );
                    
                    setState(() {
                      tasks[taskIndex] = updatedTask;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final String emptyMessage;
  final Function(Task) onTaskTapped;

  const TaskListView({
    required this.tasks,
    required this.emptyMessage,
    required this.onTaskTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(emptyMessage),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(task.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) Text(task.description),
                Text('Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}'),
                if (task.subtasks.isNotEmpty) ...[
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 6,
                  ),
                ],
              ],
            ),
            trailing: Checkbox(
              value: task.isCompleted,
              onChanged: (value) => onTaskTapped(task),
            ),
            onTap: () => onTaskTapped(task),
          ),
        );
      },
    );
  }
}