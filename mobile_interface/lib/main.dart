import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_interface/screens/BluetoothMacScreen.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import './screens/home_screen.dart';
import './screens/add_computer_screen.dart';
import './screens/auth_screen.dart';
import './screens/card_screen.dart';

import './providers/ComputerData.dart';
import './providers/Computer.dart';

import 'globals.dart';



Future main() async {



  WidgetsFlutterBinding.ensureInitialized();


  //sqfliteFfiInit();

  //databaseFactoryOrNull  = databaseFactoryFfi;
  var database = await initDatabase();


  runApp(MyApp(database: database));



}

Future<Database> initDatabase() async {
  String path = await getDatabasesPath();
  debugPrint("$time The path where the database is: " + path);
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

Future<void> initComputer(Computer computerProvider) async {
  await computerProvider.loadFromPrefs();
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.database});

  final Database database;



  final _router = GoRouter(
    initialLocation: '/',
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
      GoRoute(
        name: 'viewCard',
        path: '/view-card',
        builder: (context, state) {
          final pc = state.extra as ComputerData;

          return CardScreen(
            id: pc.id,
            name: pc.name,
            macAddress: pc.macAddress,
            ipAddress: pc.ipAddress,
            lastOnline: pc.lastOnline.toString(),
          );
        },
      ),
      GoRoute(
        name: 'bluetooth-screen',
        path: '/bt-screen',
        builder: (context, state) => BluetoothMacScreen()
      )
    ],
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final computerProvider = Computer();
    computerProvider.loadFromPrefs();
    return MultiProvider(
      providers: [
        Provider<Database>.value(value: database),
        ChangeNotifierProvider(create: (_) => computerProvider), // adaugat
      ],
      child: MaterialApp.router(
        title: 'Wake-on-Lan',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        routerConfig: _router,
      ),
    );
  }
}
