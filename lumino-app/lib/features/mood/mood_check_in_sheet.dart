import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import 'mood_provider.dart';

const _moodColors = [
  Color(0xFFE05C5C),
  Color(0xFFE8913A),
  Color(0xFFE8C23A),
  Color(0xFF8BC48A),
  Color(0xFF52B788),
];
const _moodEmojis = ['😢', '😕', '😐', '🙂', '😄'];
const _moodLabels = ['Awful', 'Bad', 'Okay', 'Good', 'Amazing'];
const _allTags = [
  'anxious', 'calm', 'energised', 'tired',
  'grateful', 'stressed', 'focused', 'social',
];

class MoodCheckInSheet extends ConsumerStatefulWidget {
  const MoodCheckInSheet({super.key});

  @override
  ConsumerState<MoodCheckInSheet> createState() => _MoodCheckInSheetState();
}

class _MoodCheckInSheetState extends ConsumerState<MoodCheckInSheet> {
  int? _selectedLevel;
  final Set<String> _selectedTags = {};
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedLevel == null || _saving) return;
    setState(() => _saving = true);
    await ref.read(moodProvider.notifier).checkIn(
          _selectedLevel!,
          _selectedTags.toList(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood logged'),
          action: SnackBarAction(
            label: 'See history',
            onPressed: () => GoRouter.of(context).push('/mood/history'),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _MoodTileRow(
            selectedLevel: _selectedLevel,
            onSelect: (level) => setState(() => _selectedLevel = level),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) => Text(
              _moodLabels[i],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: _selectedLevel == i + 1
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.textSecondary(context),
                    fontWeight: _selectedLevel == i + 1
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
            )),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.divider(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? Colors.white
                              : LuminoTheme.textSecondary(context),
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'Add a note… (optional)',
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LuminoTheme.textSecondary(context)),
              filled: true,
              fillColor: LuminoTheme.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedLevel != null && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: LuminoTheme.primaryColor,
                disabledBackgroundColor:
                    LuminoTheme.primaryColor.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Save',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTileRow extends StatelessWidget {
  final int? selectedLevel;
  final ValueChanged<int> onSelect;

  const _MoodTileRow({required this.selectedLevel, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final selected = selectedLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: selected ? 60 : 50,
              decoration: BoxDecoration(
                color: _moodColors[i],
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: LuminoTheme.primaryColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  _moodEmojis[i],
                  style: TextStyle(fontSize: selected ? 26 : 20),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

List<String> decodeMoodTags(String json) {
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}
