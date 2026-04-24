import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';

class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  String _type = 'tasks';
  int _count = 5;
  String _theme = 'auto';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _type  = prefs.getString('lumino_widget_type')  ?? 'tasks';
      _count = prefs.getInt('lumino_widget_count')     ?? 5;
      _theme = prefs.getString('lumino_widget_theme')  ?? 'auto';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumino_widget_type',  _type);
    await prefs.setInt('lumino_widget_count',     _count);
    await prefs.setString('lumino_widget_theme',  _theme);

    await HomeWidget.saveWidgetData<String>('lumino_widget_type',  _type);
    await HomeWidget.saveWidgetData<int>('lumino_widget_count',    _count);
    await HomeWidget.saveWidgetData<String>('lumino_widget_theme', _theme);
    await HomeWidget.updateWidget(androidName: 'LuminoSmallWidget');
    await HomeWidget.updateWidget(androidName: 'LuminoLargeWidget');

    if (mounted) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        title: const Text('Widget Settings'),
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Show'),
          _ChoiceRow(
            options: const {'tasks': 'Tasks', 'habits': 'Habits'},
            value: _type,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Items to show'),
          _ChoiceRow(
            options: const {'3': '3', '5': '5', '0': 'All'},
            value: _count.toString(),
            onChanged: (v) => setState(() => _count = int.parse(v)),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Appearance'),
          _ChoiceRow(
            options: const {
              'light': 'Light',
              'dark': 'Dark',
              'auto': 'Auto',
            },
            value: _theme,
            onChanged: (v) => setState(() => _theme = v),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: LuminoTheme.primaryColor),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _ChoiceRow({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries.map((e) {
        final selected = e.key == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? LuminoTheme.primaryColor
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? LuminoTheme.primaryColor
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
