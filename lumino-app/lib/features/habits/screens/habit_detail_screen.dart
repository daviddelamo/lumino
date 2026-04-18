import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database.dart';
import '../../../features/today/tasks_provider.dart';
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
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final thisMonthEntries =
        _entries.where((e) => !e.entryDate.isBefore(monthStart)).length;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final completionPct = (thisMonthEntries / daysInMonth * 100).round();

    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      appBar: AppBar(
        backgroundColor: LuminoTheme.backgroundWarm,
        title: Text(h.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatBox(value: '$streak', label: 'Streak'),
                const SizedBox(width: 10),
                _StatBox(value: '${longestStreak(entryDates)}', label: 'Best'),
                const SizedBox(width: 10),
                _StatBox(value: '$completionPct%', label: 'This month'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Last 30 days',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA08070),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _Heatmap(entries: _entries),
            const SizedBox(height: 24),
            const Text('Recent entries',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA08070),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._entries.take(10).map((e) => ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: LuminoTheme.primaryColor, radius: 5),
                  title: Text(
                    '${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Text(
                    '${e.value.toInt()}${h.unit != null ? ' ${h.unit}' : ''}  \u2713',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFA08070)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8823A),
                        fontFamily: 'Georgia')),
                Text(label,
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFFA08070))),
              ],
            ),
          ),
        ),
      );
}

class _Heatmap extends StatelessWidget {
  final List<HabitEntry> entries;
  const _Heatmap({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entrySet = entries.map((e) {
      final d = e.entryDate;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    return GridView.count(
      crossAxisCount: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      children: List.generate(30, (i) {
        final day = now.subtract(Duration(days: 29 - i));
        final norm = DateTime(day.year, day.month, day.day);
        final done = entrySet.contains(norm);
        return Container(
          decoration: BoxDecoration(
            color: done ? LuminoTheme.primaryColor : const Color(0xFFF0E0D0),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
