import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import './screens/home_screen.dart';
import './screens/auth_screen.dart';
import './screens/card_screen.dart';
import './providers/Computer.dart';
import './screens/BluetoothMacScreen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _router = GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) {
          final computer = state.extra as Computer;
          return ChangeNotifierProvider.value(
            value: computer,
            child: HomeScreen(),
          );
        },
      ),
      GoRoute(
        name: 'authentication',
        path: '/auth',
        builder: (context, state) => AuthScreen(),
      ),
      GoRoute(
        name: 'view-card',
        path: '/view-card',
        builder: (context, state) {
          final computerProvider = state.extra as Computer;
          final args = state.uri.queryParameters;
          return ChangeNotifierProvider.value(
            value: computerProvider,
            child: CardScreen(
              id: args['id']!,
              name: args['name']!,
              ipAddress: args['ip']!,
              macAddress: args['mac']!,
              lastOnline: args['lastOnline'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        name: 'bluetooth-screen',
        path: '/bt-screen',
        builder: (context, state) => BluetoothMacScreen(),
      ),
    ],
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Computer>(
          create: (_) => Computer(userId: ''), // setezi userId ulterior
        ),
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
