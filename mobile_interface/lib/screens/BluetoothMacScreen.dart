import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/Computer.dart';
import '../providers/SessionStorageService.dart';

class BluetoothMacScreen extends StatefulWidget {
  @override
  _BluetoothMacScreenState createState() => _BluetoothMacScreenState();
}

class _BluetoothMacScreenState extends State<BluetoothMacScreen> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String? macAddress;
  StreamSubscription<List<int>>? notificationSub;
  StreamSubscription<List<ScanResult>>? scanSub;
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    initializeBluetooth();

    // pornim timerul de fallback
    _fallbackTimer = Timer(Duration(seconds: 10), () async {
      if (!_navigated && macAddress == null) {
        debugPrint("MAC ESP32 nu a fost primit la timp");

        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');

        if (userId != null) {
          final computerProvider = Computer(userId: userId);
          _navigated = true;
          context.go('/', extra: computerProvider);
        }
      }
    });
  }

  Future<void> initializeBluetooth() async {
    await requestPermissions();
    await scanAndConnect();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  Future<void> scanAndConnect() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == "ESP_GATTS_DEMO") {
          await FlutterBluePlus.stopScan();
          await scanSub?.cancel();

          connectedDevice = r.device;
          if (!connectedDevice!.isConnected) {
            await connectedDevice!.connect();
          }
          await discoverServices();
          break;
        }
      }
    });
  }

  Future<void> discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        debugPrint("Service: ${service.uuid} | Char: ${c.uuid}");

        // Schimba UUID-ul daca ai definit altul
        if (c.uuid.toString().toLowerCase().contains("ff01")) {
          debugPrint("Gasit caracteristica FF01 pentru MAC");
          targetCharacteristic = c;
          await c.setNotifyValue(true);
          notificationSub = c.lastValueStream.listen((value) {
            handleNotification(value);
          });
          return;
        }
      }
    }
    debugPrint("Nu am gasit caracteristica FF01");
  }

  Future<void> _sendMacToServer(String mac, String userId) async {
    final url = Uri.parse(
      '',
    );

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': userId, 'esp_mac': mac}),
    );

    if (response.statusCode == 200) {
      debugPrint("MAC salvat cu succes.");
    } else {
      debugPrint("Eroare la salvarea MAC: ${response.body}");
    }
  }

  void handleNotification(List<int> value) async {
    if (value.isEmpty) {
      debugPrint("Am primit o notificare goala!");
      return;
    }

    String mac = value
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':');
    debugPrint("MAC primit de la ESP32: $mac");

    setState(() {
      macAddress = mac;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final session = SessionStorageService(userId: userId ?? 'temp');
    await session.saveMacAddress(mac);

    if (userId != null && userId.trim().isNotEmpty) {
      await _sendMacToServer(mac, userId);
    } else {
      debugPrint("user_id nu a fost gasit in SharedPreferences!");
    }

    if (targetCharacteristic != null) {
      await targetCharacteristic!.setNotifyValue(false);
      debugPrint("Notificarile Bluetooth dezactivate.");
    }

    await notificationSub?.cancel();
    notificationSub = null;

    if (userId != null && !_navigated) {
      final computerProvider = Computer(userId: userId);
      _navigated = true;
      _fallbackTimer?.cancel(); // oprim timerul daca s-a primit MAC-ul
      context.go('/', extra: computerProvider);
    }
  }

  @override
  void dispose() {
    notificationSub?.cancel();
    scanSub?.cancel();
    _fallbackTimer?.cancel(); // anulam fallback-ul
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESP32 MAC Reader')),
      body: Center(
        child:
            macAddress != null
                ? Text(
                  "ESP32 MAC Address:\n$macAddress",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Astept MAC de la ESP32..."),
                  ],
                ),
      ),
    );
  }
}
