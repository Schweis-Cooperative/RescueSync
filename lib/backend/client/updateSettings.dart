import 'dart:convert';

import 'package:http/http.dart' as http;

class UpdateData {
  Future<dynamic> getRoom(
      {required String roomCode, required String action}) async {
    var client = http.Client();

    try {
      Map<String, String> body = {'roomCode': roomCode, 'action': action};

      var response = await client
          .post(Uri.https('api.nativez.dev', '/rescuesync/process'), body: body);

      var responseBody = utf8.decode(response.bodyBytes);
      // print('Response Body: $responseBody');
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody) as Map;
        if (decodedResponse['status'] == 'success') {
          return decodedResponse['data'];
        } else {
          return decodedResponse['data'];
        }
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Exception: $e';
    } finally {
      client.close();
    }
  }

  Future<dynamic> changeAccountData(
      {required String username, required String data, required String action}) async {
    var client = http.Client();

    try {
      Map<String, String> body = {'username': username, 'data' : data, 'action': action};

      var response = await client
          .post(Uri.https('api.nativez.dev', '/rescuesync/process'), body: body);

      var responseBody = utf8.decode(response.bodyBytes);
      // print('Response Body: $responseBody');
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody) as Map;

        if (decodedResponse['status'] == 'success') {
          return decodedResponse['data'];
        } else {
          return decodedResponse['data'];
        }
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Exception: $e';
    } finally {
      client.close();
    }
  }

  Future<dynamic> changeRoomData(
      {required String username, required String roomCode, required dynamic data, required String action}) async {
    var client = http.Client();

    try {
      if(data == true) {
        data == 'true';
      } else if(data == false ){
        data == 'false';
      }
      Map<dynamic, dynamic> body = {'username': username, 'roomCode' : roomCode,  'update' : data, 'action': action};

      var response = await client
          .post(Uri.https('api.nativez.dev', '/rescuesync/process'), body: body);

      var responseBody = utf8.decode(response.bodyBytes);
      // print('Response Body: $responseBody');
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody) as Map;

        if (decodedResponse['status'] == 'success') {
          return decodedResponse['data'];
        } else {
          return decodedResponse['data'];
        }
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
