import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:money_tracker/core/providers/repository_providers.dart";
import "package:money_tracker/core/router.dart";
import "package:money_tracker/core/theme/app_theme.dart";
import "package:money_tracker/core/theme/text_theme.dart";

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;

  final container = ProviderContainer();

  await container.read(appStartupServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = createTextTheme(context, "Roboto", "Roboto");

    const themeColor = Color(0xFFFFD54F);

    return MaterialApp.router(
      theme: AppTheme.light(themeColor, textTheme),
      darkTheme: AppTheme.dark(themeColor, textTheme),
      themeMode: ThemeMode.dark,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,

    );
  }
}
