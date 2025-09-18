import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  final TextEditingController nomeController = TextEditingController(text: "Bruno de Almeida");
  final TextEditingController emailController = TextEditingController(text: "bruno@gmail.com");
  final TextEditingController telefoneController = TextEditingController(text: "(11) 99887-6543");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.person, size: 80, color: Colors.teal),
            const SizedBox(height: 16),
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail')),
            TextField(controller: telefoneController, decoration: const InputDecoration(labelText: 'Telefone')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Perfil atualizado com sucesso!")),
                );
              },
              child: const Text("Salvar Alterações"),
            )
          ],
        ),
      ),
    );
  }
}
