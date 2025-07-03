import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:go_router/go_router.dart';

import '../providers/user.dart';

import '../globals.dart';

class Login extends StatefulWidget {
  final VoidCallback onToggle;

  Login({super.key, required this.onToggle});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var _user = User(email: '', password: '');

  final _passwordController = FocusNode();

  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);

    void _showErrorDialog(String message) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
          title: Text('An error Occured!'),
          content: Text(message),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Okay'),
            ),
          ],
        ),
      );
    }

    Future<void> _interogateDatabase(Database database, User user) async {
      try{

        if(!_form.currentState!.validate())
          return;
        _form.currentState?.save();
        debugPrint('$time From the login form: email = ${user.email} || password = ${user.password}');
        List<Map<String, Object?>> query =  (await database.rawQuery('SELECT email,password FROM users WHERE email=? AND password=?', ['${user.email}', '${user.password}']));
        debugPrint('$time From the login query: ' + query.toString());
        for(final {'email':email as String, 'password':password as String} in query){
          User(email: email, password: password);
          if(user.email == email && user.password == password){
            context.go('/');
          }
        }
        if(query.isEmpty){
          _showErrorDialog('password or email are wrong!');
        }
      }catch(err){
        debugPrint('$time Error from the login database interogation: ' + err.toString());
      }
    }

    return Form(
      autovalidateMode: AutovalidateMode.always,
      onChanged: () {
        Form.of(primaryFocus!.context!).save();
      },
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("email", textAlign: TextAlign.left),
              TextFormField(
                decoration: InputDecoration(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 3,
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Enter the email',
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordController);
                },
                validator: (value) {
                  if(value == null || value.isEmpty){
                    return 'Enter a valid value!';
                  }
                },
                onSaved: (value) {
                  _user.email = value.toString();
                },
              ),
              SizedBox(height: 50.0),
              Text("password"),
              TextFormField(
                decoration: InputDecoration(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 3,
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Enter the password',
                ),
                focusNode: _passwordController,
                validator: (value) {
                  //if(value == null || value.isEmpty){
                    //return 'Enter a valid value!';
                  //}
                },
                onSaved: (value) {
                  _user.password = value.toString();
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                _interogateDatabase(database, _user);
              },
              child: Text("Submit"),
            ),
          ),
          Text("Not registered?"),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: widget.onToggle,
              child: Text("Sign up"),
            ),
          ),
        ],
      ),
    );
  }
}
