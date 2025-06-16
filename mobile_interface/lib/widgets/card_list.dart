import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/Computer.dart';

class CardsList extends StatelessWidget {
  const CardsList({super.key});

  @override
  Widget build(BuildContext context) {
    final computerProvider = Provider.of<Computer>(context);
    final computers = computerProvider.computers;

    return ListView.builder(
      itemCount: computers.length,
      itemBuilder: (context, index) {
        final pc = computers[index];
        return GestureDetector(
          onTap: () => context.push('/view-card', extra: pc),
          child: Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(pc.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  Text("Mac Address: ${pc.macAddress}"),
                  Text("IP: ${pc.ipAddress}"),
                  Text("Last online: ${pc.lastOnline}"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
