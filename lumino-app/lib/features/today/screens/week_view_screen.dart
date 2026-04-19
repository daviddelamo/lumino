import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../tasks_provider.dart';
import '../../../theme.dart';

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
      backgroundColor: LuminoTheme.backgroundWarm,
      appBar: AppBar(
        backgroundColor: LuminoTheme.backgroundWarm,
        elevation: 0,
        title: const Text('Week View',
            style: TextStyle(color: Color(0xFF3A2A1A), fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3A2A1A)),
          onPressed: () => context.go('/today'),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, page) {
          final weekOffset = page - _initialPage;
          final monday = _mondayOfWeek(weekOffset);
          return _WeekPage(monday: monday);
        },
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
    final today = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(monday);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(monthLabel,
              style: const TextStyle(
                  color: Color(0xFFA08070),
                  fontSize: 13,
                  letterSpacing: 0.5)),
        ),
        Expanded(
          child: Row(
            children: days.map((day) {
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              return Expanded(
                child: _DayColumn(day: day, isToday: isToday),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends ConsumerWidget {
  final DateTime day;
  final bool isToday;
  const _DayColumn({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForDayProvider(day));
    final tasks = tasksAsync.valueOrNull ?? [];
    final completed = tasks.where((t) => t.completedAt != null).length;
    final hasAny = tasks.isNotEmpty;

    return GestureDetector(
      onTap: () => context.go('/today'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: isToday
              ? LuminoTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: LuminoTheme.primaryColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(day).substring(0, 1),
              style: TextStyle(
                fontSize: 11,
                color: isToday ? LuminoTheme.primaryColor : const Color(0xFFA08070),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isToday ? LuminoTheme.primaryColor : const Color(0xFF3A2A1A),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasAny
                    ? (completed == tasks.length
                        ? LuminoTheme.supportingGreen
                        : LuminoTheme.primaryColor)
                    : Colors.transparent,
                border: hasAny
                    ? null
                    : Border.all(color: const Color(0xFFD0B898), width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
