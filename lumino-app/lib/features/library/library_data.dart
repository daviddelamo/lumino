import 'package:flutter/material.dart';

enum LibraryCategory { meditation, soundscape, affirmation }

class LibraryItem {
  final String id;
  final String title;
  final String description;
  final LibraryCategory category;
  final String audioUrl;
  final Duration duration;
  final String emoji;
  final Color color;

  const LibraryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.audioUrl,
    required this.duration,
    required this.emoji,
    required this.color,
  });
}

// Placeholder audio URLs — replace with real CC0/licensed content before shipping.
// Free sources: freesound.org (CC0), pixabay.com/music, mixkit.co
const _placeholderMeditation =
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
const _placeholderSoundscape =
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';

const _meditationColor = Color(0xFF7986CB);
const _soundscapeColor = Color(0xFF4DB6AC);

const kLibraryCatalog = <LibraryItem>[
  LibraryItem(
    id: 'med_morning_calm',
    title: 'Morning Calm',
    description: 'Start your day with a peaceful 5-minute centering practice.',
    category: LibraryCategory.meditation,
    audioUrl: _placeholderMeditation,
    duration: Duration(minutes: 5),
    emoji: '🌅',
    color: _meditationColor,
  ),
  LibraryItem(
    id: 'med_body_scan',
    title: 'Body Scan',
    description: 'Release tension from head to toe with this 10-minute body scan.',
    category: LibraryCategory.meditation,
    audioUrl: _placeholderMeditation,
    duration: Duration(minutes: 10),
    emoji: '🧘',
    color: _meditationColor,
  ),
  LibraryItem(
    id: 'med_breath_focus',
    title: 'Breath Focus',
    description: 'A 3-minute breathing exercise to anchor your attention.',
    category: LibraryCategory.meditation,
    audioUrl: _placeholderMeditation,
    duration: Duration(minutes: 3),
    emoji: '💨',
    color: _meditationColor,
  ),
  LibraryItem(
    id: 'snd_gentle_rain',
    title: 'Gentle Rain',
    description: 'Soft rainfall to mask distractions and calm the mind.',
    category: LibraryCategory.soundscape,
    audioUrl: _placeholderSoundscape,
    duration: Duration(minutes: 60),
    emoji: '🌧️',
    color: _soundscapeColor,
  ),
  LibraryItem(
    id: 'snd_forest_morning',
    title: 'Forest Morning',
    description: 'Birds and rustling leaves in a sunlit forest.',
    category: LibraryCategory.soundscape,
    audioUrl: _placeholderSoundscape,
    duration: Duration(minutes: 60),
    emoji: '🌲',
    color: _soundscapeColor,
  ),
  LibraryItem(
    id: 'snd_ocean_waves',
    title: 'Ocean Waves',
    description: 'Rhythmic waves rolling onto shore.',
    category: LibraryCategory.soundscape,
    audioUrl: _placeholderSoundscape,
    duration: Duration(minutes: 60),
    emoji: '🌊',
    color: _soundscapeColor,
  ),
  LibraryItem(
    id: 'snd_white_noise',
    title: 'White Noise',
    description: 'Pure white noise for deep focus or sleep.',
    category: LibraryCategory.soundscape,
    audioUrl: _placeholderSoundscape,
    duration: Duration(minutes: 60),
    emoji: '〰️',
    color: _soundscapeColor,
  ),
];

const kAffirmations = <String>[
  'I am capable of handling whatever comes my way.',
  'I choose peace and clarity today.',
  'I grow stronger with every challenge I face.',
  'I am enough, exactly as I am.',
  'My mind is clear, my heart is open.',
  'I attract good things into my life.',
  'I trust the process of my journey.',
  'I am worthy of love and happiness.',
  'Every day I am becoming a better version of myself.',
  'I have everything I need within me.',
];
