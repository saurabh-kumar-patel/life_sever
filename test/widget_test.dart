import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_saver/services/ai_service.dart';
import 'package:life_saver/main.dart';

void main() {
  testWidgets('Dashboard renders successfully smoke test', (WidgetTester tester) async {
    // Setup Mock Initial Values for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final aiService = AiService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(prefs: prefs, aiService: aiService));
    await tester.pumpAndSettle();

    // Verify that our app bar header text renders.
    expect(find.text('LIFESAVER AI'), findsOneWidget);

    // Verify that dashboard sections render
    expect(find.text('YOUR DEADLINE SHIELD'), findsOneWidget);
    expect(find.text('AI COPILOT RECOMMENDATION'), findsOneWidget);
  });
}
