import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/AuthService.dart';
import '../providers/Computer.dart';
import '../providers/SessionStorageService.dart';

class Signup extends StatefulWidget {
  final VoidCallback onToggle;

  Signup({required this.onToggle});

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String? _espMac;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMac();
  }

  Future<void> _loadMac() async {
    final session = SessionStorageService(userId: 'temp');
    _espMac = await session.getMacAddress();
    setState(() {});
  }

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState?.save();
    setState(() => _loading = true);

    final result = await AuthService.signup(
      email: _email,
      password: _password,
      espMac: _espMac ?? '',
    );

    setState(() => _loading = false);

    if (result['success']) {
      final userId = result['id'];

      // SALVEAZA user_id
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);

      // Mutam MAC-ul salvat temporar în spatiul userului real
      final tempSession = SessionStorageService(userId: 'temp');
      final realSession = SessionStorageService(userId: userId);
      final mac = await tempSession.getMacAddress();
      if (mac != null) {
        await realSession.saveMacAddress(mac);
      }

      final computerProvider = Computer(userId: userId);
      context.go('/bt-screen', extra: computerProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  return 'Email invalid. Ex: exemplu@email.com';
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
                if (value == null || value.isEmpty) {
                  return 'Introduceti o parola.';
                }
                if (value.length < 6) {
                  return 'Parola trebuie sa aiba minim 6 caractere.';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Parola trebuie să contina cel puțin o cifra.';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (_loading)
              CircularProgressIndicator()
            else
              ElevatedButton(onPressed: _submit, child: Text('Inregistrare')),
            TextButton(
              onPressed: widget.onToggle,
              child: Text('Ai deja cont? Autentifica-te'),
            ),
          ],
        ),
      ),
    );
  }
}
