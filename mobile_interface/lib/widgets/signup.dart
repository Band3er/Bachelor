import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:intl/intl.dart';

import '../providers/user.dart';

import '../globals.dart';

class Signup extends StatefulWidget {
  final VoidCallback onToggle;

  Signup({super.key, required this.onToggle});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  var _user = User(id: Uuid().v1(), email: '', password: '', dateTime: DateFormat('dd-MM-yyyy/HH:mm').format(DateTime.now()));

  final _passwordFocusNode = FocusNode();

  final _passwordTextController = TextEditingController();

  final _passwordConfirmController = FocusNode();

  final _form = GlobalKey<FormState>();

  final GlobalKey<FlutterPwValidatorState> validatorKey =
      GlobalKey<FlutterPwValidatorState>();

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

    Future<void> _saveForm(Database database, User user) async {
      try {
        if (!_form.currentState!.validate()) return;
        _form.currentState?.save();


        //TODO: add logic if same email is inserted
        debugPrint('$time From the signup save form: ' + user.toString());
        await database.insert('users', user.toMap());

        context.go('/');
      } catch (err) {
        debugPrint('$time From the signup save form: ' + err.toString());
        _showErrorDialog(err.toString());
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
              Text("email"),
              TextFormField(
                decoration: InputDecoration(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 1.5,
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Enter the email',
                ),

                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
                validator: (value) {
                  //final emailRegex = RegExp(
                    //'[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,8}',
                  //);
                  //if (!emailRegex.hasMatch(value.toString())) {
                    //return 'Enter a valid email address!';
                  //}
                },
                onSaved: (value) {
                  _user.email = value.toString();
                },
              ),
              SizedBox(height: 50.0),
              Text("password"),
              TextFormField(
                controller: _passwordTextController,
                decoration: InputDecoration(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 1.5,
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Enter the password',
                ),
                focusNode: _passwordFocusNode,
                onFieldSubmitted: (_) {
                  FocusScope.of(
                    context,
                  ).requestFocus(_passwordConfirmController);
                },

                // TODO: add a validator for password
                onSaved: (value) {
                  _user.password = value.toString();
                },
              ),
            ],
          ),

          FlutterPwValidator(
            key: validatorKey,
            controller: _passwordTextController,
            minLength: 8,
            uppercaseCharCount: 1,
            width: MediaQuery.sizeOf(context).width / 1.5,
            height: 50.0,
            onSuccess: () {},
          ),

          SizedBox(height: 50.0),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("confirm password"),
              TextFormField(
                decoration: InputDecoration(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 1.5,
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Confirm the password',
                ),
                focusNode: _passwordConfirmController,
                // TODO: add a validator for confirm password
                validator: (value) {
                  //if (value == null || value.isEmpty)
                    //return 'Please enter a valid value';
                  //if (_user.password != value.toString()) {
                    //return 'The passwords doesn\'t match';
                  //}
                },
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                _saveForm(database, _user);
              },
              child: Text("Submit"),
            ),
          ),
          Text("Login instead?"),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: widget.onToggle,
              child: Text("Login"),
            ),
          ),
        ],
      ),
    );
  }
}
