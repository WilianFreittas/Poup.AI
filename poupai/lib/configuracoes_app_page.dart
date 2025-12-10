import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_controller.dart';
import 'language_controller.dart';

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
      modoEscuro = prefs.getBool('modoEscuro') ?? false;     // ⬅️ ADICIONADO
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
  // 🌓 Alterna o modo escuro/claro (somente salva)
  // ======================================================
  void _alternarTema(bool value) {
    final controller = Provider.of<ThemeController>(context, listen: false);
    controller.toggleTheme(value);

    setState(() => modoEscuro = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? "🌙 Modo escuro ativado."
            : "☀️ Modo claro ativado."),
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
      final langController = Provider.of<LanguageController>(context, listen: false);

      await langController.changeLanguage(novoIdioma);

      setState(() => idioma = novoIdioma);

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