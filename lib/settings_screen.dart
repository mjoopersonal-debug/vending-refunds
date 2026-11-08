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
    _scheduleReminder();
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt('reminderHour', picked.hour);
    await p.setInt('reminderMinute', picked.minute);
    setState(() => _time = picked);
    await _scheduleReminder();
    if (mounted) setState(() => _note = 'Saved. Reminder at ${_time.format(context)}');
  }

  /// Sets the daily reminder for the next occurrence of the chosen time.
  Future<void> _scheduleReminder() async {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await AppAlarm.schedule(
      key: 'daily-reminder',
      when: when,
      title: 'Pending refunds',
      body: 'Please pay and mark your pending refunds as Done.',
    );
  }

  Future<void> _test() async {
    await AppAlarm.test();
    if (mounted) setState(() => _note = 'Test alarm will ring in 30 seconds.');
  }

  Future<void> _allowNotifications() async {
    await AppAlarm.setup();
    if (mounted) setState(() => _note = 'Permissions requested. Allow each one.');
  }

  Future<void> _openPhoneSettings() async {
    await openAppSettings();
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
              title: const Text('Daily reminder time'),
              subtitle: const Text('The alarm checks for Pending refunds at this time every day.'),
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
                  'New refund alerts work while the app is running in the background. '
                  'To keep it running:\n'
                  '1. Allow notifications and exact alarms (button below).\n'
                  '2. Set the app battery to "No restrictions".\n'
                  '3. On Xiaomi, Oppo, Vivo, Realme or Samsung, turn on auto-start.\n'
                  '4. Do not swipe the app away from recent apps.',
                  style: TextStyle(color: greyPlum, height: 1.4),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _allowNotifications,
            child: const Padding(padding: EdgeInsets.all(12), child: Text('Allow notifications and alarms')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _openPhoneSettings,
            child: const Padding(padding: EdgeInsets.all(12), child: Text('Open app settings (battery, auto-start)')),
          ),
          const SizedBox(height: 16),
          Text(_note, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
