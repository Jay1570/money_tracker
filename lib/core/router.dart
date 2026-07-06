import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:money_tracker/main.dart";
import "package:money_tracker/modules/accounts/add_account_screen.dart";
import "package:money_tracker/modules/home/home_screen.dart";
import "package:money_tracker/modules/reports/reports_screen.dart";

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: "/home",
    routes: [
      GoRoute(
        path: "/home",
        builder: (context, state) => const HomeScreen(),
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const HomeScreen(),
        ),
        // routes: [],
      ),
      GoRoute(
        path: "/reports",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const ReportsScreen(),
        ),
      ),
      GoRoute(
        path: "/account/add",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const AddAccountScreen(),
        ),
      ),
      GoRoute(
        path: "/",
        redirect: (_, _) => "/home",
        // routes: [],
      ),
    ],
  );
});

CustomTransitionPage<T> buildSlidePage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    child: child,
    transitionsBuilder:
        (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(offsetAnimation),
            child: child,
          );
        },
  );
}
