import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumino_app/features/library/library_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesNotifier', () {
    test('starts empty', () async {
      final n = FavoritesNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(n.state, isEmpty);
    });

    test('toggle adds item', () async {
      final n = FavoritesNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await n.toggle('item_1');
      expect(n.state, contains('item_1'));
    });

    test('toggle twice removes item', () async {
      final n = FavoritesNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await n.toggle('item_1');
      await n.toggle('item_1');
      expect(n.state, isNot(contains('item_1')));
    });

    test('isFavorite reflects state', () async {
      final n = FavoritesNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await n.toggle('item_1');
      expect(n.isFavorite('item_1'), isTrue);
      expect(n.isFavorite('item_2'), isFalse);
    });
  });

  group('RecentlyPlayedNotifier', () {
    test('starts empty', () async {
      final n = RecentlyPlayedNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(n.state, isEmpty);
    });

    test('add inserts at front', () async {
      final n = RecentlyPlayedNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await n.add('item_a');
      await n.add('item_b');
      expect(n.state.first, 'item_b');
    });

    test('adding existing item moves it to front without duplicate', () async {
      final n = RecentlyPlayedNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await n.add('item_a');
      await n.add('item_b');
      await n.add('item_a');
      expect(n.state.first, 'item_a');
      expect(n.state.length, 2);
    });

    test('caps at 10 items', () async {
      final n = RecentlyPlayedNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      for (var i = 0; i < 12; i++) {
        await n.add('item_$i');
      }
      expect(n.state.length, 10);
    });
  });
}
