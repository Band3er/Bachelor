import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ComputerData.dart';

import '../globals.dart';

import 'package:flutter/services.dart' show rootBundle;

class Computer with ChangeNotifier {


  List<ComputerData> _computers = [];

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<ComputerData> get computers => _computers;

  Future<void> sendAndReceiveData(Map<String, dynamic> sendInfo, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Trimit comanda MQTT catre ESP32
    await sendData(sendInfo);

    // Astept putin pentru a permite ESP32 să trimita datele la AWS
    await Future.delayed(Duration(seconds: 7));

    // Apelez fetchDevices() pentru a incarca datele primite
    await fetchDevices(context);

    _isLoading = false;
    notifyListeners();
  }

  //Map<String, Timer> _pingTimers = {}; // stocam timer-ele active per device

  void startPingAll(BuildContext context) {
    Timer.periodic(Duration(seconds: 30), (timer) async {
      for (var pc in _computers) {
        //try {
          await fetchDeviceStatus({
            'is_online': 1,
            'id': pc.id,
            'ip': pc.ipAddress,
          }, context);
        //} catch (e) {
          // Dacă nu răspunde, considerăm offline
          //pc.statusHistory.add(false);
          //debugPrint('$time NU am primit niciun raspuns');
          //notifyListeners();
        //}
      }
    });
  }




  Future<void> fetchDeviceStatus(Map<String, dynamic> sendInfo, BuildContext context) async{

    var deviceIP = sendInfo['ip'];
    debugPrint('$time Fetch device status with mac: $deviceIP');


    final url = Uri.https(
      'cdqsgosjon7pvb2awqag5si2ie0copdt.lambda-url.eu-central-1.on.aws',
      '/', //
      {'device_ip': deviceIP}, // facem GET dupa id
    );

    // Trimit comanda MQTT catre ESP32
    await sendData(sendInfo);

    await Future.delayed(Duration(seconds: 3));

    final response = await http.get(url);

      if(response.statusCode == 200) {
        final jsonList = convert.jsonDecode(response.body) as List;



        //ComputerData newPc = ComputerData.fromJson(jsonList as Map<String, dynamic>);

        _updateComputers(jsonList);


        debugPrint('$time the new PC with the data ${response.body}');

        //final index = _computers.indexWhere((pc) => pc.id == newPc.id);
        //if (index != -1) {
          //_computers[index].ipAddress = newPc.ipAddress;
          //_computers[index].macAddress = newPc.macAddress;
         // _computers[index].lastOnline = newPc.lastOnline;
        //}
      } else {
        debugPrint('$time Error ${response.statusCode} and the body ${response.body}');

        showAppThemedSnackBar(context, 'Eroare la verificarea statusului (${response.statusCode})');
    }
  }

  Future<void> fetchDevices(BuildContext context) async{
    debugPrint('$time getData called');

    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString('esp32_mac');

    final url = Uri.https(
      'cdqsgosjon7pvb2awqag5si2ie0copdt.lambda-url.eu-central-1.on.aws',
      '/', //
      {'esp_mac': mac}, // facem GET dupa adresa MAC
    );

    debugPrint('GET Request with url: $url');

    await Future.delayed(Duration(seconds: 7));

    var retries = 0;
    while(retries < 3){
      final response = await http.get(url);
      if(response.statusCode == 200){

        final jsonList = convert.jsonDecode(response.body) as List;

        bool dataIsDifferent = _isDataDifferent(jsonList);

        if (dataIsDifferent) {
          _updateComputers(jsonList);
          retries = 0;
          notifyListeners();
        }

        debugPrint('$time data received, data: ${response.body}');
      } else{
        debugPrint('$time no data received, server response ${response.statusCode}');

        showAppThemedSnackBar(context, 'Eroare la primirea dispozitivelor (${response.statusCode})');
      }

      // astept o secunda
      retries++;
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void deleteComputer(String id) {
    _computers.removeWhere((pc) => pc.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _computers.map((pc) => pc.toJson()).toList();
    prefs.setString('computers', convert.jsonEncode(jsonList));
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('computers');
    if (jsonString != null) {
      final jsonList = convert.jsonDecode(jsonString) as List;
      _computers = List<ComputerData>.from(
        jsonList.map((json) => ComputerData.fromJson(json)),
        growable: true,
      );

      notifyListeners();
    }
  }
  static bool _certsPrepared = false;
  static String? rootCAPath;
  static String? certPath;
  static String? keyPath;

  Future<void> prepareCertificates() async {
    if (_certsPrepared) return;

    final rootCA = await rootBundle.load('assets/cert/AmazonRootCA1.pem');
    final cert = await rootBundle.load('assets/cert/certificate.pem.crt');
    final privateKey = await rootBundle.load('assets/cert/private.pem.key');

    final tempDir = await getTemporaryDirectory();

    rootCAPath = '${tempDir.path}/AmazonRootCA1.pem';
    certPath = '${tempDir.path}/certificate.pem.crt';
    keyPath = '${tempDir.path}/private.pem.key';

    await File(rootCAPath!).writeAsBytes(rootCA.buffer.asUint8List());
    await File(certPath!).writeAsBytes(cert.buffer.asUint8List());
    await File(keyPath!).writeAsBytes(privateKey.buffer.asUint8List());

    _certsPrepared = true;
  }


  Future<void> sendData(Map<String, dynamic> sendInfo) async {
    final client = MqttServerClient(
      'avbtetc4ahvoo-ats.iot.eu-central-1.amazonaws.com',
      '',
    );

    client.port = 8883;
    client.secure = true;

    await prepareCertificates();

    client.securityContext = SecurityContext()
      ..setTrustedCertificates(rootCAPath!)
      ..useCertificateChain(certPath!)
      ..usePrivateKey(keyPath!);


    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueIdQ1')
        .withWillTopic(
          'willtopic',
        ) // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    }

    // Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}',
      );
      client.disconnect();
      //exit(-1);
    }

    client.published!.listen((MqttPublishMessage message) {
      print(
        'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}',
      );
    });

    final builder1 = MqttClientPayloadBuilder();
    const topic1 = '/queue0';

    var dataa = convert.jsonEncode(sendInfo);
    builder1.addString(dataa.toString());

    print('EXAMPLE:: <<<< PUBLISH >>>>');
    client.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload!);

    // Așteaptă puțin să se trimită
    await Future.delayed(Duration(seconds: 1));

    // Închide conexiunea
    client.disconnect();
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  }

