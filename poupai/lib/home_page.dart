import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'poupai.dart';
import 'metas.dart';
import 'perfil_page.dart';
import 'configuracoes_conta_page.dart';
import 'configuracoes_app_page.dart';
import 'services/api_services.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  final String usuarioId;
  final String token;

  const HomePage({
    Key? key,
    required this.usuarioId,
    required this.token,
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

  // ======================================================
  // 📤 EXPORTAR DADOS (PDF)
  // ======================================================
  Future<void> _exportarDados() async {
    int anoSelecionado = DateTime.now().year;
    int mesSelecionado = DateTime.now().month;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selecionar período'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: anoSelecionado,
                    isExpanded: true,
                    items: [2023, 2024, 2025, 2026, 2027]
                        .map((ano) => DropdownMenuItem<int>(
                      value: ano,
                      child: Text(ano.toString()),
                    ))
                        .toList(),
                    onChanged: (valor) {
                      if (valor != null) {
                        setState(() => anoSelecionado = valor);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: mesSelecionado,
                    isExpanded: true,
                    items: List.generate(
                      12,
                          (i) => DropdownMenuItem<int>(
                        value: i + 1,
                        child: Text('${i + 1} - ${_nomeMes(i + 1)}'),
                      ),
                    ),
                    onChanged: (valor) {
                      if (valor != null) {
                        setState(() => mesSelecionado = valor);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmarExportacao(anoSelecionado, mesSelecionado);
                  },
                  child: const Text('Exportar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[mes - 1];
  }

  Future<void> _confirmarExportacao(int ano, int mes) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔄 Gerando PDF de $mes/$ano...')),
    );

    try {
      await apiService.exportarPdf(
        widget.token,
        ano: ano,
        mes: mes,
        context: context,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ PDF de $mes/$ano salvo na pasta Downloads!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro ao exportar: $e')),
      );
    }
  }

  // ======================================================
  // 🧭 INTERFACE PRINCIPAL
  // ======================================================
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
            // 🪪 Cabeçalho do menu lateral
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF006155)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF006155)),
                  ),
                  SizedBox(height: 10),
                  Text('Bem-vindo(a) ao Poup.AI',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),

            // ⚙️ Opções do menu
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerfilPage(
                      usuarioId: widget.usuarioId,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Configurações de Conta'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ConfiguracoesContaPage(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Configurações do App'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConfiguracoesAppPage(),
                  ),
                );
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

      // Corpo principal
      body: IndexedStack(
        index: _paginaAtual,
        children: _telas,
      ),

      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual,
        selectedItemColor: const Color(0xFF006155),
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