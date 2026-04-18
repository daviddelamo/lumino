import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../tasks_provider.dart';
import '../task_form_sheet.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme.dart';
import '../../../database/database.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final tasksAsync = ref.watch(tasksNotifierProvider(today));

    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TodayHeader(date: today, tasksAsync: tasksAsync),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) => tasks.isEmpty
                    ? EmptyState(
                        emoji: '✨',
                        title: 'A fresh start',
                        subtitle: 'Add your first task for today.',
                        onAction: () => _showAddTask(context, ref, today),
                        actionLabel: 'Add task',
                      )
                    : _Timeline(tasks: tasks, date: today, ref: ref),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context, ref, today),
        backgroundColor: LuminoTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }

  void _showAddTask(BuildContext context, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFormSheet(
        date: date,
        onSaved: () => ref.read(tasksNotifierProvider(date).notifier).reload(),
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final DateTime date;
  final AsyncValue<List<Task>> tasksAsync;

  const _TodayHeader({required this.date, required this.tasksAsync});

  @override
  Widget build(BuildContext context) {
    final tasks = tasksAsync.valueOrNull ?? [];
    final completed = tasks.where((t) => t.completedAt != null).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(
                      color: Color(0xFFA08070), fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  _greeting(date.hour),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 22, color: const Color(0xFF3A2A1A)),
                ),
              ],
            ),
          ),
          ProgressRing(completed: completed, total: tasks.length, size: 48),
        ],
      ),
    );
  }

  static String _greeting(int hour) {
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

class _Timeline extends StatelessWidget {
  final List<Task> tasks;
  final DateTime date;
  final WidgetRef ref;

  const _Timeline({required this.tasks, required this.date, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, i) => _TaskCard(task: tasks[i], date: date, ref: ref),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final DateTime date;
  final WidgetRef ref;

  const _TaskCard({required this.task, required this.date, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDone = task.completedAt != null;
    final color = _parseColor(task.color);
    return Opacity(
      opacity: isDone ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.circle, color: color, size: 14),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: isDone ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(DateFormat('HH:mm').format(task.startAt)),
          trailing: GestureDetector(
            onTap: () {
              if (!isDone) {
                ref.read(tasksNotifierProvider(date).notifier).completeTask(task.id);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? LuminoTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isDone ? LuminoTheme.primaryColor : const Color(0xFFD0B898),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
      ],
      onTap: (i) {
        if (i == 1) context.go('/habits');
        if (i == 2) context.go('/me');
      },
    );
  }
}