  void renameComputer(String id, String newName) {
    final index = _computers.indexWhere((pc) => pc.id == id);
    if (index != -1) {
      _computers[index] = ComputerData(
        id: _computers[index].id,
        name: newName,
        macAddress: _computers[index].macAddress,
        ipAddress: _computers[index].ipAddress,
        lastOnline: _computers[index].lastOnline,
      );
      _saveToPrefs();
      notifyListeners();
    }
  }

  bool _isDataDifferent(List jsonList) {
    for (var json in jsonList) {
      final newPc = ComputerData.fromJson(json);

      final existingPcIndex = _computers.indexWhere((pc) => pc.id == newPc.id);
      if (existingPcIndex == -1) return true; // nu exista device ul stocat local

      final existingPc = _computers[existingPcIndex];
      if (newPc.lastOnline != existingPc.lastOnline ||
          newPc.macAddress != existingPc.macAddress ||
          newPc.ipAddress != existingPc.ipAddress) {
        return true; // date modificate
      }
    }

    return false;
  }


  void _updateComputers(List jsonList) {
    // creează o copie sigură a listei curente
    List<ComputerData> newList = List<ComputerData>.from(_computers);

    for (var json in jsonList) {
      final newPc = ComputerData.fromJson(json);
      bool isOnline = newPc.lastOnline.trim() == "1";

      final index = newList.indexWhere((pc) => pc.id == newPc.id);
      if (index != -1) {
        newList[index].ipAddress = newPc.ipAddress;
        newList[index].lastOnline = newPc.lastOnline;

        if (newList[index].statusHistory.length >= 1440) {
          newList[index].statusHistory.removeAt(0);
        }
        newList[index].statusHistory.add(isOnline);
      } else {
        final name = newPc.name.trim().isEmpty
            ? 'Device - ${newList.length + 1}'
            : newPc.name;
        final newDevice = ComputerData(
          id: newPc.id,
          name: name,
          macAddress: newPc.macAddress,
          ipAddress: newPc.ipAddress,
          lastOnline: newPc.lastOnline,
        );
        if (newDevice.statusHistory.length >= 1440) {
          newDevice.statusHistory.removeAt(0);
        }
        newList.add(newDevice); // AICI adaugi într-o listă sigură
      }
    }

    _computers = newList;
    _saveToPrefs();
    notifyListeners();
  }



  bool statusDevice(int isOnline, String ipAddress){
    //getData();

    int minutes = 0, hours = 0, days = 0, month = 0;

    if(isOnline == 1){
      return true;
    } else if(isOnline == 0){
      minutes += 1;
      if(minutes == 60){
        minutes = 0;
        hours += 1;
      }
      if(hours == 24){
        hours = 0;
        days += 1;
      }
      if(days == 30){
        days = 0;
        month += 1;
      }
      return false;
    }
    return false;
  }

}
