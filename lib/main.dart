import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:money_tracker/core/providers/repository_providers.dart";
import "package:money_tracker/core/router.dart";
import "package:money_tracker/core/theme/app_theme.dart";
import "package:money_tracker/core/theme/text_theme.dart";
import "package:money_tracker/modules/settings/settings_provider.dart";

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;

  final container = ProviderContainer();

  await container.read(appStartupServiceProvider).initialize();
  await container.read(settingsRepositoryProvider).getSettings();

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

    final settings = ref.watch(settingsStreamProvider).value;
    final isDarkMode = settings?.darkMode ?? true;

    final themeColor = isDarkMode ? Colors.yellow : Colors.brown;

    return MaterialApp.router(
      theme: AppTheme.light(themeColor, textTheme),
      darkTheme: AppTheme.dark(themeColor, textTheme),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
