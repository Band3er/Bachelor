import 'dart:convert' as convert;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;


import 'ComputerData.dart';

import '../globals.dart';

class Computer with ChangeNotifier {
  List<ComputerData> _computers = [];

  List<ComputerData> get computers => _computers;

  //Computer({required this.ipAddress, required this.name, required this.lastOnline, required this.macAddress});

  // trebuie luate date de la server
  // sa iau date pe rand
  // ce trimit aia sa primesc si sa procesez
  Future<void> getData() async {
    // TODO: change with the actual path of the aws
    var url = Uri.http('10.0.2.2:3000', '/results');

    while(true){
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonList = convert.jsonDecode(response.body);
        _computers = (jsonList as List)
            .map((json) => ComputerData.fromJson(json))
            .toList();

        notifyListeners();
        break;
      } else {
        debugPrint('$time Failed to load data: ${response.statusCode}');
      }
      await Future.delayed(Duration(seconds: 5));
    }

  _computers.forEach((pc) {
    debugPrint(
      '$time Pc with id: ' + pc.id + ', name: ' + pc.name +' mac:' + pc.macAddress +', ip: ' + pc.ipAddress +', online: ' + pc.lastOnline.toString());
  });


  }

  // trimit sub forma de json, si comanda si tot o impachetez ca json!!!
  Future<void> sendData(Map<String, dynamic> sendInfo) async {
    var url = Uri.http('10.0.2.2:3000', '/commands'); // acelasi ca si pe esp

    // trimite info care trebuie, specificata
    http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },

      // aici trimit sub forma de json, serializez
      body: convert.jsonEncode(sendInfo),
    );
    debugPrint('$time Data sent to ' + url.toString());
    debugPrint('$time Info sent ' + sendInfo.toString());
  }
}
