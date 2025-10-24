// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:real_volume/real_volume.dart';
import 'package:rescuesync/constants/app_constants.dart';

class PlaySOS {
  void setAlarmSettings(String username, int id,
      {int time = AppConstants.defaultAlarmDuration,
      String title = AppConstants.defaultNotificationTitle,
      String body = AppConstants.defaultNotificationBody,
      bool loopAudio = false,
      bool vibrate = true,
      double volume = AppConstants.defaultVolume,
      String assetAudioPath = AppConstants.defaultAudioPath,
      double fadeDuration = AppConstants.defaultFadeDuration,
      bool androidFullScreenIntent = true,
      bool volumeEnforced = true,
      String dateTime = 'now'}) {
    // ignore: unnecessary_null_comparison
    if (username == null || id == null) {
      throw ArgumentError('username ve id parametreleri null olamaz.');
    }

    if (dateTime == 'now') {
      final alarmSettings = AlarmSettings(
        id: id,
        volume: volume,
        vibrate: vibrate,
        loopAudio: loopAudio,
        fadeDuration: fadeDuration,
        androidFullScreenIntent: androidFullScreenIntent,
        warningNotificationOnKill: Platform.isAndroid,
        dateTime: DateTime.now(),
        assetAudioPath: assetAudioPath,
        volumeEnforced: volumeEnforced,
        notificationSettings: NotificationSettings(
          title: title,
          body: username + body,
          icon: 'android/app/src/main/res/drawable/ic_launcher.png',
        ),
      );

      Alarm.set(alarmSettings: alarmSettings);

      Timer(Duration(seconds: time), () async {
        await Alarm.stop(id);
      });
    }
  }

  Future<void> playMp3InBackground() async {
  final AudioPlayer audioPlayer = AudioPlayer()
    ..setAudioContext(AudioContext(
        android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media)));

  Timer? volumeControlTimer;

  try {
    bool? isPermissionGranted = await RealVolume.isPermissionGranted();

    if (!isPermissionGranted!) {
      // Opens Do Not Disturb Access settings to grant the access
      await RealVolume.openDoNotDisturbSettings();
    }
    // Ses dosyasını asset'ten yükle
    await audioPlayer.setSourceAsset('alarm/alarm.mp3');

    // Ses seviyesini maksimuma çek

    // Control volume for alarm duration
    volumeControlTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      await RealVolume.setVolume(AppConstants.defaultVolume,
          showUI: false, streamType: StreamType.MUSIC);
    });

    // Start playback in loop mode
    await audioPlayer.resume();
    await audioPlayer.setReleaseMode(ReleaseMode.loop);

    // Stop after default duration
    Timer(const Duration(seconds: AppConstants.defaultAlarmDuration), () async {
      await audioPlayer.stop();
      print('Alarm durduruldu');
    });
  } catch (e) {
    print("Hata: ${e.toString()}");
  }
}
}

