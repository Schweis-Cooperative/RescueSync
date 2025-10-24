// ignore_for_file: depend_on_referenced_packages, file_names, avoid_print, use_build_context_synchronously, unrelated_type_equality_checks

// Varsayılan dart paketlerini projeye dahil ediyoruz
import 'dart:async';
import 'dart:io';

// Flutter paketlerini projeye dahil ediyoruz, burada firebase_mesagging bölümünü ayırt etmemizin bir sebebi var;
// Alarm paketimizde de Notification ile alakalı bir sınıf var, firebase mesagging'te de
// Ve bunlar çakışıyor, bunları ayırmamız lazım. Bu yüzden bu yöntemi kullanıyoruz.
import 'package:firebase_messaging/firebase_messaging.dart'
    as firebase_messaging;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
// Artık kendi sınıflarımızı ve fonksiyonlarımızı projeye dahil edebiliriz. Bunlar gözünü korkutmasın.
import 'package:rescuesync/backend/client/fcm.dart';
import 'package:rescuesync/backend/client/sos.dart';
import 'package:rescuesync/backend/client/auth.dart';
import 'package:rescuesync/backend/client/getx.dart';
import 'package:rescuesync/main.dart';
import 'package:rescuesync/screens/aboutScreen.dart';
import 'package:rescuesync/screens/authScreen.dart';
import 'package:rescuesync/screens/settingsScreen.dart';
import 'package:rescuesync/constants/app_constants.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final box = GetStorage();
  final UserController userController = Get.put(UserController());
  final PlaySOS _playSOS = PlaySOS();
  final FCMOnProcess _fcmOnProcess = FCMOnProcess();
  final Auth _auth = Auth();
  String username = '';
  String? role;
  String? room;
  String? fcmToken;
  bool? status;

  List<Map<String, String>> users = [];

  bool isLoading = true;

  connectionChecker() async {
    bool status = await InternetConnection().hasInternetAccess;
    return status;
  }

  Future<void> _initializeData() async {
  // İnternet bağlantısını kontrol et.
  bool isConnected = await connectionChecker();

  if (isConnected) {
    checkUsername();
    username = box.read('username') ?? 'NULL';
    _fcmOnProcess.getPermission();
    await _fcmOnProcess.getAndChangeFCMToken(username);

    // Kullanıcı bilgilerini çek.
    await userController.fetchRole(username);
    await userController.fetchInvite(username);
    await userController.fetchRoom(username);

    // Firebase Messaging dinleyici ekle.
    firebase_messaging.FirebaseMessaging.onMessage.listen(
      (firebase_messaging.RemoteMessage message) {
        if (message.data.isNotEmpty) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            importance: Importance.high,
            priority: Priority.high,
          );

          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          flutterLocalNotificationsPlugin.show(
            0,
            message.notification?.title,
            message.notification?.body,
            platformChannelSpecifics,
          );

          if (message.data['receiver'] == username) {
            _playSOS.setAlarmSettings(
              message.data['caller'],
              int.parse(message.data['receiver_id']),
            );
          }
        }
      },
    );

    AwesomeDialog(
            context: context,
            animType: AnimType.scale,
            dialogType: DialogType.info,
            body: const Center(child: Text(
                    'This application is in beta version. Please use it with this awareness. Report any issues to the support team or create a pull request on the Github repository.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),),
            title: 'BETA',
            desc:   '${AppConstants.appName} BETA',
            btnOkOnPress: () {
            },
            ).show();
  } else {
    // Eğer bağlantı yoksa durumu ayarla.
    setState(() {
      status = false;
    });


    AwesomeDialog(
            context: context,
            animType: AnimType.scale,
            dialogType: DialogType.error,
            body: const Center(child: Text(
                    'Lütfen internet bağlantınızı kontrol ediniz veya uygulama ayarlarından interneti açınız.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),),
            title: 'Bağlantı hatası',
            desc:   'Bağlantınızı Kontrol ediniz',
            btnOkOnPress: () {
              exit(1);
            },
            ).show();
    
  }
}

  Future checkUsername() async {
    String nickname = box.read('username') ?? 'null';
    dynamic users = await _auth.auth(username: nickname, action: 'getId');

    // Check if user data is invalid or contains errors
    bool isInvalidUser = nickname == 'null' ||
        users == null ||
        users == 'None' ||
        users.toString().contains('SQLSTATE') ||
        users.toString().contains('Error:') ||
        users.toString().contains('Exception:');

    if (isInvalidUser) {
      box.erase();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (builder) => const AuthScreen()));
      return 'NULL';
    }

    setState(() {
      username = nickname;
    });
  }

  @override
  void initState() {
    super.initState();

    // playMp3InBackground();

    _initializeData();
  }

  Future<void> fetchUsers() async {
    if (userController.room.value != 'None' &&
        userController.room.value != 'Loading...' &&
        userController.room.value != false) {
      try {
        final fetchedUsers =
            await userController.getUsers(username, userController.room.value);
        setState(() {
          users = fetchedUsers;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            onPressed: () => _auth.logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                "Hello, $username\n\n${AppConstants.appName} Android App ${AppConstants.appVersion}",
                style: const TextStyle(
                  color: Color.fromARGB(255, 99, 71, 71),
                  fontSize: 18,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (builder) => SettingsScreen(
                              userRole: userController.role.value,
                              roomCode: userController.room.value,
                              users: users,
                            )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (builder) => const AboutScreen()));
              },
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (status == false) {
          return Container();
        } else {
        String role = userController.role.value;
        String invite = userController.invite.value;
        String room = userController.room.value;
        // print('Role: $role');
        // print('Davet Kodu: $invite');
        // print('Kullanıcının bulunduğu odanın kodu: $room');

        if (invite == 'Loading...' || username == 'NULL') {
          return const Center(child: CircularProgressIndicator());
        }

        if (room != 'None' && room != 'Loading...' && role != 'None') {
          fetchUsers();
        } else {}

        return role == 'None' && room == 'None'
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'You are not in a room yet.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showInviteDialog(context, invite);
                      },
                      child: const Text('Share or Join'),
                    ),
                  ],
                ),
              )
            : isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'People in the Room',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      title: Text(
                                        '${users[index]['username']}, ${users[index]['role']}',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          _fcmOnProcess.sendFcmNotification(
                                            callerName: username,
                                            receiverName: users[index]
                                                ['username']!,
                                            duration: AppConstants.defaultAlarmDuration,
                                            startTime: 'now',
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('SOS'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 60.0),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                for (var user in users) {
                                  _fcmOnProcess.sendFcmNotification(
                                    callerName: username,
                                    receiverName: user['username']!,
                                    duration: AppConstants.defaultAlarmDuration,
                                    startTime: 'now',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(40),
                              ),
                              child: const Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Room Code: $room',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
        }
      
      }),
    );
  }

  void _showInviteDialog(BuildContext context, String inviteCode) {
    final inviteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share or Join'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Your Invite Code:: '),
                  Text(inviteCode,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inviteController,
                decoration: const InputDecoration(
                  labelText: "Enter someone else's invite code",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String result = await userController.joinRoom(
                    username, inviteController.text);
                // print('Room join result: $result');
                if (result == 'Room joined successfully') {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Successfully joined the room')),
                  );
                  userController.fetchRoom(username);
                  userController.fetchRole(username);
                  setState(() {
                    room = userController.room.value;
                    role = userController.role.value;
                  });
                } else {
                  // Hata mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                }
              }, // sample code: 532461133
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }
}


// finished