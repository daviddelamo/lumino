import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../library_data.dart';
import '../library_provider.dart';
import '../../../theme.dart';
import '../../paywall/paywall_gate.dart';
import '../../paywall/paywall_provider.dart';

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
    final isPremium = ref.watch(isPremiumProvider);

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
          final locked = item.isPremium && !isPremium;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LibraryItemCard(
              item: item,
              isFavorite: favorites.contains(item.id),
              locked: locked,
              onTap: () {
                if (locked) {
                  paywallGate(context, ref);
                } else {
                  context.push('/library/player', extra: item);
                }
              },
              onFavoriteToggle: locked
                  ? null
                  : () => ref.read(favoritesProvider.notifier).toggle(item.id),
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
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const _LibraryItemCard({
    required this.item,
    required this.isFavorite,
    required this.locked,
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
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: locked ? 0.08 : 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: TextStyle(
                          fontSize: 26,
                          color: locked ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ),
                  if (locked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: locked ? Colors.grey : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: locked ? Colors.grey : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(item.duration),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: locked ? Colors.grey : item.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (locked)
                const SizedBox(width: 48)
              else
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
