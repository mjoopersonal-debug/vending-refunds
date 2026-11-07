import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Give this to MaterialApp(navigatorKey: navKey) so the ring screen can open by itself.
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// Reusable alarm: rings at an exact time for 5 minutes, even when the app is closed or the phone is locked.
class AppAlarm {
  static Timer? _stopTimer;

  /// A stable number for any text key such as 'task-42' (the same text always gives the same number).
  static int idFor(String key) {
    var h = 0x811c9dc5;
    for (final c in key.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  /// Call once in main(): await AppAlarm.init();
  /// Pass ringBuilder if you want your own ring screen instead of the built-in one.
  static Future<void> init({Widget Function(AlarmSettings s)? ringBuilder}) async {
    await Alarm.init();
    Alarm.ringStream.stream.listen((s) {
      _stopTimer?.cancel();
      _stopTimer = Timer(const Duration(minutes: 5), () => Alarm.stop(s.id));
      navKey.currentState?.push(MaterialPageRoute(builder: (_) => ringBuilder != null ? ringBuilder(s) : RingScreen(settings: s)));
    });
  }

  static Future<void> _set(int id, DateTime when, String title, String body) => Alarm.set(
        alarmSettings: AlarmSettings(
          id: id,
          dateTime: when,
          assetAudioPath: 'assets/alarm.wav',
          loopAudio: false,
          vibrate: true,
          volumeSettings: VolumeSettings.fixed(volume: 1.0),
          notificationSettings: NotificationSettings(title: title, body: body),
          warningNotificationOnKill: true,
        ),
      );

  /// Set (or replace) the alarm for [key]. Returns false if the time is already past.
  static Future<bool> schedule({required String key, required DateTime when, required String title, required String body}) async {
    await Alarm.stop(idFor(key));
    if (!when.isAfter(DateTime.now())) return false;
    await _set(idFor(key), when, title, body);
    return true;
  }

  /// Use at app start for every saved item. Never stops an alarm that is ringing right now.
  static Future<void> restore({required String key, required DateTime when, required String title, required String body}) async {
    if (when.isAfter(DateTime.now())) await _set(idFor(key), when, title, body);
  }

  static Future<void> cancel(String key) async {
    await Alarm.stop(idFor(key));
  }

  /// Button "Alarm setup": asks for the permissions an alarm needs.
  static Future<void> setup() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  /// Button "Test alarm": rings in 30 seconds.
  static Future<void> test() => _set(999999, DateTime.now().add(const Duration(seconds: 30)), 'Test alarm', 'Your alarm works');

  static void stopRinging(int id) {
    _stopTimer?.cancel();
    Alarm.stop(id);
  }

  /// Rings again in [minutes].
  static Future<void> snooze(AlarmSettings s, {int minutes = 10}) async {
    stopRinging(s.id);
    await _set(s.id, DateTime.now().add(Duration(minutes: minutes)), s.notificationSettings.title, s.notificationSettings.body);
  }
}

class RingScreen extends StatelessWidget {
  final AlarmSettings settings;
  const RingScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white, fontSize: 18);
    return Scaffold(
      backgroundColor: const Color(0xFFD9381E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⏰', style: TextStyle(fontSize: 64)),
              Text(settings.notificationSettings.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(settings.notificationSettings.body, textAlign: TextAlign.center, style: white),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                onPressed: () {
                  AppAlarm.stopRinging(settings.id);
                  Navigator.pop(context);
                },
                child: const Padding(padding: EdgeInsets.all(14), child: Text('STOP', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: () async {
                  await AppAlarm.snooze(settings);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Snooze 10 minutes'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
