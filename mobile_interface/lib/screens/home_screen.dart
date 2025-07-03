import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../widgets/app_drawer.dart';
import '../widgets/card_list.dart';
import '../providers/Computer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {

    super.initState();
    // Pornește ping-ul periodic după build-ul inițial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Computer>(context, listen: false).startPingAll(context);
    });
  }



  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<Computer>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Wake on Lan page'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            color: Colors.white60,
            onPressed: () async {

              showAppThemedSnackBar(context, 'Scanare ARP trimisă către ESP32...');
              await Provider.of<Computer>(context, listen: false)
                  .sendAndReceiveData({'do_arp': 1}, context);

              showAppThemedSnackBar(context, 'Scanare ARP finalizată');
            },
            icon: Icon(Icons.refresh),
            tooltip: 'Get PC\'s from LAN',
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Stack(children: [CardsList(),
        if (isLoading)
          Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ),]),
    );
  }
}
