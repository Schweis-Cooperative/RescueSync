/// Application-wide constants
class AppConstants {
  // Invite code configuration
  static const int inviteCodeLength = 9;
  static const int inviteCodeMin = 0;
  static const int inviteCodeMax = 999999999;

  // Alarm/SOS configuration
  static const int defaultAlarmDuration = 30; // seconds
  static const double defaultVolume = 1.0;
  static const double defaultFadeDuration = 5.0;
  static const String defaultAudioPath = 'assets/alarm/genclik.mp3';
  static const String defaultNotificationTitle = 'EMERGENCY CALL';
  static const String defaultNotificationBody = 'You are being called by user!';

  // User validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;

  // API configuration
  static const String apiBaseUrl = 'https://api.nativez.dev';
  static const String apiEndpoint = '/rescuesync/process';
  static const String fcmEndpoint = '/rescuesync/fcm';

  // Notification channel
  static const String notificationChannelId = 'put_alarm_channel';
  static const String notificationChannelName = 'Start Alarm Channel';

  // App version
  static const String appVersion = 'v0.1.0';
  static const String appName = 'RescueSync';
  static const bool isBeta = true;
}
