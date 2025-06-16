import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/Computer.dart';

class CardScreen extends StatelessWidget {
  final String name;
  final String macAddress;
  final String ipAddress;
  final String lastOnline;

  //final String do_arp;
  //final String send_wol;

  CardScreen({
    required this.name,
    required this.ipAddress,
    required this.lastOnline,
    required this.macAddress,
  });

  Future<void> _sendDataServer(BuildContext context, Map<String, dynamic> sendData) async {
    await Provider.of<Computer>(context, listen: false).sendData(sendData);
    //await Provider.of<Computer>(context, listen: false).getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(spacing: MediaQuery.of(context).size.height * 0.03,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.computer,
              size: 80,
              color: Colors.blueAccent,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.blueAccent.withValues(alpha: 0.5),
                  offset: Offset(2, 4),
                ),
              ],
            ),
            Text('Ip address: ' + ipAddress),
            Text('Mac address: ' + macAddress),
            Text('The device was last online: ' + lastOnline),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _sendDataServer(context, {'do_arp': 1}),
                  child: Icon(Icons.refresh),
                  ),

                ElevatedButton(
                  onPressed: () => _sendDataServer(context, {'do_arp': 0, 'send_wol': 1, 'mac': macAddress}),
                  child: Icon(Icons.power_settings_new),
                  ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
