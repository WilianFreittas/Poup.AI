import 'package:flutter/material.dart';
import '../services/api_services.dart';

class PerfilPage extends StatefulWidget {
  final String usuarioId;
  final String token;

  const PerfilPage({
    super.key,
    required this.usuarioId,
    required this.token,
  });

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  // ======================================================
  // 🔹 CARREGA PERFIL SOMENTE VIA /auth/validate
  // ======================================================
  Future<void> _carregarPerfil() async {
    try {
      final response = await _apiService.get(
        "/auth/validate",
        token: widget.token,
      );

      emailController.text = response['email'] ?? '';
      nomeController.text = response['nome'] ?? '';

      setState(() => isLoading = false);
    } catch (e) {
      print("❌ Erro ao carregar perfil: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  // ======================================================
  // 💾 ATUALIZA SOMENTE O NOME
  // ======================================================
  Future<void> _salvarAlteracoes() async {
    final nome = nomeController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O nome não pode estar vazio.")),
      );
      return;
    }

    try {
      await _apiService.put(
        "/v1/usuarios/atualizar_nome",
        {"nome": nome},
        token: widget.token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil atualizado com sucesso!")),
      );
    } catch (e) {
      print("❌ Erro ao atualizar perfil: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar perfil: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.person, size: 80, color: Colors.teal),
            const SizedBox(height: 16),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: emailController,
              readOnly: true, // e-mail não pode ser alterado
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarAlteracoes,
              child: const Text("Salvar Alterações"),
            ),
          ],
        ),
      ),
    );
  }
}