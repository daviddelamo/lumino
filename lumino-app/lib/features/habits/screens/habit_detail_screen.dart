import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../database/database.dart';
import '../../../features/today/tasks_provider.dart';
import '../../../shared/widgets/lumino_icon.dart';
import '../habits_provider.dart';
import '../../../theme.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  List<HabitEntry> _entries = [];
  Habit? _habit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final userId = ref.read(currentUserIdProvider) ?? 'local';
    final habits = await db.habitDao.getActiveHabits(userId);
    final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
    final entries = await db.habitDao.getAllEntries(widget.habitId);
    if (mounted) {
      setState(() {
        _habit = habit;
        _entries = entries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_habit == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final h = _habit!;
    final entryDates = _entries.map((e) => e.entryDate).toList();
    final streak = computeStreak(entryDates);
    final longest = longestStreak(entryDates);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final thisMonthEntries =
        _entries.where((e) => !e.entryDate.isBefore(monthStart)).length;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final completionPct = (thisMonthEntries / daysInMonth * 100).round();

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        backgroundColor: LuminoTheme.bg(context),
        title: Text(h.title, style: Theme.of(context).textTheme.titleLarge),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsStrip(
              streak: streak,
              longest: longest,
              completionPct: completionPct,
            ),
            const SizedBox(height: 32),
            Text(
              'Last 30 days',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _Heatmap(entries: _entries),
            const SizedBox(height: 32),
            if (_entries.isNotEmpty) ...[
              Text(
                'Recent entries',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ..._entries.take(10).map((e) => _EntryRow(entry: e, habit: h)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final int streak;
  final int longest;
  final int completionPct;

  const _StatsStrip({
    required this.streak,
    required this.longest,
    required this.completionPct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(value: '$streak', label: 'Streak'),
        _VerticalDivider(),
        _Stat(value: '$longest', label: 'Best'),
        _VerticalDivider(),
        _Stat(value: '$completionPct%', label: 'This month'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: LuminoTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: LuminoTheme.divider(context),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _EntryRow extends StatelessWidget {
  final HabitEntry entry;
  final Habit habit;
  const _EntryRow({required this.entry, required this.habit});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEE, MMM d').format(entry.entryDate);
    final value =
        '${entry.value.toInt()}${habit.unit != null ? ' ${habit.unit}' : ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          LuminoIcon(habit.iconId,
              size: 16, color: LuminoTheme.textSecondary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text('$value  ✓', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final List<HabitEntry> entries;
  const _Heatmap({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entrySet = entries.map((e) {
      final d = e.entryDate;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    return GridView.count(
      crossAxisCount: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: List.generate(30, (i) {
        final day = now.subtract(Duration(days: 29 - i));
        final norm = DateTime(day.year, day.month, day.day);
        final done = entrySet.contains(norm);
        final isToday = norm == today;
        return Tooltip(
          message: DateFormat('MMM d').format(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: done ? LuminoTheme.primaryColor : LuminoTheme.divider(context),
              borderRadius: BorderRadius.circular(4),
              border: isToday
                  ? Border.all(color: LuminoTheme.primaryColor, width: 1.5)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
