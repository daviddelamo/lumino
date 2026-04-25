import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../features/library/library_data.dart';

class LuminoAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  LuminoAudioHandler() {
    _player.playbackEventStream
        .map(_toPlaybackState)
        .pipe(playbackState)
        .catchError((_) {});
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get currentPosition => _player.position;
  bool get isPlaying => _player.playing;

  Future<void> playItem(LibraryItem item) async {
    mediaItem.add(MediaItem(
      id: item.id,
      title: item.title,
      duration: item.duration,
    ));
    await _player.setUrl(item.audioUrl);
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> onTaskRemoved() => stop();

  Future<void> dispose() => _player.dispose();

  PlaybackState _toPlaybackState(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    );
  }
}

/// Overridden in main() with the result of AudioService.init().
final audioHandlerProvider = Provider<LuminoAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});
