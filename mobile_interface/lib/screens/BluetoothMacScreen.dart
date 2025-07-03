import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

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


  @override
  void initState() {
    super.initState();
    initializeBluetooth();
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

        // <<== Schimba UUID-ul dacă ai definit altul
        if (c.uuid.toString().toLowerCase().contains("ff01")) {
          debugPrint("Gasit characteristic FF01 pentru MAC");
          targetCharacteristic = c;

          await c.setNotifyValue(true);



          notificationSub = c.lastValueStream.listen((value) {
            handleNotification(value);
          });



          return;
        }
      }
    }

    debugPrint("Nu am gasit characteristic FF01");
  }


  void handleNotification(List<int> value) async {
    if (value.isEmpty) {
      debugPrint("Received empty notification!");
      return;
    }

    String mac = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
    debugPrint("Received MAC: $mac");

    setState(() {
      macAddress = mac;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_mac', mac);

    // Oprește notificarile si streamul
    if (targetCharacteristic != null) {
      await targetCharacteristic!.setNotifyValue(false);
      debugPrint("Notificarile au fost dezactivate.");
    }

    await notificationSub?.cancel();
    notificationSub = null;
  }

  @override
  void dispose() {
    notificationSub?.cancel();
    scanSub?.cancel();
    connectedDevice?.disconnect(); // optional, daca vrei să te deconectezi
    super.dispose();
  }




  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 MAC Reader'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // merge inapoi în istoricul GoRouter
          },
        ),
      ),

      body: Center(
        child: macAddress != null
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
            Text("Astept MAC de la ESP32...")
          ],
        ),
      ),
    );
  }

}