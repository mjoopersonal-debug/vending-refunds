import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_alarm.dart';
import 'main.dart' show pink, greyPlum, darkPlum;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 22, minute: 0);
  String _note = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final h = p.getInt('reminderHour') ?? 22;
    final m = p.getInt('reminderMinute') ?? 0;
    if (mounted) setState(() => _time = TimeOfDay(hour: h, minute: m));
    // Remove any old fixed daily alarm so it never rings by itself
    await AppAlarm.cancel('daily-reminder');
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt('reminderHour', picked.hour);
    await p.setInt('reminderMinute', picked.minute);
    await AppAlarm.cancel('daily-reminder');
    if (mounted) {
      setState(() {
        _time = picked;
        _note = 'Saved. The alarm rings at ${_time.format(context)} only if refunds are pending.';
      });
    }
  }

  Future<void> _test() async {
    await AppAlarm.test();
    if (mounted) setState(() => _note = 'Test alarm will ring in 30 seconds.');
  }

  Widget _card({required Widget child}) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm, color: pink),
              title: const Text('Reminder time'),
              subtitle: const Text('Rings only if there are Pending refunds at this time.'),
              trailing: Text(_time.format(context),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pink)),
              onTap: _pick,
            ),
          ),
          FilledButton(
            onPressed: _pick,
            child: const Padding(padding: EdgeInsets.all(12), child: Text('Change reminder time')),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: _test,
            child: const Padding(padding: EdgeInsets.all(12), child: Text('Test alarm now (30 seconds)')),
          ),
          const SizedBox(height: 20),
          _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep alerts working',
                    style: TextStyle(color: darkPlum, fontSize: 17, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'New refund alerts and the reminder work while the app is running in the background.\n'
                  '1. Allow notifications and alarms (button below).\n'
                  '2. Set the app battery to "No restrictions".\n'
                  '3. On Xiaomi, Oppo, Vivo, Realme or Samsung, turn on auto-start.\n'
                  '4. Do not swipe the app away from recent apps.',
                  style: TextStyle(color: greyPlum, height: 1.4),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => AppAlarm.setup(),
            child: const Padding(padding: EdgeInsets.all(12), child: Text('Allow notifications and alarms')),
          ),
          const SizedBox(height: 16),
          Text(_note, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
