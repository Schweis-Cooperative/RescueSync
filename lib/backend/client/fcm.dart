// ignore_for_file: depend_on_referenced_packages, file_names, avoid_print, use_build_context_synchronously, unrelated_type_equality_checks

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:rescuesync/backend/client/auth.dart';
import 'package:rescuesync/constants/app_constants.dart';

import 'package:http/http.dart' as http;
class FCMOnProcess {
    Future<String> getAndChangeFCMToken(String username) async {
    firebase_messaging.FirebaseMessaging messaging =
    firebase_messaging.FirebaseMessaging.instance;
    String fcmToken = (await messaging.getToken())!;
    String data = await Auth().auth(username: username, action: 'changeFcm', room: fcmToken);
    // await Clipboard.setData(ClipboardData(text: fcmToken!));
    // print("FCM Token: $fcmToken");
    if(data != 'None')  {
      return fcmToken;
    } else {
      return 'null';
    }
    
    }

  void getPermission() async {
    firebase_messaging.FirebaseMessaging messaging =
        firebase_messaging.FirebaseMessaging.instance;

    // ignore: unused_local_variable
    firebase_messaging.NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

   //  print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<dynamic> sendFcmNotification({
  required String callerName,
  required String receiverName,
  required int duration,
  required String startTime,
}) async {
  var client = http.Client();

  try {
    String fcmForCalling = await Auth().auth(username: receiverName, action: 'getFcm');
    Map<String, String> body = {
      'callerName': callerName,
      'receiverName': receiverName,
      'duration': duration.toString(),
      'startTime': startTime,
      'fcmToken': fcmForCalling,
    };
    // 2. Send FCM Notification
    var response = await client.post(
      Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.fcmEndpoint}'),
      body: body,
    );

    // ignore: unused_local_variable
    var responseBody = utf8.decode(response.bodyBytes);
    print('FCM Response Body: $responseBody');

    if (response.statusCode == 200) {
      return 'Bildirim başarıyla gönderildi!';
    } else {
      return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
    }
  } catch (e) {
    return 'Exception: $e';
  } finally {
    client.close();
  }
}
}