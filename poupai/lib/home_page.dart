import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'poupai.dart';
import 'metas.dart';
import 'perfil_page.dart';
import 'configuracoes_conta_page.dart';
import 'configuracoes_app_page.dart';
import 'services/api_services.dart'; // integração com FastAPI

class HomePage extends StatefulWidget {
  /// Agora o ID vem do Supabase Auth (UUID)
  final String usuarioId;
  final String token;

  const HomePage({
    Key? key,
    required this.usuarioId,
    required this.token, // ✅ novo
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaAtual = 0;

  late List<Widget> _telas;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _telas = [
      DashboardPage(usuarioId: widget.usuarioId, token: widget.token),
      PoupaiPage(usuarioId: widget.usuarioId, token: widget.token),
      MetasPage(usuarioId: widget.usuarioId, token: widget.token),
    ];
  }

  /// === Função para exportar dados do usuário ===
  Future<void> _exportarDados() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Iniciando exportação...')),
    );

    try {
      final data = await apiService.getResumoCompleto(widget.token); // ✅ usa token

      // exemplo simples de exportação local
      print('📦 Dados exportados: $data');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Exportação concluída!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro ao exportar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poup.AI'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF006155)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações de Conta'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ConfiguracoesContaPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Configurações do App'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ConfiguracoesAppPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Exportar Dados'),
              onTap: () {
                Navigator.pop(context);
                _exportarDados();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _paginaAtual,
        children: _telas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual,
        onTap: (index) => setState(() => _paginaAtual = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Poup.ai'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
        ],
      ),
    );
  }
}
