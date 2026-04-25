import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'library_data.dart';

export '../../services/audio_handler.dart' show audioHandlerProvider;

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  static const _key = 'lumino_library_favorites';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Set.from(prefs.getStringList(_key) ?? []);
  }

  Future<void> toggle(String itemId) async {
    final next = Set<String>.from(state);
    if (next.contains(itemId)) {
      next.remove(itemId);
    } else {
      next.add(itemId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool isFavorite(String itemId) => state.contains(itemId);
}

class RecentlyPlayedNotifier extends StateNotifier<List<String>> {
  RecentlyPlayedNotifier() : super([]) {
    _load();
  }

  static const _key = 'lumino_library_recents';
  static const _maxItems = 10;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String itemId) async {
    final next = [itemId, ...state.where((id) => id != itemId)]
        .take(_maxItems)
        .toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (_) => FavoritesNotifier(),
);

final recentlyPlayedProvider =
    StateNotifierProvider<RecentlyPlayedNotifier, List<String>>(
  (_) => RecentlyPlayedNotifier(),
);

final libraryForCategoryProvider =
    Provider.family<List<LibraryItem>, LibraryCategory>(
  (ref, category) =>
      kLibraryCatalog.where((item) => item.category == category).toList(),
);

final recentItemsProvider = Provider<List<LibraryItem>>((ref) {
  final ids = ref.watch(recentlyPlayedProvider);
  return ids
      .map((id) => kLibraryCatalog.where((i) => i.id == id).firstOrNull)
      .whereType<LibraryItem>()
      .toList();
});

final favoriteItemsProvider = Provider<List<LibraryItem>>((ref) {
  final ids = ref.watch(favoritesProvider);
  return kLibraryCatalog.where((item) => ids.contains(item.id)).toList();
});
