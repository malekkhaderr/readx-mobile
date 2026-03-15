import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ReadX',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
