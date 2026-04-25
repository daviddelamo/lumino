import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../library_data.dart';
import '../library_provider.dart';
import '../../../theme.dart';

class LibraryCategoryScreen extends ConsumerWidget {
  final LibraryCategory category;
  const LibraryCategoryScreen({super.key, required this.category});

  String get _title => switch (category) {
        LibraryCategory.meditation => 'Meditations',
        LibraryCategory.soundscape => 'Soundscapes',
        LibraryCategory.affirmation => 'Affirmations',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(libraryForCategoryProvider(category));
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LibraryItemCard(
              item: item,
              isFavorite: favorites.contains(item.id),
              onTap: () => context.push('/library/player', extra: item),
              onFavoriteToggle: () =>
                  ref.read(favoritesProvider.notifier).toggle(item.id),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryItemCard extends StatelessWidget {
  final LibraryItem item;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _LibraryItemCard({
    required this.item,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(item.duration),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: item.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : null,
                  size: 20,
                ),
                onPressed: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
