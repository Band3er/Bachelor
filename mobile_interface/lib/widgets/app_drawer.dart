import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                AppBar(
                  title: Text('Sidebar'),
                  automaticallyImplyLeading: false,
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.question_answer),
                  title: Text('Add Bluetooth Device'),
                  onTap: () => context.push('/bt-screen'),
                ),
                Divider(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(
                    'user_id',
                  ); // doar userul curent este delogat
                  context.go('/auth');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
