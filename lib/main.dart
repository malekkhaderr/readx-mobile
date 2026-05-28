import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/data/book_repository.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    return Material(
      color: Colors.transparent,
      child: Center(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(details.exceptionAsString(), style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
      )),
    );
  };

  await di.init();
  await BookRepository.init();

  final prefs = di.sl<SharedPreferences>();
  final themeProvider = ThemeProvider(prefs);
  di.sl.registerSingleton<ThemeProvider>(themeProvider);

  di.sl<DioClient>().registerUnauthorizedHandler(() {
    AppRouter.router.go('/welcome');
  });

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatefulWidget {
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.themeProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.themeProvider.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    widget.themeProvider.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final brightness = widget.themeProvider.isDark ? Brightness.dark : Brightness.light;
    AppColors.updateBrightness(brightness);

    return MaterialApp.router(
      title: 'Readora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.themeProvider.mode,
      routerConfig: AppRouter.router,
    );
  }
}
