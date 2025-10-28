import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'login.dart';

class ConfiguracoesContaPage extends StatefulWidget {
  final String token;
  const ConfiguracoesContaPage({super.key, required this.token});

  @override
  State<ConfiguracoesContaPage> createState() => _ConfiguracoesContaPageState();
}

class _ConfiguracoesContaPageState extends State<ConfiguracoesContaPage> {
  final ApiService _apiService = ApiService();

  // ======================================================
  // 🔐 ALTERAR SENHA
  // ======================================================
  Future<void> _alterarSenha() async {
    final novaSenhaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Alterar Senha"),
        content: TextField(
          controller: novaSenhaController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Nova senha",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final novaSenha = novaSenhaController.text.trim();
              if (novaSenha.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Digite a nova senha.")),
                );
                return;
              }

              Navigator.pop(context); // fecha o diálogo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Alterando senha...")),
              );

              try {
                await _apiService.alterarSenha(widget.token, novaSenha);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Senha alterada com sucesso!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro ao alterar senha: $e")),
                );
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🚪 SAIR (LOGOUT)
  // ======================================================
  void _sair() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sair"),
        content: const Text("Deseja realmente sair da sua conta?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
              );
            },
            child: const Text("Sair"),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🗑️ EXCLUIR CONTA
  // ======================================================
  Future<void> _excluirConta() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir Conta"),
        content: const Text("Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // fecha diálogo
              try {
                await _apiService.excluirConta(widget.token);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Conta excluída permanentemente.")),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Login()),
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro ao excluir conta: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Conta')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar Senha'),
            onTap: _alterarSenha,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: _sair,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Excluir Conta'),
            onTap: _excluirConta,
          ),
        ],
      ),
    );
  }
}