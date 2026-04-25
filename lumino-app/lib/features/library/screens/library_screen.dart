import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../library_data.dart';
import '../library_provider.dart';
import '../../../shared/widgets/lumino_nav_bar.dart';
import '../../../theme.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentItemsProvider);
    final favorites = ref.watch(favoriteItemsProvider);

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text('Library',
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
            ),
            const SliverToBoxAdapter(child: _CategoryGrid()),
            if (recents.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionHeader('Recently Played')),
              SliverToBoxAdapter(child: _HorizontalItemList(items: recents)),
            ],
            if (favorites.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionHeader('Favorites')),
              SliverToBoxAdapter(child: _HorizontalItemList(items: favorites)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: const LuminoNavBar(currentIndex: 2),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _CategoryCard(
            title: 'Meditations',
            subtitle: 'Guided mindfulness sessions',
            emoji: '🧘',
            color: const Color(0xFF7986CB),
            onTap: () => context.push('/library/category/meditation'),
          ),
          const SizedBox(height: 12),
          _CategoryCard(
            title: 'Soundscapes',
            subtitle: 'Ambient audio for focus and sleep',
            emoji: '🌿',
            color: const Color(0xFF4DB6AC),
            onTap: () => context.push('/library/category/soundscape'),
          ),
          const SizedBox(height: 12),
          _CategoryCard(
            title: 'Affirmations',
            subtitle: 'Daily words to ground your mindset',
            emoji: '✨',
            color: const Color(0xFFFFB74D),
            onTap: () => context.push('/library/affirmations'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: LuminoTheme.textSecondary(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _HorizontalItemList extends StatelessWidget {
  final List<LibraryItem> items;
  const _HorizontalItemList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _ItemChip(item: items[i]),
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final LibraryItem item;
  const _ItemChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/library/player', extra: item),
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
