import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../habits_provider.dart';
import '../../../shared/widgets/lumino_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_card.dart';
import '../../../shared/widgets/lumino_nav_bar.dart';
import '../../../theme.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final habits = habitsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HabitsHeader(habits: habits),
            Expanded(
              child: habitsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: 3,
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (items) => items.isEmpty
                    ? EmptyState(
                        emoji: '🌱',
                        title: 'No habits yet',
                        subtitle: 'Add your first habit and start building a streak.',
                        onAction: () => context.push('/habits/add'),
                        actionLabel: 'Add habit',
                      )
                    : _HabitList(habits: items),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/add'),
        backgroundColor: LuminoTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const LuminoNavBar(currentIndex: 1),
    );
  }
}

class _HabitsHeader extends StatelessWidget {
  final List<HabitWithStatus> habits;
  const _HabitsHeader({required this.habits});

  @override
  Widget build(BuildContext context) {
    final done = habits.where((h) => h.completedToday).length;
    final total = habits.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Habit Journey', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Add your first habit below'
                : '${_todayLabel()} · $done/$total habits done',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  static String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _HabitList extends StatelessWidget {
  final List<HabitWithStatus> habits;
  const _HabitList({required this.habits});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      itemCount: habits.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _HabitCard(item: habits[i]),
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitWithStatus item;
  const _HabitCard({required this.item});

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = item.habit;
    final done = item.completedToday;
    final streak = item.streak;
    final color = _parseColor(habit.color);

    return Material(
      // Per-habit tonal background: very subtle color tint
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/habits/${habit.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon in rounded square with color tint
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: LuminoIcon(habit.iconId, size: 20, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${habit.type} · target ${habit.targetValue.toInt()}${habit.unit != null ? ' ${habit.unit}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Completion toggle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      try {
                        final notifier = ref.read(habitsNotifierProvider.notifier);
                        if (done) {
                          await notifier.uncompleteToday(habit.id);
                        } else {
                          await notifier.completeToday(habit.id, habit.targetValue);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not update habit: $e')),
                          );
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? color : Colors.transparent,
                        border: Border.all(
                          color: done ? color : color.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check, size: 15, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
              if (streak > 0) ...[
                const SizedBox(height: 12),
                _StreakRow(streak: streak, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final int streak;
  final Color color;
  const _StreakRow({required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.local_fire_department, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$streak day streak',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
