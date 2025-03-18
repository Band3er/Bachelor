import 'package:flutter/material.dart';


import '../widgets/login.dart';
import '../widgets/signup.dart';

enum AuthState{Login, Signup}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  AuthState _authState = AuthState.Login;





  void _toggleAuthStates(){
    setState(() {
      _authState = _authState == AuthState.Login ? AuthState.Signup : AuthState.Login;
    });
  }




  // TODO: error alert if the auth is not as it should
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('An error Occured!'),
            content: Text(message),
            actions: [OutlinedButton(onPressed: null, child: Text('Okay'))],
          ),
    );
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
                Icon(Icons.computer, color: Colors.blueAccent,size: MediaQuery.sizeOf(context).width / 4,),
                SizedBox(height: MediaQuery.sizeOf(context).width / 8),
                _authState == AuthState.Login ?
                    Login(onToggle: _toggleAuthStates)
                    : Signup(onToggle: _toggleAuthStates),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
