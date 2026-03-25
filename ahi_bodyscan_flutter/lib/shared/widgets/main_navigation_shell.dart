import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/home':
        return 0;
      case '/reports':
        return 1;
      case '/new-scan':
        return 2;
      case '/settings':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        // Set bottom to false to prevent content from hiding behind the navigation bar
        // The BottomNavigationBar will handle bottom insets automatically
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/reports');
              break;
            case 2:
              context.go('/new-scan');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.backgroundWhite,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: AppColors.inactive,
        selectedLabelStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: AppTypography.bodySmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}