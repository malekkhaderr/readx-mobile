import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/data/book_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace the giant red 'Null check operator used on a null value'
  // overlay with a small empty space. Without this, ONE broken paragraph
  // inside the EPUB reader (e.g. an <a href=null> link or an unsupported
  // CSS tag inside flutter_html) takes over the entire screen — even
  // though the surrounding widgets are fine.
  // The error still goes to the console via dumpErrorToConsole so the
  // dev team can investigate; the user just doesn't see a hostile screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    return const SizedBox.shrink();
  };

  await di.init();
  await BookRepository.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Readora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
