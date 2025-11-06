import 'package:flutter/material.dart';
import 'models.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<Task> _tasks = [
    Task(id: '1', title: 'Пункт 1'),
    Task(id: '2', title: 'Пункт 2'),
    Task(id: '3', title: 'Пункт 3'),
    Task(id: '4', title: 'Пункт 4'),
    Task(id: '5', title: 'Пункт 5'),
  ];

  void _toggle(Task t, bool v) => setState(() => t.done = v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задачи')), // без const у AppBar
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 22),
        itemBuilder: (context, i) {
          final t = _tasks[i];
          return Row(
            children: [
              CircleCheckbox(value: t.done, onChanged: (v) => _toggle(t, v)),
              const SizedBox(width: 16),
              Expanded(child: Text(t.title, style: const TextStyle(fontSize: 18))),
            ],
          );
        },
      ),
      // квадратный FAB
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Material(
            color: AppColors.pinkLight.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, '/add').then((v) {
                if (v is Task) setState(() => _tasks.insert(0, v));
              }),
              child: const Center(child: Icon(Icons.add, size: 34, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
