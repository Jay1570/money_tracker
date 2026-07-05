import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:money_tracker/core/router.dart";
import "package:money_tracker/core/theme/app_theme.dart";
import "package:money_tracker/core/theme/text_theme.dart";

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = createTextTheme(context, "Roboto", "Roboto");

    return MaterialApp.router(
      theme: AppTheme.light(Color(0xFF2563EB), textTheme),
      darkTheme: AppTheme.dark(Color(0xFF2563EB), textTheme),
      themeMode: ThemeMode.dark,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
