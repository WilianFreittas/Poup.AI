import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesAppPage extends StatefulWidget {
  const ConfiguracoesAppPage({super.key});

  @override
  _ConfiguracoesAppPageState createState() => _ConfiguracoesAppPageState();
}

class _ConfiguracoesAppPageState extends State<ConfiguracoesAppPage> {
  bool modoEscuro = false;
  bool notificacoesAtivas = true;
  String idioma = "Português";

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  // ======================================================
  // 🔄 Carrega configurações salvas
  // ======================================================
  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      modoEscuro = prefs.getBool('modoEscuro') ?? false;
      notificacoesAtivas = prefs.getBool('notificacoesAtivas') ?? true;
      idioma = prefs.getString('idioma') ?? "Português";
    });
  }

  // ======================================================
  // 💾 Salva configuração no storage local
  // ======================================================
  Future<void> _salvarPreferencia(String chave, dynamic valor) async {
    final prefs = await SharedPreferences.getInstance();
    if (valor is bool) {
      await prefs.setBool(chave, valor);
    } else if (valor is String) {
      await prefs.setString(chave, valor);
    }
  }

  // ======================================================
  // 🌓 Alterna o modo escuro/claro
  // ======================================================
  void _alternarTema(bool value) async {
    setState(() {
      modoEscuro = value;
    });
    await _salvarPreferencia('modoEscuro', value);

    final themeMode = value ? ThemeMode.dark : ThemeMode.light;
    // Atualiza o tema globalmente (se o app usar ThemeMode)
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const ConfiguracoesAppPage(),
        ),
      ),
    );
  }

  // ======================================================
  // 🌐 Seleciona idioma
  // ======================================================
  void _selecionarIdioma() async {
    final novoIdioma = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Selecionar idioma"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Português"),
            child: const Text("🇧🇷 Português"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "English"),
            child: const Text("🇺🇸 English"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Español"),
            child: const Text("🇪🇸 Español"),
          ),
        ],
      ),
    );

    if (novoIdioma != null) {
      setState(() => idioma = novoIdioma);
      await _salvarPreferencia('idioma', novoIdioma);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Idioma alterado para $novoIdioma.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do App')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Modo Escuro"),
            value: modoEscuro,
            onChanged: _alternarTema,
          ),
          SwitchListTile(
            title: const Text("Notificações"),
            value: notificacoesAtivas,
            onChanged: (value) {
              setState(() => notificacoesAtivas = value);
              _salvarPreferencia('notificacoesAtivas', value);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value
                      ? "🔔 Notificações ativadas."
                      : "🔕 Notificações desativadas."),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Idioma"),
            subtitle: Text(idioma),
            onTap: _selecionarIdioma,
          ),
        ],
      ),
    );
  }
}