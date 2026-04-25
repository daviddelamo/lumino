import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../library_data.dart';
import '../library_provider.dart';
import '../../../theme.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final LibraryItem item;
  const PlayerScreen({super.key, required this.item});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final handler = ref.read(audioHandlerProvider);
      await handler.playItem(widget.item);
      ref.read(recentlyPlayedProvider.notifier).add(widget.item.id);
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final isFavorite = ref.watch(favoritesProvider).contains(widget.item.id);
    final item = widget.item;

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : null,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(item.id),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 32),
            Text(item.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(item.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 40),
            // Seek bar
            StreamBuilder<Duration?>(
              stream: handler.durationStream,
              builder: (_, dSnap) {
                final total = dSnap.data ?? item.duration;
                return StreamBuilder<Duration>(
                  stream: handler.positionStream,
                  builder: (_, pSnap) {
                    final pos = pSnap.data ?? Duration.zero;
                    final frac = total.inMilliseconds > 0
                        ? (pos.inMilliseconds / total.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: item.color,
                            thumbColor: item.color,
                            inactiveTrackColor: item.color.withValues(alpha: 0.2),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: frac,
                            onChanged: (v) => handler.seek(Duration(
                                milliseconds:
                                    (v * total.inMilliseconds).round())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos),
                                  style: Theme.of(context).textTheme.labelSmall),
                              Text(_fmt(total),
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // Playback controls
            StreamBuilder<PlaybackState>(
              stream: handler.playbackState,
              builder: (_, snap) {
                final playing = snap.data?.playing ?? false;
                final loading =
                    snap.data?.processingState == AudioProcessingState.loading ||
                    snap.data?.processingState == AudioProcessingState.buffering;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final pos = handler.currentPosition - const Duration(seconds: 10);
                        handler.seek(pos < Duration.zero ? Duration.zero : pos);
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => playing ? handler.pause() : handler.play(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: item.color, shape: BoxShape.circle),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.forward_30),
                      onPressed: () => handler.seek(
                          handler.currentPosition + const Duration(seconds: 30)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
