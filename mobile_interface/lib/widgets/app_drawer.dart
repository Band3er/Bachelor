import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/BluetoothMacScreen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(

      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Column(
            children: [
              AppBar(
                title: Text('Hello there'),
                automaticallyImplyLeading: false,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.question_answer),
                title: Text('Add Bluetooth Device'),
                onTap: () => context.push('/bt-screen'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.question_answer),
                title: Text('Something'),
                onTap: null,
              ),
              Divider(),
            ],
          ),
          Align(
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: ()=>context.go('/auth'),

            ),
            alignment: Alignment.bottomCenter,
          ),
        ],
      ),
    );
  }
}
