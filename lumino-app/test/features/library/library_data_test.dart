import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/features/library/library_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog has at least 3 meditations', () {
    final items = kLibraryCatalog
        .where((i) => i.category == LibraryCategory.meditation)
        .toList();
    expect(items.length, greaterThanOrEqualTo(3));
  });

  test('catalog has at least 4 soundscapes', () {
    final items = kLibraryCatalog
        .where((i) => i.category == LibraryCategory.soundscape)
        .toList();
    expect(items.length, greaterThanOrEqualTo(4));
  });

  test('every catalog item has non-empty id, title, and audioUrl', () {
    for (final item in kLibraryCatalog) {
      expect(item.id, isNotEmpty, reason: '${item.title} has empty id');
      expect(item.title, isNotEmpty, reason: '${item.id} has empty title');
      expect(item.audioUrl, isNotEmpty,
          reason: '${item.id} has empty audioUrl');
    }
  });

  test('catalog item ids are unique', () {
    final ids = kLibraryCatalog.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('kAffirmations has at least 5 non-empty entries', () {
    expect(kAffirmations.length, greaterThanOrEqualTo(5));
    for (final a in kAffirmations) {
      expect(a, isNotEmpty);
    }
  });

  test('each non-affirmation category has at least one free item', () {
    for (final cat in LibraryCategory.values) {
      if (cat == LibraryCategory.affirmation) continue;
      final items = kLibraryCatalog.where((i) => i.category == cat);
      final freeItems = items.where((i) => !i.isPremium);
      expect(freeItems, isNotEmpty,
          reason: '$cat should have at least one free item');
    }
  });

  test('some catalog items are marked premium', () {
    expect(kLibraryCatalog.any((i) => i.isPremium), isTrue);
  });
}
