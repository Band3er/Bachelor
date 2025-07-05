import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/AuthService.dart';
import '../providers/Computer.dart';

class Login extends StatefulWidget {
  final VoidCallback onToggle;

  Login({required this.onToggle});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState?.save();
    setState(() => _loading = true);

    final result = await AuthService.login(email: _email, password: _password);

    setState(() => _loading = false);

    if (result['success']) {
      final userId = result['id'];

      // Salvam userId in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);

      final computerProvider = Computer(userId: userId);
      await computerProvider.loadFromPrefs(); // incarcare date locale

      context.go('/', extra: computerProvider);
    } else {
      _showError(result['error']);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Eroare la autentificare'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction, // validare live
        child: Column(
          children: [
            TextFormField(
              key: ValueKey('email'),
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onSaved: (value) => _email = value!.trim(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introduceti un email.';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Email invalid. Exemplu: nume@email.com';
                }
                return null;
              },
            ),
            TextFormField(
              key: ValueKey('password'),
              decoration: InputDecoration(labelText: 'Parola'),
              obscureText: true,
              onSaved: (value) => _password = value!,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introduceti o parola.';
                }
                if (value.length < 6) {
                  return 'Parola trebuie sa aiba cel putin 6 caractere.';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (_loading)
              CircularProgressIndicator()
            else
              ElevatedButton(onPressed: _submit, child: Text('Autentificare')),
            TextButton(
              onPressed: widget.onToggle,
              child: Text('Nu ai cont? Inregistreaza-te'),
            ),
          ],
        ),
      ),
    );
  }
}
