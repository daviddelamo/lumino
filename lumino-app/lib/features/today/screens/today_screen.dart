import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../tasks_provider.dart';
import '../task_form_sheet.dart';
import '../../../shared/widgets/lumino_icon.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_card.dart';
import '../../../shared/widgets/lumino_nav_bar.dart';
import '../../../theme.dart';
import '../../../database/database.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tasksAsync = ref.watch(tasksNotifierProvider(today));

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TodayHeader(date: today, tasksAsync: tasksAsync),
            Expanded(
              child: tasksAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: 3,
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) => tasks.isEmpty
                    ? EmptyState(
                        emoji: '✨',
                        title: 'A fresh start',
                        subtitle: 'Add your first task for today.',
                        onAction: () => _showAddTask(context, ref, today),
                        actionLabel: 'Add task',
                      )
                    : _TaskGroups(tasks: tasks, date: today),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context, ref, today),
        backgroundColor: LuminoTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const LuminoNavBar(currentIndex: 0),
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
    final total = tasks.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(date),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _greeting(date.hour),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/today/week'),
                    child: ProgressRing(
                      completed: completed,
                      total: total,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 ? 'No tasks' : '$completed/$total',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          if (total > 0 && completed == total) ...[
            const SizedBox(height: 8),
            Text(
              'All done — great work today.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LuminoTheme.primaryColor),
            ),
          ],
        ],
      ),
    );
  }

  static String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

enum _TimeBlock { morning, afternoon, evening }

extension _TimeBlockExt on _TimeBlock {
  String get label {
    switch (this) {
      case _TimeBlock.morning:
        return 'Morning';
      case _TimeBlock.afternoon:
        return 'Afternoon';
      case _TimeBlock.evening:
        return 'Evening';
    }
  }

  IconData get icon {
    switch (this) {
      case _TimeBlock.morning:
        return Icons.wb_sunny_outlined;
      case _TimeBlock.afternoon:
        return Icons.wb_cloudy_outlined;
      case _TimeBlock.evening:
        return Icons.nights_stay_outlined;
    }
  }

  static _TimeBlock forHour(int hour) {
    if (hour < 12) return _TimeBlock.morning;
    if (hour < 17) return _TimeBlock.afternoon;
    return _TimeBlock.evening;
  }
}

class _TaskGroups extends StatelessWidget {
  final List<Task> tasks;
  final DateTime date;

  const _TaskGroups({required this.tasks, required this.date});

  @override
  Widget build(BuildContext context) {
    final grouped = <_TimeBlock, List<Task>>{};
    for (final task in tasks) {
      final block = _TimeBlockExt.forHour(task.startAt.hour);
      grouped.putIfAbsent(block, () => []).add(task);
    }

    final sections = <Widget>[];
    for (final block in _TimeBlock.values) {
      final blockTasks = grouped[block];
      if (blockTasks == null || blockTasks.isEmpty) continue;
      sections.add(_TimeBlockSection(block: block, tasks: blockTasks, date: date));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: sections,
    );
  }
}

class _TimeBlockSection extends StatelessWidget {
  final _TimeBlock block;
  final List<Task> tasks;
  final DateTime date;

  const _TimeBlockSection({
    required this.block,
    required this.tasks,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(block.icon, size: 14, color: LuminoTheme.textSecondary(context)),
            const SizedBox(width: 6),
            Text(
              block.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...tasks.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskCard(task: t, date: date),
            )),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;
  final DateTime date;

  const _TaskCard({required this.task, required this.date});

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }

  static String _durationLabel(Task task) {
    final time = DateFormat('HH:mm').format(task.startAt);
    final end = task.endAt;
    if (end != null) {
      final diffMin = end.difference(task.startAt).inMinutes;
      if (diffMin > 0) return '$time · ${diffMin}m';
    }
    return time;
  }

  void _openEdit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFormSheet(
        date: date,
        existing: task,
        onSaved: () => ref.read(tasksNotifierProvider(date).notifier).reload(),
      ),
    );
  }

  void _toggle(WidgetRef ref) {
    if (task.completedAt != null) {
      ref.read(tasksNotifierProvider(date).notifier).uncompleteTask(task.id);
    } else {
      ref.read(tasksNotifierProvider(date).notifier).completeTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = task.completedAt != null;
    final color = _parseColor(task.color);

    return AnimatedOpacity(
      opacity: isDone ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: LuminoTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEdit(context, ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                // Icon in rounded square with color tint
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: LuminoIcon(task.iconId, size: 20, color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              decorationColor:
                                  LuminoTheme.textSecondary(context),
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _durationLabel(task),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? color : Colors.transparent,
                      border: Border.all(
                        color: isDone ? color : color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
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
