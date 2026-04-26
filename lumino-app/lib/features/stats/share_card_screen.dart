import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import 'stats_provider.dart';

class ShareCardScreen extends ConsumerStatefulWidget {
  final StatsPeriod period;
  const ShareCardScreen({super.key, required this.period});

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _repaintKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'lumino_stats.png')
        ],
        text: 'My Lumino progress 🌟',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider(widget.period));

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        title: const Text('Share Progress'),
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share'),
          ),
        ],
      ),
      body: Center(
        child: statsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (stats) => Padding(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(
              key: _repaintKey,
              child: _ShareCard(stats: stats, period: widget.period),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final StatsData stats;
  final StatsPeriod period;

  const _ShareCard({required this.stats, required this.period});

  String get _periodLabel {
    final diff = period.to.difference(period.from).inDays;
    if (diff <= 7) return 'Last 7 days';
    if (period.from.month == period.to.month) {
      const months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[period.from.month]} ${period.from.year}';
    }
    return '${period.from.year}';
  }

  static String _moodEmoji(double avg) {
    if (avg == 0) return '💭';
    if (avg < 2) return '😢';
    if (avg < 3) return '😕';
    if (avg < 4) return '😐';
    if (avg < 4.5) return '🙂';
    return '😄';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LuminoTheme.primaryColor.withValues(alpha: 0.92),
            const Color(0xFFD35400),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lumino',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text(_periodLabel,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12)),
                ],
              ),
              const Text('🌟', style: TextStyle(fontSize: 32)),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _CardStat(
                  emoji: '✅',
                  value: '${stats.tasksCompleted}',
                  label: 'Tasks done'),
              const SizedBox(width: 24),
              _CardStat(
                  emoji: '🔄',
                  value: '${(stats.habitCompletionRate * 100).round()}%',
                  label: 'Habit rate'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _CardStat(
                  emoji: _moodEmoji(stats.avgMood),
                  value: stats.avgMood == 0
                      ? '—'
                      : stats.avgMood.toStringAsFixed(1),
                  label: 'Avg mood'),
              const SizedBox(width: 24),
              _CardStat(
                  emoji: '🔥',
                  value: stats.bestStreak == 0
                      ? '—'
                      : '${stats.bestStreak}d',
                  label: 'Best streak'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('lumino.app',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _CardStat(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11)),
        ],
      ),
    );
  }
}
