import 'package:flutter/material.dart';

// TODO: initializam lista cu chestii ce is prin LAN cu ARP
Map<String, String> listDevices = {
  'id':'',
  'macAdd':'',
  'ip':''
};

class CardsList extends StatelessWidget {
  const CardsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text('My pc'),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12,),
                Text("Mac Address: C9:FD:17:37:D8:11"),
                Text("Ip: 81.227.255.101"),
                //Text("Last online: 2h ago")
              ],

            ),
            // functie unde trimitem pachetul magic catre pc
            // TODO: adaugat logica de true, false care sa se reflecte si in culoarea butonului
            trailing: IconButton(
              icon: Icon(Icons.power_settings_new, color: Colors.green,),
              onPressed: null,
            ),
          ),
        )

      ],
    );
  }
}
