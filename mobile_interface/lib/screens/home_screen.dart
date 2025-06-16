import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/app_drawer.dart';
import '../widgets/card_list.dart';
import '../providers/Computer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _sendDataServer(BuildContext context, Map<String, dynamic> sendData) async {
    await Provider.of<Computer>(context, listen: false).sendData(sendData);
    await Provider.of<Computer>(context, listen: false).getData();
  }

  Future<void> _getDataServer(BuildContext context) async {
    await Provider.of<Computer>(context, listen: false).getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wake on Lan page'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            color: Colors.white60,
            onPressed: () => _sendDataServer(context, {'do_arp': 1, 'send_wol': 0}),
            //onPressed: () => _getDataServer(context),
            icon: Icon(Icons.refresh),
            tooltip: 'Get PC\'s from LAN',
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: CardsList(),
      floatingActionButton: FloatingActionButton(onPressed: ()=> context.go('/add-computer'), child: Icon(Icons.add),),
    );
  }
}
