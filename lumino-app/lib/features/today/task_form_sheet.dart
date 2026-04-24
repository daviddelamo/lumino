import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../shared/widgets/lumino_icon.dart';
import '../../theme.dart';
import 'tasks_provider.dart';

const _icons = [
  'circle', 'run', 'yoga', 'book', 'food', 'water',
  'brain', 'pencil', 'sun', 'moon', 'check', 'work',
];
const _colors = [
  '#E8823A', '#4CAF82', '#9B72D0', '#5B6EF5',
  '#E57373', '#F9C06A', '#A8D5BA', '#F7C59F',
];
const _minuteSteps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
const _durations = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];

class TaskFormSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final VoidCallback onSaved;
  final Task? existing;

  const TaskFormSheet({
    super.key,
    required this.date,
    required this.onSaved,
    this.existing,
  });

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _titleCtrl = TextEditingController();
  String _iconId = 'circle';
  String _color = '#E8823A';
  bool _saving = false;

  late int _hour;
  late int _minuteIndex;
  late int _durationIndex;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _durationCtrl;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _titleCtrl.text = ex.title;
      _iconId = ex.iconId;
      _color = ex.color;
      _hour = ex.startAt.hour;
      final min = ex.startAt.minute;
      _minuteIndex =
          (_minuteSteps.indexWhere((m) => m >= min)).clamp(0, _minuteSteps.length - 1);
      final dur = ex.endAt?.difference(ex.startAt).inMinutes ?? 30;
      final di = _durations.indexWhere((d) => d >= dur);
      _durationIndex = di == -1 ? _durations.indexOf(30) : di;
    } else {
      final now = TimeOfDay.now();
      _hour = now.hour;
      final mi = _minuteSteps.indexWhere((m) => m >= now.minute);
      _minuteIndex = mi == -1 ? 0 : mi;
      _durationIndex = _durations.indexOf(30);
    }
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minuteIndex);
    _durationCtrl = FixedExtentScrollController(initialItem: _durationIndex);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      final userId = ref.read(currentUserIdProvider) ?? 'local';
      final startAt = DateTime(
        widget.date.year, widget.date.month, widget.date.day,
        _hour, _minuteSteps[_minuteIndex],
      );
      final endAt = startAt.add(Duration(minutes: _durations[_durationIndex]));

      await db.taskDao.insertTask(TasksCompanion.insert(
        userId: userId,
        title: _titleCtrl.text.trim(),
        iconId: Value(_iconId),
        color: Value(_color),
        startAt: startAt,
        endAt: Value(endAt),
      ));

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save task: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: LuminoTheme.bg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LuminoTheme.divider(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.existing != null ? 'Edit Task' : 'New Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // Task title field
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'e.g. Read 20 pages',
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: LuminoTheme.textSecondary(context)),
                    filled: true,
                    fillColor: LuminoTheme.surface(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: LuminoTheme.primaryColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Icon grid (4 × 3, no scrolling) ─────────────────────
                Text(
                  'Icon',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (_, i) {
                    final id = _icons[i];
                    final isSelected = _iconId == id;
                    final accentColor = _hexToColor(_color);
                    return GestureDetector(
                      onTap: () => setState(() => _iconId = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.12)
                              : LuminoTheme.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: accentColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: LuminoIcon(
                            id,
                            size: 26,
                            color: isSelected
                                ? accentColor
                                : LuminoTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Color grid (2 × 4, full width) ──────────────────────
                Text(
                  'Category Color',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _ColorRow(
                      colors: _colors.sublist(0, 4),
                      selected: _color,
                      onSelect: (c) => setState(() => _color = c),
                    ),
                    const SizedBox(height: 8),
                    _ColorRow(
                      colors: _colors.sublist(4),
                      selected: _color,
                      onSelect: (c) => setState(() => _color = c),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Drum rollers: Start Time + Duration ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: LuminoTheme.surface(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _DrumRoller(
                                  width: 52,
                                  controller: _hourCtrl,
                                  items: List.generate(
                                      24, (i) => i.toString().padLeft(2, '0')),
                                  selectedIndex: _hour,
                                  onChanged: (i) =>
                                      setState(() => _hour = i),
                                ),
                                Text(
                                  ':',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                          color: LuminoTheme.textPrimary(
                                              context)),
                                ),
                                _DrumRoller(
                                  width: 52,
                                  controller: _minuteCtrl,
                                  items: _minuteSteps
                                      .map((m) =>
                                          m.toString().padLeft(2, '0'))
                                      .toList(),
                                  selectedIndex: _minuteIndex,
                                  onChanged: (i) =>
                                      setState(() => _minuteIndex = i),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: LuminoTheme.surface(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _DrumRoller(
                                  width: 56,
                                  controller: _durationCtrl,
                                  items: _durations
                                      .map((d) => '$d')
                                      .toList(),
                                  selectedIndex: _durationIndex,
                                  onChanged: (i) =>
                                      setState(() => _durationIndex = i),
                                ),
                                Text(
                                  'min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: LuminoTheme.textSecondary(
                                              context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Task'),
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

// ── Full-width color row ────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: colors.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        final isSelected = selected == c;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < colors.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                decoration: BoxDecoration(
                  color: _hexToColor(c),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: LuminoTheme.textPrimary(context),
                          width: 2.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _hexToColor(c).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      )
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Drum roller wheel picker ────────────────────────────────────────────────

class _DrumRoller extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final FixedExtentScrollController controller;
  final double width;

  const _DrumRoller({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    required this.controller,
    required this.width,
  });

  @override
  State<_DrumRoller> createState() => _DrumRollerState();
}

class _DrumRollerState extends State<_DrumRoller> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    const itemHeight = 44.0;
    const visibleHeight = 132.0; // 3 items

    return SizedBox(
      width: widget.width,
      height: visibleHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center highlight band — behind the text
          IgnorePointer(
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: LuminoTheme.divider(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Wheel
          ListWheelScrollView.useDelegate(
            controller: widget.controller,
            itemExtent: itemHeight,
            perspective: 0.001,
            diameterRatio: 3.0,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              setState(() => _selectedIndex = i);
              widget.onChanged(i);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (context, i) {
                final isSelected = i == _selectedIndex;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 120),
                    style: isSelected
                        ? (Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: LuminoTheme.textPrimary(context),
                                fontWeight: FontWeight.w700,
                              ) ??
                            const TextStyle())
                        : (Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: LuminoTheme.textSecondary(context),
                              ) ??
                            const TextStyle()),
                    child: Text(widget.items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
