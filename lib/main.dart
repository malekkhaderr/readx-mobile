import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ReadX',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('ReadX'))),
    );
  }
}
