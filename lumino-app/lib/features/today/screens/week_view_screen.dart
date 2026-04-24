import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../tasks_provider.dart';
import '../../../shared/widgets/lumino_icon.dart';
import '../../../theme.dart';
import '../../../database/database.dart';

class WeekViewScreen extends ConsumerStatefulWidget {
  const WeekViewScreen({super.key});

  @override
  ConsumerState<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends ConsumerState<WeekViewScreen> {
  late final PageController _pageController;
  static const int _initialPage = 500;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _mondayOfWeek(int offset) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day)
        .add(Duration(days: offset * 7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _WeekAppBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, page) {
                  final weekOffset = page - _initialPage;
                  final monday = _mondayOfWeek(weekOffset);
                  return _WeekPage(monday: monday);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back,
                color: LuminoTheme.textPrimary(context), size: 20),
            onPressed: () => GoRouter.of(context).go('/today'),
          ),
          Text(
            'WEEKLY OVERVIEW',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeekPage extends ConsumerWidget {
  final DateTime monday;
  const _WeekPage({required this.monday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final sunday = days.last;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startLabel = DateFormat('MMM d').format(monday);
    final endLabel = DateFormat('MMM d').format(sunday);
    final yearLabel = DateFormat('yyyy').format(monday);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startLabel – $endLabel, $yearLabel',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your week.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 20),
                _WeekStrip(days: days, today: today),
                const SizedBox(height: 8),
                _WeekSummary(days: days),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          sliver: _DayList(days: days, today: today),
        ),
      ],
    );
  }
}

// ─── 7-day tonal strip ────────────────────────────────────────────────────────

class _WeekStrip extends ConsumerWidget {
  final List<DateTime> days;
  final DateTime today;
  const _WeekStrip({required this.days, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: days.map((day) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _StripDay(day: day, today: today),
            ),
          )).toList(),
    );
  }
}

class _StripDay extends ConsumerWidget {
  final DateTime day;
  final DateTime today;
  const _StripDay({required this.day, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForDayProvider(day));
    final tasks = tasksAsync.valueOrNull ?? [];
    final total = tasks.length;
    final completed = tasks.where((t) => t.completedAt != null).length;

    final isToday = day == today;
    final isPast = day.isBefore(today);
    final isFuture = day.isAfter(today);

    Color blockColor;
    if (total == 0) {
      blockColor = isFuture
          ? LuminoTheme.divider(context).withValues(alpha: 0.5)
          : LuminoTheme.divider(context);
    } else if (completed == total) {
      blockColor = LuminoTheme.supportingGreen.withValues(alpha: isPast ? 0.6 : 0.8);
    } else if (completed > 0) {
      blockColor = LuminoTheme.primaryColor.withValues(alpha: 0.5);
    } else {
      blockColor = LuminoTheme.divider(context);
    }

    return Column(
      children: [
        Text(
          DateFormat('E').format(day).substring(0, 1),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isToday
                    ? LuminoTheme.primaryColor
                    : LuminoTheme.textSecondary(context),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 36,
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: LuminoTheme.primaryColor, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.textPrimary(context),
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Week summary line ────────────────────────────────────────────────────────

class _WeekSummary extends ConsumerWidget {
  final List<DateTime> days;
  const _WeekSummary({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int totalTasks = 0;
    int totalDone = 0;
    int daysWithTasks = 0;

    for (final day in days) {
      final tasks = ref.watch(tasksForDayProvider(day)).valueOrNull ?? [];
      if (tasks.isNotEmpty) daysWithTasks++;
      totalTasks += tasks.length;
      totalDone += tasks.where((t) => t.completedAt != null).length;
    }

    if (totalTasks == 0) {
      return Text(
        'Nothing planned yet this week',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Text(
      '$totalDone of $totalTasks tasks done · $daysWithTasks active ${daysWithTasks == 1 ? 'day' : 'days'}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

// ─── Day-by-day list ──────────────────────────────────────────────────────────

class _DayList extends ConsumerWidget {
  final List<DateTime> days;
  final DateTime today;
  const _DayList({required this.days, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _DaySection(day: days[i], today: today),
        childCount: days.length,
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DateTime day;
  final DateTime today;
  const _DaySection({required this.day, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForDayProvider(day));
    final tasks = tasksAsync.valueOrNull ?? [];
    final isToday = day == today;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day section header
          Row(
            children: [
              Text(
                DateFormat('EEEE').format(day),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isToday
                          ? LuminoTheme.primaryColor
                          : LuminoTheme.textPrimary(context),
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d').format(day),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: LuminoTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Today',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: LuminoTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Text(
              'Rest day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            )
          else
            ...tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WeekTaskRow(task: t),
                )),
        ],
      ),
    );
  }
}

class _WeekTaskRow extends StatelessWidget {
  final Task task;
  const _WeekTaskRow({required this.task});

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.completedAt != null;
    final color = _parseColor(task.color);

    return AnimatedOpacity(
      opacity: isDone ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: LuminoTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: LuminoIcon(task.iconId, size: 16, color: color),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: LuminoTheme.textSecondary(context),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('HH:mm').format(task.startAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? color : Colors.transparent,
                border: Border.all(
                  color: isDone ? color : color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
