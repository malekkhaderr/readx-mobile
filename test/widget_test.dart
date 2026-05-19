import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readx/core/di/injection_container.dart' as di;
import 'package:readx/core/data/book_repository.dart';
import 'package:readx/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await di.sl.reset();
  });

  testWidgets('App smoke test - Welcome screen loads successfully', (WidgetTester tester) async {
    // Initialize dependency injection and mock repositories
    await di.init();
    await BookRepository.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that our welcome screen loads and displays the app name.
    expect(find.text('Readora'), findsOneWidget);
    expect(find.text('Read more. Learn more. Every day.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
