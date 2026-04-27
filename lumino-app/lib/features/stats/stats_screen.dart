import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../paywall/paywall_gate.dart';
import '../paywall/paywall_provider.dart';
import 'stats_provider.dart';

enum _Period { week, month, year }

extension on _Period {
  String get label => switch (this) {
        _Period.week => '7 days',
        _Period.month => 'Month',
        _Period.year => 'Year',
      };

  StatsPeriod get period {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      _Period.week => (from: today.subtract(const Duration(days: 6)), to: today),
      _Period.month => (from: DateTime(now.year, now.month, 1), to: today),
      _Period.year => (from: DateTime(now.year, 1, 1), to: today),
    };
  }
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _Period _selected = _Period.month;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final period = _selected.period;
    final statsAsync = ref.watch(statsProvider(period));
    final dailyAsync = ref.watch(dailyStatsProvider(period));
    final breakdownAsync = ref.watch(habitBreakdownProvider(period));

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => context.push('/stats/share', extra: period),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _PeriodChips(
            selected: _selected,
            locked: isPremium ? {} : {_Period.year},
            onChanged: (p) {
              if (p == _Period.year && !isPremium) {
                paywallGate(context, ref);
                return;
              }
              setState(() => _selected = p);
            },
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (stats) => _SummaryGrid(stats: stats),
          ),
          const SizedBox(height: 28),
          Text('Habit & Mood Trend',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Row(
            children: [
              _LegendDot(color: LuminoTheme.primaryColor, label: 'Habits'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFFFB74D), label: 'Mood'),
            ],
          ),
          const SizedBox(height: 12),
          dailyAsync.when(
            loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator())),
            error: (e, st) {
              debugPrint('dailyStatsProvider error: $e\n$st');
              return const SizedBox.shrink();
            },
            data: (points) => _CorrelationChart(points: points),
          ),
          const SizedBox(height: 28),
          breakdownAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) {
              debugPrint('habitBreakdownProvider error: $e\n$st');
              return const SizedBox.shrink();
            },
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : _HabitBreakdown(items: items),
          ),
        ],
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  final Set<_Period> locked;

  const _PeriodChips({
    required this.selected,
    required this.onChanged,
    this.locked = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Period.values.map((opt) {
        final isSelected = opt == selected;
        final isLocked = locked.contains(opt);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? LuminoTheme.primaryColor
                    : LuminoTheme.surface(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : LuminoTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: isSelected
                          ? Colors.white70
                          : LuminoTheme.textPrimary(context)
                              .withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatsData stats;
  const _SummaryGrid({required this.stats});

  static String _moodEmoji(double avg) {
    if (avg == 0) return '—';
    if (avg < 2) return '😢';
    if (avg < 3) return '😕';
    if (avg < 4) return '😐';
    if (avg < 4.5) return '🙂';
    return '😄';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: 'Tasks Done',
          value: '${stats.tasksCompleted}/${stats.tasksTotal}',
          icon: Icons.check_circle_outline,
          color: LuminoTheme.primaryColor,
        ),
        _StatCard(
          label: 'Habit Rate',
          value: '${(stats.habitCompletionRate * 100).round()}%',
          icon: Icons.repeat_outlined,
          color: const Color(0xFF7986CB),
        ),
        _StatCard(
          label: 'Avg Mood',
          value: stats.avgMood == 0
              ? '—'
              : '${_moodEmoji(stats.avgMood)} ${stats.avgMood.toStringAsFixed(1)}',
          icon: Icons.mood_outlined,
          color: const Color(0xFFFFB74D),
        ),
        _StatCard(
          label: 'Best Streak',
          value: stats.bestStreak == 0 ? '—' : '🔥 ${stats.bestStreak}d',
          icon: Icons.local_fire_department_outlined,
          color: const Color(0xFFEF5350),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuminoTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                          color: LuminoTheme.textSecondary(context))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: LuminoTheme.textSecondary(context))),
      ],
    );
  }
}

class _CorrelationChart extends StatelessWidget {
  final List<DailyPoint> points;
  const _CorrelationChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final habitSpots = <FlSpot>[];
    final moodSpots = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      habitSpots.add(FlSpot(i.toDouble(), p.habitRate * 100));
      if (p.mood > 0) {
        // scale mood 1..5 → 0..100 so both series share one y-axis
        moodSpots.add(FlSpot(i.toDouble(), (p.mood - 1) / 4 * 100));
      }
    }

    final xInterval = points.length > 31 ? 30.0 : points.length > 7 ? 7.0 : 1.0;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: LuminoTheme.divider(context),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    DateFormat('M/d').format(points[i].date),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontSize: 9),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: habitSpots,
              isCurved: true,
              color: LuminoTheme.primaryColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: LuminoTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            if (moodSpots.isNotEmpty)
              LineChartBarData(
                spots: moodSpots,
                isCurved: true,
                color: const Color(0xFFFFB74D),
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => LuminoTheme.surface(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitBreakdown extends StatelessWidget {
  final List<(String, double)> items;
  const _HabitBreakdown({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit Breakdown',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.$1,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(item.$2 * 100).round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: LuminoTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.$2,
                      minHeight: 6,
                      backgroundColor: LuminoTheme.surface(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          LuminoTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
