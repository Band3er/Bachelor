import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import './screens/home_screen.dart';
import './screens/add_computer_screen.dart';
import './screens/auth_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();


  //sqfliteFfiInit();

  //databaseFactoryOrNull  = databaseFactoryFfi;
  var database = await initDatabase();


  runApp(MyApp(database: database));


}

Future<Database> initDatabase() async {
  String path = await getDatabasesPath();
  debugPrint("The path where the database is: " + path);
  return openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.

    // db.db initial
    // TODO: create new table
    join(await getDatabasesPath(), 'dbb.db'),
    onCreate: (db, version){
      //TODO:  Add time when users registered
      db.execute('CREATE TABLE "users" ( "id" TEXT, "email" TEXT, "password" TEXT, "dateTime" TEXT)');
    },
    version: 2
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.database});

  final Database database;

  final _router = GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        name: 'authentication',
        path: '/auth',
        builder: (context, state) => AuthScreen(),
      ),
      GoRoute(
        name: 'add computer',
        path: '/add-computer',
        builder: (context, state) => AddComputerScreen(),
      ),
    ],
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider<Database>.value(
      value: database,
      child: MaterialApp.router(
        title: 'Wake-on-Lan',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        routerConfig: _router,
        //home: AuthScreen(),
      ),
    );
  }
}
