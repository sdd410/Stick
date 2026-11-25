import 'package:flutter/material.dart';

import '../../theme.dart';

/// Bottom tabs: Home, Progress, Messages, Settings. Back on another tab
/// returns to Home; back on Home leaves the app.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.tab,
    required this.home,
    required this.progress,
    required this.messages,
    required this.settings,
  });

  /// The selected tab (0 = Home). Owned by the caller so screens can switch.
  final ValueNotifier<int> tab;
  final Widget home;
  final Widget progress;
  final Widget messages;
  final Widget settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: tab,
    builder: (context, i, _) => PopScope(
      canPop: i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) tab.value = 0;
      },
      child: Scaffold(
        body: IndexedStack(
          index: i,
          children: [home, progress, messages, settings],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (n) => tab.value = n,
          backgroundColor: const Color(0xFF111119),
          indicatorColor: StickColors.lime,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: StickColors.bg),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              selectedIcon: Icon(
                Icons.bar_chart_rounded,
                color: StickColors.bg,
              ),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle, color: StickColors.bg),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: StickColors.bg),
              label: 'Settings',
            ),
          ],
        ),
      ),
    ),
  );
}
