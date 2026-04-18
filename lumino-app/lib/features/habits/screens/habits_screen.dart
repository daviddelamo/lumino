import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../habits_provider.dart';
import '../../../database/database.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Habits',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 26, color: const Color(0xFF3A2A1A))),
                  const SizedBox(height: 2),
                  Text(
                    _todaySummary(habitsAsync.valueOrNull ?? []),
                    style: const TextStyle(fontSize: 13, color: Color(0xFFA08070)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (habits) => habits.isEmpty
                    ? EmptyState(
                        emoji: '✅',
                        title: 'No habits yet',
                        subtitle: 'Add your first habit and start building a streak.',
                        onAction: () => context.push('/habits/add'),
                        actionLabel: 'Add habit',
                      )
                    : _HabitList(habits: habits),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/add'),
        backgroundColor: LuminoTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 1),
    );
  }

  static String _todaySummary(List<Habit> habits) =>
      '${habits.length} habit${habits.length == 1 ? '' : 's'} active';
}

class _HabitList extends ConsumerWidget {
  final List<Habit> habits;
  const _HabitList({required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (_, i) => _HabitCard(habit: habits[i]),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(habit.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.circle, color: color, size: 14),
        ),
        title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${habit.type} · target ${habit.targetValue.toInt()}${habit.unit != null ? ' ${habit.unit}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: () async {
            try {
              await ref
                  .read(habitsNotifierProvider.notifier)
                  .completeToday(habit.id, habit.targetValue);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not log habit: $e')),
                );
              }
            }
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD0B898), width: 2),
            ),
            child: const Icon(Icons.check, size: 16, color: Color(0xFFD0B898)),
          ),
        ),
        onTap: () => context.push('/habits/${habit.id}'),
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
  Widget build(BuildContext context) => BottomNavigationBar(
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
        onTap: (i) {
          if (i == 0) context.go('/today');
          if (i == 2) context.go('/me');
        },
      );
}
