import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/model/notification_settings.dart';
import 'package:alarm/model/volume_settings.dart';
import 'package:permission_handler/permission_handler.dart';

class AppAlarm {
  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> setup() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  // Schedules a ringing alarm. The title and body are shown on the ringing screen.
  static Future<void> schedule({
    required String key,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: key.hashCode.abs() % 2147483647,
        dateTime: when,
        assetAudioPath: 'assets/alarm.wav',
        loopAudio: true,
        vibrate: true,
        volumeSettings: VolumeSettings.fade(
          volume: 1.0,
          fadeDuration: const Duration(seconds: 3),
        ),
        notificationSettings: NotificationSettings(
          title: title,
          body: body,
          stopButton: 'Stop',
        ),
      ),
    );
  }

  static Future<void> cancel(String key) async {
    await Alarm.stop(key.hashCode.abs() % 2147483647);
  }

  // Test alarm that rings in 30 seconds
  static Future<void> test() async {
    await schedule(
      key: 'test-alarm',
      when: DateTime.now().add(const Duration(seconds: 30)),
      title: 'Test alarm',
      body: 'This is a test of the Softies Refunds alarm.',
    );
  }
}
