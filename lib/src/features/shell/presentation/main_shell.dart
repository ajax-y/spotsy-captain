import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/data/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common_widgets/glass_container.dart';

class MainShell extends ConsumerStatefulWidget {
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
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use ref.listen to trigger the dialog only when the profile state actually changes to null
    ref.listen(userProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile == null && !_dialogShown) {
          _dialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: 32,
                opacity: 0.1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Complete Profile', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    const Text(
                      'We couldn\'t find your profile name. Would you like to set it up or sign out and start fresh?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await FirebaseAuth.instance.signOut();
                            if (mounted) context.go('/login');
                          },
                          child: const Text('SIGN OUT', style: TextStyle(color: Colors.redAccent)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onTap(3); // Go to profile tab
                          },
                          child: const Text('SETUP NAME'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      });
    });

    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_filled, isSelected: widget.currentIndex == 0, onTap: () => widget.onTap(0)),
                  _NavItem(icon: Icons.bookmark_rounded, isSelected: widget.currentIndex == 1, onTap: () => widget.onTap(1)),
                  const _FloatingNavCenter(),
                  _NavItem(icon: Icons.account_balance_wallet_rounded, isSelected: widget.currentIndex == 2, onTap: () => widget.onTap(2)),
                  _NavItem(icon: Icons.person_rounded, isSelected: widget.currentIndex == 3, onTap: () => widget.onTap(3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white38,
      ),
    );
  }
}

class _FloatingNavCenter extends StatelessWidget {
  const _FloatingNavCenter();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/parking/add'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
      ),
    );
  }
}
