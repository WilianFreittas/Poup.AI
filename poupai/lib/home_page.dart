import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'poupai.dart';
import 'metas.dart';
import 'perfil_page.dart';
import 'configuracoes_conta_page.dart';
import 'configuracoes_app_page.dart';

class HomePage extends StatefulWidget {
  final int usuarioId;

  const HomePage({Key? key, required this.usuarioId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaAtual = 1;

  late List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    _telas = [
      DashboardPage(usuarioId: widget.usuarioId),
      PoupaiPage(usuarioId: widget.usuarioId),
      MetasPage(usuarioId: widget.usuarioId),
    ];
  }
  void _exportarDados() async {
    // Aqui você pode implementar a lógica de exportação real
    // Por exemplo, exportar como CSV ou JSON

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação iniciada...'),
      ),
    );

    // TODO: sua lógica de exportação aqui
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PerfilPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações de Conta'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConfiguracoesContaPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Configurações do App'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConfiguracoesAppPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.file_download),
              title: Text('Exportar Dados'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                _exportarDados();       // Chama a função de exportação
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
        onTap: (index) {
          setState(() {
            _paginaAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Poup.ai',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Metas',
          ),
        ],
      ),
    );
  }
}
