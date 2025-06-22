import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/Computer.dart';

class CardScreen extends StatefulWidget {
  final String id;
  final String name;
  final String macAddress;
  final String ipAddress;
  final String lastOnline;

  //final String do_arp;
  //final String send_wol;

  CardScreen({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.lastOnline,
    required this.macAddress,
  });

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  Future<void> _sendDataServer(BuildContext context, Map<String, dynamic> sendData) async {
    await Provider.of<Computer>(context, listen: false).sendData(sendData);
    //await Provider.of<Computer>(context, listen: false).getData();
  }

  late String deviceName;
  @override
  void initState() {
    super.initState();
    deviceName = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    final computerProvider = Provider.of<Computer>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(deviceName), actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                final controller = TextEditingController();
                return AlertDialog(
                  title: Text('Redenumește dispozitivul'),
                  content: TextField(
                    controller: controller,
                    decoration: InputDecoration(hintText: 'Nume nou'),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Anulează'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text('Salvează'),
                      onPressed: () {
                        Provider.of<Computer>(context, listen: false)
                            .renameComputer(widget.id, controller.text);
                        setState(() {
                          deviceName = controller.text;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        )

      ],),
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
            Text('Ip address: ' + widget.ipAddress),
            Text('Mac address: ' + widget.macAddress),
            Text('The device was last online: ' + widget.lastOnline),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _sendDataServer(context, {'do_arp': 1}),
                  child: Icon(Icons.refresh),
                  ),

                ElevatedButton(
                  onPressed: () => _sendDataServer(context, {'send_wol': 1, 'mac': widget.macAddress.replaceAll(':', '').toLowerCase()}),
                  child: Icon(Icons.power_settings_new),
                  ),
                ElevatedButton(onPressed: (){
                  // Caută obiectul complet după MAC sau IP (sau trimite id dacă îl ai)
                  final pcToDelete = computerProvider.computers.firstWhere(
                        (pc) => pc.macAddress == widget.macAddress,
                    orElse: () => throw Exception('PC not found'),
                  );
                  computerProvider.deleteComputer(pcToDelete.id);
                  context.pop();
                }, child: Icon(Icons.delete, color: Colors.red,))

              ],
            ),
          ],
        ),
      ),
    );
  }
}
