import "package:flutter/cupertino.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:money_tracker/main.dart";

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: "/home",
    routes: [
      GoRoute(
        path: "/home",
        builder: (context, state) => const SizedBox(),
        // routes: [],
      ),
    ],
  );
});
