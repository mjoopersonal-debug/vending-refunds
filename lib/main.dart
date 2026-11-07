import 'package:flutter/material.dart';
import 'app_alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAlarm.init();
  runApp(const AlarmTestApp());
}

class AlarmTestApp extends StatelessWidget {
  const AlarmTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vending Refunds',
      navigatorKey: navKey,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD81860),
        useMaterial3: true,
      ),
      home: const AlarmTestPage(),
    );
  }
}

class AlarmTestPage extends StatelessWidget {
  const AlarmTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOFTIES Alarm Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => AppAlarm.setup(),
                child: const Text('Alarm setup'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => AppAlarm.test(),
                child: const Text('Test alarm (30 seconds)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
