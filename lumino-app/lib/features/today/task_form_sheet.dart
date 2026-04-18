import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../theme.dart';
import 'tasks_provider.dart';

const _icons = ['circle', 'run', 'yoga', 'book', 'food', 'water', 'brain', 'pencil', 'sun', 'moon', 'check', 'work'];
const _colors = ['#E8823A', '#4CAF82', '#9B72D0', '#5B6EF5', '#E57373', '#F9C06A', '#A8D5BA', '#F7C59F'];

class TaskFormSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final VoidCallback onSaved;
  final Task? existing;

  const TaskFormSheet({super.key, required this.date, required this.onSaved, this.existing});

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _titleCtrl = TextEditingController();
  String _iconId = 'circle';
  String _color = '#E8823A';
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationMin = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _iconId = widget.existing!.iconId;
      _color = widget.existing!.color;
      _startTime = TimeOfDay.fromDateTime(widget.existing!.startAt);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final db = ref.read(dbProvider);
    final userId = ref.read(currentUserIdProvider) ?? 'local';
    final startAt = DateTime(widget.date.year, widget.date.month, widget.date.day,
        _startTime.hour, _startTime.minute);
    final endAt = startAt.add(Duration(minutes: _durationMin));

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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0C8B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('New Task',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: const Color(0xFFFFF0E0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Icon',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA08070),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _iconId = _icons[i]),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E0),
                      borderRadius: BorderRadius.circular(8),
                      border: _iconId == _icons[i]
                          ? Border.all(color: LuminoTheme.primaryColor, width: 2)
                          : null,
                    ),
                    child: const Icon(Icons.circle, size: 16, color: Color(0xFFA08070)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Color',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA08070),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: _colors
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Color(int.parse(c.replaceFirst('#', 'FF'), radix: 16)),
                            shape: BoxShape.circle,
                            border: _color == c
                                ? Border.all(color: Colors.black54, width: 2)
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA08070),
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context, initialTime: _startTime);
                          if (t != null && mounted) setState(() => _startTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E0),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(_startTime.format(context),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Duration',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA08070),
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: _durationMin,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFFF0E0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [5, 10, 15, 20, 30, 45, 60, 90, 120]
                            .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                            .toList(),
                        onChanged: (v) => setState(() => _durationMin = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Task'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
