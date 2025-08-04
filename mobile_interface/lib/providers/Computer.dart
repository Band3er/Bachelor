import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path_provider/path_provider.dart';

import 'ComputerData.dart';
import '../globals.dart';
import 'SessionStorageService.dart';

class Computer with ChangeNotifier {
  List<ComputerData> _computers = [];
  final String userId;

  bool _isLoading = false;
  static bool _certsPrepared = false;
  static String? rootCAPath;
  static String? certPath;
  static String? keyPath;

  bool get isLoading => _isLoading;

  List<ComputerData> get computers => _computers;
  late final SessionStorageService session;

  Computer({required this.userId}) {
    session = SessionStorageService(userId: userId);
  }

  Future<void> sendAndReceiveData(
    Map<String, dynamic> sendInfo,
    BuildContext context,
  ) async {
    _isLoading = true;
    notifyListeners();

    final mac = await session.getMacAddress();
    if (mac == null || mac.isEmpty) {
      showAppThemedSnackBar(context, 'MAC ESP32 nu este asociat. Conecteaza-te la Bluetooth.');
      return; // ieși din functie, nu trimite nimic
    }

    // Trimit comanda MQTT catre ESP32
    await sendData(sendInfo);

    // Astept putin pentru a permite ESP32 sa trimita datele la AWS
    await Future.delayed(Duration(seconds: 7));

    // Apelez fetchDevices() pentru a incarca datele primite
    await fetchDevices(context);

    _isLoading = false;
    notifyListeners();
  }

  void startPingAll(BuildContext context) {
    Timer.periodic(Duration(seconds: 20), (timer) async {
      for (var pc in _computers) {
        //try {
        await fetchDeviceStatus({
          'is_online': 1,
          'id': pc.id,
          'ip': pc.ipAddress,
        }, context);
      }
    });
  }

  Future<void> fetchDeviceStatus(
    Map<String, dynamic> sendInfo,
    BuildContext context,
  ) async {
    var deviceIP = sendInfo['ip'];
    debugPrint('$time Fetch device status with mac: $deviceIP');

    final url = Uri.https(
      '',
      '/', //
      {'device_ip': deviceIP}, // facem GET dupa id
    );

    // Trimit comanda MQTT catre ESP32
    await sendData(sendInfo);
    await Future.delayed(Duration(seconds: 3));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = convert.jsonDecode(response.body) as List;
      _updateComputers(jsonList);
      debugPrint('$time the new PC with the data ${response.body}');
    } else {
      debugPrint(
        '$time Error ${response.statusCode} and the body ${response.body}',
      );
      showAppThemedSnackBar(
        context,
        'Eroare la verificarea statusului (${response.statusCode})',
      );
    }
  }

  Future<void> fetchDevices(BuildContext context) async {
    debugPrint('$time getData called');

    if (userId.isEmpty) {
      debugPrint('$time user_id nu este setat in SharedPreferences.');
      showAppThemedSnackBar(context, 'Eroare: utilizator necunoscut.');
      return;
    }

    final mac = await session.getMacAddress();
    if (mac == null || mac.isEmpty) {
      debugPrint('$time MAC address nu este disponibil!');
      showAppThemedSnackBar(
        context,
        'MAC ESP32 lipsa. Asociaza mai intai un dispozitiv Bluetooth.',
      );
      return;
    }

    debugPrint('$time MAC obtinut din sesiune: $mac');

    final url = Uri.https(
      '',
      '/', //
      {'esp_mac': mac}, // facem GET dupa adresa MAC
    );

    debugPrint('GET Request with url: $url');

    await Future.delayed(Duration(seconds: 7));

    var retries = 0;
    while (retries < 3) {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonList = convert.jsonDecode(response.body) as List;
        bool dataIsDifferent = _isDataDifferent(jsonList);

        if (dataIsDifferent) {
          _updateComputers(jsonList);
          retries = 0;
          notifyListeners();
        }

        debugPrint('$time data received, data: ${response.body}');
      } else {
        debugPrint(
          '$time no data received, server response ${response.statusCode}',
        );
        showAppThemedSnackBar(
          context,
          'Eroare la primirea dispozitivelor (${response.statusCode})',
        );
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
    await session.saveComputers(_computers);
  }

  Future<void> loadFromPrefs() async {
    final jsonList = await session.getComputers();
    _computers = List<ComputerData>.from(
      jsonList.map((json) => ComputerData.fromJson(json)),
      growable: true,
    );
    notifyListeners();
  }

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
      '',
      '',
    );

    client.port = 8883;
    client.secure = true;

    await prepareCertificates();

    client.securityContext =
        SecurityContext()
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
    debugPrint('$time MQTT::client connecting....');
    client.connectionMessage = connMess;
    try {
      await client.connect();
    } on Exception catch (e) {
      debugPrint('$time MQTT::client exception - $e');
      client.disconnect();
    }

    // Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('$time MQTT::Mosquitto client connected');
    } else {
      debugPrint(
        '$time MQTT::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}',
      );
      client.disconnect();
    }

    client.published!.listen((MqttPublishMessage message) {
      debugPrint(
        '$time MQTT::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}',
      );
    });

    final builder1 = MqttClientPayloadBuilder();
    const topic1 = '/queue0';

    var dataa = convert.jsonEncode(sendInfo);
    builder1.addString(dataa.toString());

    print('$time MQTT:: <<<< PUBLISH >>>>');
    client.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload!);

    // Așteapta putin sa se trimita
    await Future.delayed(Duration(seconds: 1));

    // inchide conexiunea
    client.disconnect();
  }

  void onSubscribed(String topic) {
    print('MQTT::Subscription confirmed for topic $topic');
  }

  void onDisconnected() {
    print('MQTT::OnDisconnected client callback - Client disconnection');
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
      if (existingPcIndex == -1)
        return true; // nu exista device ul stocat local

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
    // creează o copie sigura a listei curente
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
        final name =
            newPc.name.trim().isEmpty
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
        newList.add(newDevice);
      }
    }
    _computers = newList;
    _saveToPrefs();
    notifyListeners();
  }

  void fromJSON(List<Map<String, dynamic>> jsonList) {
    _computers = jsonList.map((json) => ComputerData.fromJson(json)).toList();
    notifyListeners();
  }
}
