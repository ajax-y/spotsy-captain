import 'dart:ui';
import 'package:flutter/material.dart';

class MainShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTap;

  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for glass effect to show content behind
      body: child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            elevation: 0,
            indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
