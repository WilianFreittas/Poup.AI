import 'package:flutter/material.dart';

class ConfiguracoesAppPage extends StatefulWidget {
  @override
  _ConfiguracoesAppPageState createState() => _ConfiguracoesAppPageState();
}

class _ConfiguracoesAppPageState extends State<ConfiguracoesAppPage> {
  bool modoEscuro = false;
  bool notificacoesAtivas = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do App')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Modo Escuro"),
            value: modoEscuro,
            onChanged: (value) {
              setState(() {
                modoEscuro = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Notificações"),
            value: notificacoesAtivas,
            onChanged: (value) {
              setState(() {
                notificacoesAtivas = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Idioma"),
            subtitle: const Text("Português"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Funcionalidade de idioma ainda não implementada.")),
              );
            },
          ),
        ],
      ),
    );
  }
}
