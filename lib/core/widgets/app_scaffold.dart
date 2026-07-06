import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:money_tracker/core/widgets/app_bottom_bar.dart';
import 'package:money_tracker/core/widgets/bottom_bar_item.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.showBottomBar = true,
    this.showFabButton = true,
    this.onFabPressed,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool showBottomBar;
  final bool showFabButton;
  final VoidCallback? onFabPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    final currentItem = BottomBarItem.fromLocation(
      GoRouterState.of(context).uri.path,
    );

    return Scaffold(
      backgroundColor: const Color(0xff171717),
      appBar: appBar,
      body: SafeArea(child: body),
      bottomNavigationBar: showBottomBar
          ? AppBottomBar(
              currentItem: currentItem,
              onTap: (item) {
                if (item.route != currentItem.route) {
                  context.go(item.route);
                }
              },
            )
          : null,
      floatingActionButton: showFabButton
          ? FloatingActionButton(
              backgroundColor: theme.primary,
              foregroundColor: theme.onPrimary,
              shape: const CircleBorder(),
              onPressed: onFabPressed,
              child: const Icon(Icons.add, size: 36),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
