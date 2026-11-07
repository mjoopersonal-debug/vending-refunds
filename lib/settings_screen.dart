import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_alarm.dart';
import 'main.dart' show pink;

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
    setState(() => _time = TimeOfDay(hour: h, minute: m));
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

  /// Sets the daily reminder alarm for the next occurrence of the chosen time.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.alarm, color: pink),
                title: const Text('Daily reminder time'),
                subtitle: const Text('The alarm checks for Pending refunds at this time every day.'),
                trailing: Text(_time.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pink)),
                onTap: _pick,
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => AppAlarm.setup(),
              child: const Padding(padding: EdgeInsets.all(12), child: Text('Alarm setup (permissions)')),
            ),
            const SizedBox(height: 16),
            Text(_note, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
