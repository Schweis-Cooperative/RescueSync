// ignore_for_file: avoid_print

// Import Flutter packages
import 'package:alarm/alarm.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

// Import our custom functions and classes
import 'package:rescuesync/backend/client/sos.dart';
import 'package:rescuesync/screens/authScreen.dart';
import 'package:rescuesync/screens/homeScreen.dart';
import 'package:rescuesync/constants/app_constants.dart';


// Bu değişken ile flutter local bildirim plugin sınıfını, değişkene aktarıyoruz.
// Böylelikle bu sınıftaki fonksiyonları kullanabileceğiz.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


// Bu sınıf oldukça önemli, uygulama arka plandayken bildirimleri dinlemek istiyorsak;
// Bildirim dinleme fonksiyonunu bir widgeta değil, main fonksiyonuna gömmemiz gerekiyor.
// Mantıklı düşününce, eğer widget telefon ekranında açık olmazsa, fonksiyon çalışmaz.
// Arka planda ise widget teknik olarak açık olmaz.
void initializeNotifications() async {
  // Set notification alarm
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    AppConstants.notificationChannelId,
    AppConstants.notificationChannelName,
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// Arka plan bildirim dinleme konusunda hangi bölgelerin çalışıp çalışmadığını anlamak için oluşturulmuş debug print kodları mevcuttur.
// Ön plan bildirim dinleme konusunda biz, username eşleşmesi arıyoruz fakat burada bunu aramıyoruz
// Çünkü burada box içerisindeki veri null olarak döndürülüyor. Bunun üstünde çalışıyoruz
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  // print('data 1');
  if (message.data.isNotEmpty) {
    // print('data 2');

    // Connect notification channel
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    // print('data 3');

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
    
    // Play background alarm
    PlaySOS().playMp3InBackground();

    // String username = message.data['receiver'];
    
    // print('on play function');
  }
}




void main() async {
  // Widget başlatma işlemi, çoğu şey için (firebase dahil) gerekli
  // Burada, paketlerimizi main içerisinde başlatıyoruz ve hazır hale getirmek için widgetlar içerisinde kodluyoruz.
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp();
  initializeNotifications();
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);
  await Alarm.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    // Box içerisinde giriş yapıldı mı? yapılmadı mı? Bu veriye göre kullanıcıya yansıtılacak widget seçiliyor
    bool isLoggedIn = box.read('isLoggedIn') ?? false;


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: isLoggedIn ? const Homescreen() : const AuthScreen(),
    );
  }}