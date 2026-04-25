import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LuminoNavBar extends StatelessWidget {
  final int currentIndex;
  const LuminoNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        if (i == currentIndex) return;
        switch (i) {
          case 0:
            context.go('/today');
          case 1:
            context.go('/habits');
          case 2:
            context.go('/library');
          case 3:
            context.go('/me');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: 'Habits',
        ),
        NavigationDestination(
          icon: Icon(Icons.headphones_outlined),
          selectedIcon: Icon(Icons.headphones),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Me',
        ),
      ],
    );
  }
}
