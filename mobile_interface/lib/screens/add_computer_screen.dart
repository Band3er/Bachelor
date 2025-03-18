import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddComputerScreen extends StatelessWidget {
  AddComputerScreen({super.key});

  final _form = GlobalKey<FormState>();
  final _macAdd = FocusNode();
  final _ip = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Computer'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back)),
        ], // TODO
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Mac Address'),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {},
                // TODO
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please provide a value';
                  }
                  return null;
                },
                onSaved: (value) {
                  // add to list as it should
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'IP Address'),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {},
                // TODO
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please provide a value';
                  }
                  return null;
                },
                onSaved: (value) {
                  // add to list as it should
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
