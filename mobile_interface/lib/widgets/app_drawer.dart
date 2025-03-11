import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text('Hello there'),
            automaticallyImplyLeading: false,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('Something'),
            onTap: null,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('Something'),
            onTap: null,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('Something'),
            onTap: null,
          ),
        ],
      ),
    );
  }
}
