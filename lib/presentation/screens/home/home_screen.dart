import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/responsive_layout.dart';
import '../convert/convert_screen.dart';
import '../trim/trim_screen.dart';
import '../batch/batch_screen.dart';
import '../presets/presets_screen.dart';
import '../settings/settings_screen.dart';

/// Navigation destination
enum NavDestination {
  convert,
  trim,
  batch,
  presets,
  settings,
}

/// Provider for current navigation destination
final navigationProvider = StateProvider<NavDestination>((ref) {
  return NavDestination.convert;
});

/// Main home screen with navigation
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDestination = ref.watch(navigationProvider);

    return ResponsiveLayout(
      mobile: _MobileLayout(currentDestination: currentDestination),
      desktop: _DesktopLayout(currentDestination: currentDestination),
    );
  }
}

/// Mobile layout with bottom navigation
class _MobileLayout extends ConsumerWidget {
  final NavDestination currentDestination;

  const _MobileLayout({required this.currentDestination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: _buildBody(currentDestination),
      bottomNavigationBar: _buildBottomNav(context, ref),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentDestination.index,
        onTap: (index) {
          ref.read(navigationProvider.notifier).state =
              NavDestination.values[index];
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Convert',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut_outlined),
            activeIcon: Icon(Icons.content_cut),
            label: 'Trim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Batch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            activeIcon: Icon(Icons.tune),
            label: 'Presets',
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

/// Desktop layout with navigation rail
class _DesktopLayout extends ConsumerWidget {
  final NavDestination currentDestination;

  const _DesktopLayout({required this.currentDestination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: NavigationRail(
              selectedIndex: currentDestination.index,
              onDestinationSelected: (index) {
                ref.read(navigationProvider.notifier).state =
                    NavDestination.values[index];
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.movie_filter,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'VidForge',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: Text('Convert'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.content_cut_outlined),
                  selectedIcon: Icon(Icons.content_cut),
                  label: Text('Trim'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('Batch'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Presets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _buildBody(currentDestination),
          ),
        ],
      ),
    );
  }
}

Widget _buildBody(NavDestination destination) {
  switch (destination) {
    case NavDestination.convert:
      return const ConvertScreen();
    case NavDestination.trim:
      return const TrimScreen();
    case NavDestination.batch:
      return const BatchScreen();
    case NavDestination.presets:
      return const PresetsScreen();
    case NavDestination.settings:
      return const SettingsScreen();
  }
}
