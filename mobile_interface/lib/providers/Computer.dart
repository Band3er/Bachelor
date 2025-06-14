import 'dart:convert' as convert;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class Computer {
  late String name;
  late String macAddress = '11';
  late String ipAddress = '12';
  late String lastOnline;

  //Computer({required this.ipAddress, required this.name, required this.lastOnline, required this.macAddress});

  Future<void> getData() async {
    // TODO: change with the actual path
    var url = Uri.http('10.0.2.2:3000', '/data-flutter');

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      macAddress = jsonResponse['mac'];
      ipAddress = jsonResponse['ip'];
      lastOnline = jsonResponse['online'];
    }

    debugPrint(
      'Pc with mac:' +
          macAddress +
          ', ip: ' +
          ipAddress +
          ', online: ' +
          lastOnline,
    );
  }

  Future<void> sendData() async {
    var url = Uri.http('10.0.2.2:3000', 'data'); // acelasi ca si pe esp

    var do_arp = 1;
    var send_wol = 0;

    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: convert.jsonEncode(<String, String>{
        'do_arp': do_arp.toString(),
        'send_wol': send_wol.toString(),
        'mac': macAddress,
        'ip:': ipAddress,
      }),
    );
    debugPrint('Data sent to ' + url.toString());
  }
}
