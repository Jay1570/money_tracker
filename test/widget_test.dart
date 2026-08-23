import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Pump twice without a duration to flush routing microtasks
    await tester.pump();
    await tester.pump();

    // Verify that the home screen is displayed.
    expect(find.text('Money Tracker'), findsOneWidget);
  });
}
