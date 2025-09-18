import 'package:flutter/material.dart';

class ConfiguracoesContaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Conta')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar Senha'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Funcionalidade ainda não implementada.")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Excluir Conta'),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Excluir Conta"),
                  content: const Text("Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                    ElevatedButton(onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conta excluída.")));
                    }, child: const Text("Excluir"))
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
