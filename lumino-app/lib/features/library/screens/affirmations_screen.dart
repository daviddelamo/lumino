import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../library_data.dart';
import '../../../theme.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final dayIndex =
        DateTime.now().difference(DateTime(2024)).inDays %
            kAffirmations.length;
    _currentPage = dayIndex;
    _controller = PageController(initialPage: dayIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        title: const Text('Daily Affirmations'),
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: kAffirmations.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _AffirmationCard(
                text: kAffirmations[i],
                isToday: i == _currentPage,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(kAffirmations.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _currentPage ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  final String text;
  final bool isToday;
  const _AffirmationCard({required this.text, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LuminoTheme.primaryColor.withValues(alpha: 0.12),
              const Color(0xFFFFB74D).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: LuminoTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 32),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 32),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: LuminoTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Today's affirmation",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: LuminoTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LuminoTheme.primaryColor,
                  side: BorderSide(
                      color: LuminoTheme.primaryColor.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
