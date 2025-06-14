import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_drawer.dart';
import '../widgets/card_list.dart';
import '../providers/Computer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var computer = new Computer();
    return Scaffold(
      appBar: AppBar(title: Text('Wake on Lan page'), backgroundColor: Theme.of(context).primaryColor,),
      drawer: AppDrawer(),
      body: CardsList(),
      //floatingActionButton: FloatingActionButton(onPressed: ()=> context.go('/add-computer'), child: Icon(Icons.add),),
      floatingActionButton: FloatingActionButton(onPressed: ()=> computer.sendData(), child: Icon(Icons.add),),
    );
  }
}
