import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../providers/Computer.dart';

class CardScreen extends StatefulWidget {
  final String id;
  final String name;
  final String macAddress;
  final String ipAddress;
  final String lastOnline;

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
  late String deviceName;

  @override
  void initState() {
    super.initState();
    deviceName = widget.name;
  }

  @override
  void dispose() {
    super.dispose();
  }

  String getStatusText(List<bool> history) {
    if (history.isEmpty) return "Necunoscut";

    bool lastStatus = history.last;
    if (lastStatus) return "ONLINE";

    // Cauta ultima pozitie unde a fost online
    int lastOnlineIndex = history.lastIndexWhere((status) => status == true);
    if (lastOnlineIndex == -1) return "OFFLINE (fara istoric online)";

    int minuteDiff = history.length - 1 - lastOnlineIndex - 1;
    if (minuteDiff == 0) return "OFFLINE (acum un minut)";
    if (minuteDiff < 60) return "OFFLINE (acum $minuteDiff minute)";
    if (minuteDiff < 120) return "OFFLINE (acum o oră)";
    if (minuteDiff < 1440) {
      final hours = (minuteDiff / 60).floor();
      return "OFFLINE (acum $hours ore)";
    }
    final days = (minuteDiff / 1440).floor();
    return "OFFLINE (acum $days zile)";
  }

  @override
  Widget build(BuildContext context) {
    final computerProvider = Provider.of<Computer>(context, listen: false);
    final currentPc = computerProvider.computers.firstWhere(
      (pc) => pc.id == widget.id,
    );
    final recentHistory =
        currentPc.statusHistory.length > 30
            ? currentPc.statusHistory.sublist(
              currentPc.statusHistory.length - 30,
            )
            : currentPc.statusHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: Text('Redenumeste dispozitivul'),
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Nume nou'),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Anuleaza'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text('Salveaza'),
                        onPressed: () {
                          Provider.of<Computer>(
                            context,
                            listen: false,
                          ).renameComputer(widget.id, controller.text);
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
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            spacing: MediaQuery.of(context).size.height * 0.03,
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
              Text('Ip address: ' + currentPc.ipAddress),
              Text('Mac address: ' + widget.macAddress),
              Text(
                getStatusText(recentHistory),
                style: TextStyle(
                  color:
                      recentHistory.isNotEmpty && recentHistory.last
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      showAppThemedSnackBar(
                        context,
                        'Verific status pentru ${widget.name}...',
                      );
                      await Provider.of<Computer>(
                        context,
                        listen: false,
                      ).fetchDeviceStatus({
                        'is_online': 1,
                        'id': widget.id,
                        'ip': widget.ipAddress,
                      }, context);
                      showAppThemedSnackBar(
                        context,
                        'Status actualizat pentru ${widget.name}.',
                      );
                    },
                    child: Icon(Icons.refresh),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      showAppThemedSnackBar(
                        context,
                        'Trimitere pachet Wake-on-LAN...',
                      );
                      await Provider.of<Computer>(
                        context,
                        listen: false,
                      ).sendAndReceiveData({
                        'send_wol': 1,
                        'mac':
                            widget.macAddress.replaceAll(':', '').toLowerCase(),
                      }, context);
                      showAppThemedSnackBar(
                        context,
                        'Pachet WOL trimis catre ${widget.macAddress}',
                      );
                    },
                    child: Icon(Icons.power_settings_new),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Confirmare'),
                            content: const Text(
                              'Sigur vrei să stergi acest dispozitiv?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Anuleaza'),
                                onPressed: () {
                                  Navigator.of(
                                    dialogContext,
                                  ).pop(); // inchide dialogul
                                },
                              ),
                              TextButton(
                                child: const Text(
                                  'Sterge',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  final pcToDelete = computerProvider.computers
                                      .firstWhere(
                                        (pc) =>
                                            pc.macAddress == widget.macAddress,
                                        orElse:
                                            () =>
                                                throw Exception('PC not found'),
                                      );
                                  computerProvider.deleteComputer(
                                    pcToDelete.id,
                                  );
                                  showAppThemedSnackBar(
                                    context,
                                    'Dispozitiv sters: ${pcToDelete.name}',
                                  );
                                  Navigator.of(
                                    dialogContext,
                                  ).pop(); // inchide dialogul
                                  context.pop(); // Revenim la ecranul anterior
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Text("Istoric conectivitate"),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        spots:
                            recentHistory
                                .asMap()
                                .entries
                                .map(
                                  (entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value ? 1 : 0,
                                  ),
                                )
                                .toList(),
                        color: Colors.blueAccent,
                        barWidth: 2,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            if (value == 0) return const Text("Off");
                            if (value == 1) return const Text("On");
                            return const SizedBox.shrink();
                          },
                          interval: 1,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    minY: 0,
                    maxY: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
