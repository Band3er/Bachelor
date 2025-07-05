import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart';
import '../providers/SessionStorageService.dart';
import '../widgets/app_drawer.dart';
import '../widgets/card_list.dart';
import '../providers/Computer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SessionStorageService session;

  @override
  void initState() {
    super.initState();
    _initSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Computer>(context, listen: false).startPingAll(context);
    });
  }

  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      final computerProvider = Provider.of<Computer>(context, listen: false);
      await computerProvider.loadFromPrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final computerProvider = Provider.of<Computer>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Wake on Lan page'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            color: Colors.white60,
            onPressed: () async {
              showAppThemedSnackBar(
                context,
                'Scanare ARP trimisa către ESP32...',
              );
              await Provider.of<Computer>(
                context,
                listen: false,
              ).sendAndReceiveData({'do_arp': 1}, context);
              showAppThemedSnackBar(context, 'Scanare ARP finalizata');
            },
            icon: Icon(Icons.refresh),
            tooltip: 'Get PC\'s from LAN',
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Stack(
        children: [
          CardsList(),
          if (computerProvider.isLoading)
            Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator()],
              ),
            ),
        ],
      ),
    );
  }
}
