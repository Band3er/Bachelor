import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/Computer.dart';

// Poți extrage această funcție într-un fișier separat (ex: utils/status_helper.dart)
String getStatusText(List<bool> history) {
  if (history.isEmpty) return "Necunoscut";

  bool lastStatus = history.last;
  if (lastStatus) return "ONLINE";

  int lastOnlineIndex = history.lastIndexWhere((s) => s == true);
  if (lastOnlineIndex == -1) return "OFFLINE (fără istoric online)";

  int minuteDiff = history.length - 1 - lastOnlineIndex;
  if (minuteDiff == 0) return "OFFLINE (acum un minut)";
  if (minuteDiff == 1) return "OFFLINE (acum două minute)";
  if (minuteDiff < 60) return "OFFLINE (acum $minuteDiff minute)";
  if (minuteDiff < 120) return "OFFLINE (acum o oră)";
  if (minuteDiff < 1440) {
    final hours = (minuteDiff / 60).floor();
    return "OFFLINE (acum $hours ore)";
  }
  final days = (minuteDiff / 1440).floor();
  return "OFFLINE (acum $days zile)";
}

class CardsList extends StatelessWidget {
  const CardsList({super.key});

  @override
  Widget build(BuildContext context) {
    final computers = Provider.of<Computer>(context).computers;

    return ListView.builder(
      itemCount: computers.length,
      itemBuilder: (context, index) {
        final pc = computers[index];
        final recentHistory = pc.statusHistory.length > 30
            ? pc.statusHistory.sublist(pc.statusHistory.length - 30)
            : pc.statusHistory;
        final isOnline = recentHistory.isNotEmpty && recentHistory.last;
        final statusText = getStatusText(recentHistory);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.computer),
            title: Text(pc.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP: ${pc.ipAddress}'),
                Text('MAC: ${pc.macAddress}'),
                Text(
                  statusText,
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () =>
              context.push('/view-card', extra: pc)
             // <-- acum e corect plasat
          ),
        );

      },
    );
  }
}
