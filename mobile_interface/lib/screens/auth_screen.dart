import 'package:flutter/material.dart';

import '../widgets/login.dart';
import '../widgets/signup.dart';

enum AuthState { Login, Signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthState _authState = AuthState.Login;

  void _toggleAuthStates() {
    setState(() {
      _authState =
          _authState == AuthState.Login ? AuthState.Signup : AuthState.Login;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bine ai venit!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                SizedBox(height: 16),
                Icon(
                  Icons.computer,
                  color: Colors.blueAccent,
                  size: MediaQuery.sizeOf(context).width / 4,
                ),
                SizedBox(height: MediaQuery.sizeOf(context).width / 8),
                _authState == AuthState.Login
                    ? Login(onToggle: _toggleAuthStates)
                    : Signup(onToggle: _toggleAuthStates),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
