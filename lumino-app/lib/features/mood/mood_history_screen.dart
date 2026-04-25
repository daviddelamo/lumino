import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';
import '../../shared/widgets/lumino_nav_bar.dart';
import '../../theme.dart';
import 'mood_provider.dart';

const _moodColors = [
  Color(0xFFE05C5C),
  Color(0xFFE8913A),
  Color(0xFFE8C23A),
  Color(0xFF8BC48A),
  Color(0xFF52B788),
];

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() => setState(() {
        if (_month == 1) {
          _year--;
          _month = 12;
        } else {
          _month--;
        }
      });

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      if (_month == 12) {
        _year++;
        _month = 1;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && _month == now.month;
    final monthEntries = ref.watch(moodEntriesForMonthProvider((_year, _month)));
    final last14Entries = ref.watch(moodEntriesLast14Provider);

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        title: Text('Mood History',
            style: Theme.of(context).textTheme.headlineSmall),
        iconTheme: IconThemeData(color: LuminoTheme.textPrimary(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(
              year: _year,
              month: _month,
              isCurrentMonth: isCurrentMonth,
              onPrev: _prevMonth,
              onNext: _nextMonth,
            ),
            const SizedBox(height: 16),
            monthEntries.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entries) =>
                  _MonthCalendar(year: _year, month: _month, entries: entries),
            ),
            const SizedBox(height: 8),
            const _ColorLegend(),
            const SizedBox(height: 24),
            Text(
              'LAST 14 DAYS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: LuminoTheme.textSecondary(context),
                  ),
            ),
            const SizedBox(height: 12),
            last14Entries.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entries) => _TrendChart(entries: entries),
            ),
            const SizedBox(height: 24),
            monthEntries.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (entries) =>
                  _StatsRow(entries: entries, year: _year, month: _month),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LuminoNavBar(currentIndex: 0),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final int year;
  final int month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          color: LuminoTheme.textPrimary(context),
        ),
        Text(
          DateFormat('MMMM yyyy').format(DateTime(year, month)),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : onNext,
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentMonth
                ? LuminoTheme.textSecondary(context)
                : LuminoTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final int year;
  final int month;
  final List<MoodEntry> entries;

  const _MonthCalendar({
    required this.year,
    required this.month,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final byDay = <int, List<int>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.loggedAt.day, () => []).add(e.moodLevel);
    }
    final avgByDay = byDay.map((day, levels) {
      final avg = levels.reduce((a, b) => a + b) / levels.length;
      return MapEntry(day, avg.round().clamp(1, 5));
    });

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = DateTime(year, month, 1).weekday - 1; // Mon=0
    final today = DateTime.now();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          children: dayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: LuminoTheme.textSecondary(context),
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.4,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final day = index - offset + 1;
            final cellDate = DateTime(year, month, day);
            final isFuture = cellDate.isAfter(today);
            final isToday = year == today.year &&
                month == today.month &&
                day == today.day;
            final level = avgByDay[day];

            Color cellColor;
            double opacity;
            if (isFuture) {
              cellColor = LuminoTheme.divider(context);
              opacity = 0.0;
            } else if (level == null) {
              cellColor = LuminoTheme.divider(context);
              opacity = 0.3;
            } else {
              cellColor = _moodColors[level - 1];
              opacity = 1.0;
            }

            return Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(5),
                  border: isToday
                      ? Border.all(color: LuminoTheme.primaryColor, width: 2)
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ColorLegend extends StatelessWidget {
  const _ColorLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._moodColors.map((c) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
        const SizedBox(width: 4),
        Text(
          'Low → High',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: LuminoTheme.textSecondary(context),
              ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<MoodEntry> entries;
  const _TrendChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final spots = <FlSpot>[];

    for (int i = 0; i < 14; i++) {
      final day = today.subtract(Duration(days: 13 - i));
      final dayEntries = entries.where((e) {
        final d = DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
        return d == day;
      }).toList();
      if (dayEntries.isNotEmpty) {
        final avg = dayEntries.map((e) => e.moodLevel).reduce((a, b) => a + b) /
            dayEntries.length;
        spots.add(FlSpot(i.toDouble(), avg));
      }
    }

    if (spots.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: LuminoTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('No entries in the last 14 days',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: LuminoTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: LuminoTheme.primaryColor,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x == spots.last.x,
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<MoodEntry> entries;
  final int year;
  final int month;

  const _StatsRow({
    required this.entries,
    required this.year,
    required this.month,
  });

  static int _streak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries
        .map((e) => DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    if (days.first.isBefore(todayNorm.subtract(const Duration(days: 1)))) return 0;
    return streak;
  }

  static String _emoji(double avg) {
    if (avg < 1.5) return '😢';
    if (avg < 2.5) return '😕';
    if (avg < 3.5) return '😐';
    if (avg < 4.5) return '🙂';
    return '😄';
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final loggedDays = entries
        .map((e) => DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day))
        .toSet()
        .length;
    final avgMood = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.moodLevel).reduce((a, b) => a + b) /
            entries.length;

    return Row(
      children: [
        _StatTile(
          emoji: entries.isEmpty ? '😶' : _emoji(avgMood),
          value: entries.isEmpty ? '—' : avgMood.toStringAsFixed(1),
          label: 'Avg mood',
        ),
        const SizedBox(width: 12),
        _StatTile(emoji: '🔥', value: '${_streak(entries)}', label: 'Day streak'),
        const SizedBox(width: 12),
        _StatTile(
          emoji: '✅',
          value: '$loggedDays/$daysInMonth',
          label: 'Logged',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: LuminoTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: LuminoTheme.textSecondary(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
