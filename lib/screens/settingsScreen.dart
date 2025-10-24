// ignore_for_file: depend_on_referenced_packages, file_names

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rescuesync/backend/client/fcm.dart';
import 'package:rescuesync/backend/client/getx.dart';
import 'package:rescuesync/backend/client/updateSettings.dart';
import 'package:rescuesync/screens/homeScreen.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  final String roomCode;
  final List<Map<String, String>> users;
  const SettingsScreen(
      {super.key,
      required this.userRole,
      required this.roomCode,
      required this.users});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 'owner', 'moderator' veya 'member'
  final UpdateData _updateData = UpdateData();
  late Map<String, dynamic> _updateDataSettings = {};
  final kutu = GetStorage();
  bool _isLoading = true;
  String _errorMessage = '';
  TextEditingController newUsername = TextEditingController();
  TextEditingController newEmail = TextEditingController();
  TextEditingController newPassword = TextEditingController();
  late TextEditingController newTitle;
  late TextEditingController newBody;
  late TextEditingController newTime;
  final UserController userController = Get.put(UserController());
  final FCMOnProcess _fcmOnProcess = FCMOnProcess();
  bool? value;
  bool? loopAudio;
  double? volume;

  String username = '';

  final RxString _selectedAudioPath = 'assets/alarm/alarm.mp3'.obs;

  bool? vibrate;

  @override
  void initState() {
    super.initState();
    newTitle = TextEditingController();
    newBody = TextEditingController();
    newTime = TextEditingController();

  

    _loadRoomSettings();
    username = kutu.read('username');

  }

  Future<void> _loadRoomSettings() async {
    try {
      final settings = await _fetchSettingsBasedOnRole();
      setState(() {
        _updateDataSettings = settings;

        newTitle.text = _updateDataSettings['getTitle']?.toString() ?? '';
        newBody.text = _updateDataSettings['getBody']?.toString() ?? '';
        newTime.text = _updateDataSettings['getDuration']?.toString() ?? '';
        _selectedAudioPath.value =
            _updateDataSettings['getAudioPath'] ?? 'assets/alarm/alarm.mp3';
        _isLoading = false;
          if(_updateDataSettings['getVibrate'] == 'true') {
            vibrate = true;
          } else {
            vibrate = false;
          }
          if(_updateDataSettings['getLoopAudio'] == '1') {
            loopAudio = true;
          } else {
            loopAudio = false;
          }

      

          

          // print(_updateDataSettings['getFullScreenIntent']);


           if(_updateDataSettings['getFullScreenIntent'] == 'true') {
            value = true;
          } else {
            value = false;
          }

      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchSettingsBasedOnRole() async {
    final Map<String, dynamic> settings = {};
    final List<String> actions = [];

    // Common settings for all roles
    actions.addAll([
      'getDuration',
      'getTitle',
      'getBody',
      'getVibrate',
      'getVolume',
      'getFullScreenIntent'
    ]);

    // Role-specific settings
    if (widget.userRole == 'owner' || widget.userRole == 'moderator') {
      actions.addAll(['getAudioPath', 'getLoopAudio', 'getFadeDuration']);
    }

    for (var action in actions) {
      try {
        final result = await _updateData.getRoom(
          roomCode: widget.roomCode,
          action: action,
        );
        settings[action] = result;
      } catch (e) {
        print('Error fetching $action: $e');
      }
    }

    return settings;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(_errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (builder) => const Homescreen()),
              );
            },
            icon: const Icon(Icons.turn_left_rounded),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAccountSettings(),
                const SizedBox(height: 20),
                _buildRoomSettings(),
                const SizedBox(height: 20),
                _buildNotificationSettings(),
              ],
            ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        title: const Text('Hesap Ayarları', style: TextStyle(fontSize: 18)),
        children: [
          _buildSettingItem(
              'Kullanıcı Adı Değiştir',
              Icons.person,
              TextFormField(
                controller: newUsername,
                decoration:
                    const InputDecoration(labelText: 'Yeni Kullanıcı Adı'),
              )),
          _buildSettingItem(
              'Şifre Değiştir',
              Icons.lock,
              TextFormField(
                obscureText: true,
                controller: newPassword,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
              )),
          _buildSettingItem(
              'Email Değiştir',
              Icons.email,
              TextFormField(
                controller: newEmail,
                decoration: const InputDecoration(labelText: 'Yeni Email'),
              )),
          _buildActionButton('FCM Token Yenile', Icons.refresh, Colors.blue,
              () async {
            String data = await _fcmOnProcess.getAndChangeFCMToken(username);
            if (data != 'null') {
              const snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Success!',
                  message: 'FCM Token başarıyla yenilendi.',
                  contentType: ContentType.success,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            }
          }),
          widget.userRole != 'owner'
              ? _buildActionButton(
                  'Invite Kodunu Yenile', Icons.refresh, Colors.red, () async {
                  await userController.changeInvite(username, widget.roomCode);
                  if (userController.changedInvite.value != 'None') {
                    // print(userController.changedInvite.value);
                    const snackBar = SnackBar(
                      elevation: 0,
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.transparent,
                      content: AwesomeSnackbarContent(
                        title: 'Success!',
                        message: 'Invite kodu başarıyla yenilendi.',
                        contentType: ContentType.success,
                      ),
                    );

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(snackBar);
                  }
                })
              : Container(),
          InkWell(
            onTap: () async {
              // Tüm controller ve ilgili action değerlerini bir listeye ekliyoruz
              final updates = [
                {'controller': newUsername, 'action': 'changeUsername'},
                {'controller': newPassword, 'action': 'changePassword'},
                {'controller': newEmail, 'action': 'changeMail'},
              ];

              // Boş olmayan controller'ları filtreleyip sırayla çalıştırıyoruz
              for (var update in updates) {
                final controller =
                    update['controller'] as TextEditingController;
                final action = update['action'] as String;

                if (controller.text.isNotEmpty) {
                  String response = await _updateData.changeAccountData(
                    username: username,
                    data: controller.text,
                    action: action,
                  );

                  // changeUsername özel kontrolü
                  if (action == 'changeUsername' && response == username) {
                    kutu.write('username', controller.text);

                    setState(() {
                      username = controller.text;
                    });

                    // Başarı durumunda snackbar gösteriliyor
                    const snackBar = SnackBar(
                      elevation: 0,
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.transparent,
                      content: AwesomeSnackbarContent(
                        title: 'Success!',
                        message: 'Değişiklikler başarıyla kaydedildi.',
                        contentType: ContentType.success,
                      ),
                    );

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(snackBar);
                  } else if (response != 'None' && newUsername.text.isEmpty) {
                    // Diğer action'lar için kontrol
                    const snackBar = SnackBar(
                      elevation: 0,
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.transparent,
                      content: AwesomeSnackbarContent(
                        title: 'Success!',
                        message: 'Değişiklikler başarıyla kaydedildi.',
                        contentType: ContentType.success,
                      ),
                    );

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(snackBar);
                    print('$action başarılı: $response');
                  }

                  // İşlemden sonra ilgili text alanını temizliyoruz
                  controller.clear();
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Container(
                height: 50,
                decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.all(Radius.circular(15.0))),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      Text(' Değişiklikleri Kaydet',
                          style: TextStyle(
                              fontSize: 14.0, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoomSettings() {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        title: const Text('Oda Ayarları', style: TextStyle(fontSize: 18)),
        children: [
          if (widget.userRole == 'owner') ...[
            _buildUserManagementSection(),
            _buildRoleManagementSection(),
            // _buildSoundSettings(),
            _buildNotificationCustomization(),
            _buildSaveButton(),
          ],
          if (widget.userRole == 'moderator') ...[
            _buildRoleManagementSection(),
            _buildNotificationCustomization(),
            _buildSaveButton(),
          ],
          if (widget.userRole == 'member') ...[
            _buildNotificationCustomization(),
            _buildSaveButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        title: const Text('Bildirim Ayarları', style: TextStyle(fontSize: 18)),
        children: [
          _buildSwitchSetting(
            'Titreşim',
            Icons.vibration,
            vibrate!,
            (newValue) {
                setState(() {
                  vibrate = newValue;
                });
            },
          ),
          _buildSliderSetting(
            'Ses Seviyesi',
            Icons.volume_up,
            0.5,
          ),
          _buildSwitchSetting(
            'Tam Ekran Bildirim',
            Icons.fullscreen,
             value!,
            (newValue) {
                setState(() {
                  value = newValue;
                });
            },
          ),
          Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () async {
          String response = await _updateData.changeRoomData(username: username, roomCode: widget.roomCode, data: vibrate!, action: 'changeVibrate');
          String responseScreen = await _updateData.changeRoomData(username: username, roomCode: widget.roomCode, data: value!, action: 'changeFullScreenIntent');
          if(response == 'True' && responseScreen == 'True') {
             const snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'Success!',
                    message: 'Değişiklikler başarıyla kaydedildi.',
                    contentType: ContentType.success,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
          }

          print(response);
          print(responseScreen);
        },
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save),
                Text(' Değişiklikleri Kaydet',
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCustomization() {
    return Column(
      children: [
        _buildSettingItem(
          'Varsayılan Süre (sn)',
          Icons.timer,
          TextFormField(
            controller: newTime,
            // initialValue:
            //    _updateDataSettings['getDuration']?.toString() ?? '30',
            keyboardType: TextInputType.number,
          ),
        ),
        _buildSettingItem(
          'Bildirim Başlığı',
          Icons.title,
          TextFormField(
            controller: newTitle,
            // initialValue:
            //   _updateDataSettings['getTitle'] ?? 'ACİL DURUM ÇAĞRISI',
          ),
        ),
        _buildSettingItem(
          'Bildirim İçeriği',
          Icons.description,
          TextFormField(
            controller: newBody,
            // initialValue: _updateDataSettings['getBody'] ??
            //    'Kullanıcısı tarafından çağrılıyorsunuz!',
          ),
        ),
        if (widget.userRole != 'member')
          _buildSwitchSetting(
            'Ses Döngüsü',
            Icons.loop,
             loopAudio!,
            (newValue) {
                setState(() {
                  loopAudio = newValue;
                });
            },
          ),
        if (widget.userRole != 'member')
          _buildSliderSetting(
            'Fade Süresi',
            Icons.timer,
            5.0,
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () async {
          // Tüm controller ve ilgili action değerlerini bir listeye ekliyoruz
          final updates = [
            {'controller': newTime, 'action': 'changeDuration'},
            {'controller': newTitle, 'action': 'changeTitle'},
            {'controller': newBody, 'action': 'changeBody'},
          ];

          // Boş olmayan controller'ları filtreleyip sırayla çalıştırıyoruz
          for (var update in updates) {
            final controller = update['controller'] as TextEditingController;
            final action = update['action'] as String;

            if (controller.text.isNotEmpty) {
              String response = await _updateData.changeRoomData(
                username: username,
                roomCode: widget.roomCode,
                data: controller.text,
                action: action,
              );

              print(response);

              if (response == 'True') {
// Diğer action'lar için kontrol
                const snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'Success!',
                    message: 'Değişiklikler başarıyla kaydedildi.',
                    contentType: ContentType.success,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
                print('$action başarılı: $response');
              }

              // İşlemden sonra ilgili text alanını temizliyoruz
              controller.clear();
            }
          }
        },
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save),
                Text(' Değişiklikleri Kaydet',
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Kullanıcı Yönetimi',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        _buildUserListTile('Kullanıcı 1', 'user1@example.com'),
        _buildUserListTile('Kullanıcı 2', 'user2@example.com'),
      ],
    );
  }

  Widget _buildRoleManagementSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Rol Yönetimi',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        _buildRoleDropdown(),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Çıkış Yap'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () {},
      ),
    );
  }

  // Ortak Widgetlar
  Widget _buildSettingItem(String title, IconData icon, Widget input) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        softWrap: true,
      ),
      trailing: SizedBox(width: 140, child: input),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: TextStyle(color: color)),
        trailing: IconButton(
            icon: Icon(Icons.arrow_forward, color: color), onPressed: () {}),
      ),
    );
  }

Widget _buildSwitchSetting(
  String title,
  IconData icon,
  bool value,
  ValueChanged<bool> onChanged,
) {
  return SwitchListTile(
    title: Text(title),
    secondary: Icon(icon),
    value: value,
    onChanged: onChanged,
  );
}

  Widget _buildSliderSetting(String title, IconData icon, double value) {
    return ListTile(
      leading: Icon(icon),
      title: Slider(
        value: value,
        min: 0,
        max: 10,
        divisions: 10,
        label: value.toString(),
        onChanged: (double value) {},
      ),
    );
  }

  Widget _buildUserListTile(String name, String email) {
    return ListTile(
      title: Text(name),
      subtitle: Text(email),
      trailing: widget.userRole == 'owner'
          ? IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {})
          : null,
    );
  }

  Widget _buildRoleDropdown() {
    return ListView.builder(
      shrinkWrap: true, // Bu satırı ekleyin
      physics: const NeverScrollableScrollPhysics(), //
      itemCount: widget.users.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  '${widget.users[index]['username']}',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: DropdownButton<String>(
                  value: widget.users[index]['role'],
                  items: [
                    const DropdownMenuItem(value: 'member', child: Text('Üye')),
                    const DropdownMenuItem(
                        value: 'moderator', child: Text('Moderatör')),
                    if (widget.userRole == 'owner' || widget.users[index]['role'] == 'owner')
                      const DropdownMenuItem(
                          value: 'owner', child: Text('Sahip')),
                  ],
                  onChanged: (String? newValue) {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
