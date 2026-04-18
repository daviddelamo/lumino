import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../habits_provider.dart';
import '../../../theme.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _titleCtrl = TextEditingController();
  String _type = 'bool';
  double _target = 1;
  final String _color = '#E8823A';
  final String _iconId = 'circle';
  String _frequencyRule = '{"type":"daily"}';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(habitsNotifierProvider.notifier).addHabit(
            title: _titleCtrl.text.trim(),
            iconId: _iconId,
            color: _color,
            type: _type,
            targetValue: _target,
            frequencyRule: _frequencyRule,
          );
      if (mounted) { context.pop(); }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      appBar: AppBar(
        backgroundColor: LuminoTheme.backgroundWarm,
        title: const Text('New Habit'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Habit name'),
            ),
            const SizedBox(height: 20),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'bool', label: Text('Yes/No')),
                ButtonSegment(value: 'count', label: Text('Count')),
                ButtonSegment(value: 'duration', label: Text('Duration')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (_type != 'bool') ...[
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _type == 'count' ? 'Target count' : 'Target minutes',
                ),
                onChanged: (v) => setState(() => _target = double.tryParse(v) ?? 1),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _frequencyRule,
              items: const [
                DropdownMenuItem(value: '{"type":"daily"}', child: Text('Every day')),
                DropdownMenuItem(
                    value: '{"type":"weekdays"}', child: Text('Weekdays only')),
                DropdownMenuItem(
                    value: '{"type":"weekend"}', child: Text('Weekends only')),
              ],
              onChanged: (v) => setState(() => _frequencyRule = v!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 32),
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
                    : const Text('Save Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
