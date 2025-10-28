import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PoupaiPage extends StatefulWidget {
  final String usuarioId;
  final String token;

  const PoupaiPage({
    required this.usuarioId,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  State<PoupaiPage> createState() => _PoupaiPageState();
}

class _PoupaiPageState extends State<PoupaiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _mensagens = [];
  final ApiService _apiService = ApiService();

  bool _mensagemInicialEnviada = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _enviarMensagemInicial();
  }

  // ======================================================
  // 👋 MENSAGEM INICIAL
  // ======================================================
  Future<void> _enviarMensagemInicial() async {
    if (_mensagemInicialEnviada) return;

    final saudacao =
        'Olá 👋 Sou o Poup.ai, seu assistente financeiro.\nEm que posso te ajudar hoje?';
    final dataHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    setState(() {
      _mensagens.add({
        'tipo': 'bot',
        'texto': saudacao,
        'data_hora': dataHora,
      });
      _mensagemInicialEnviada = true;
    });
  }

  // ======================================================
  // 💬 ENVIAR MENSAGEM DO USUÁRIO
  // ======================================================
  Future<void> _enviarMensagem() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _carregando) return;

    final dataHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final msgUsuario = {
      'usuario_id': widget.usuarioId,
      'tipo': 'usuario',
      'texto': texto,
      'data_hora': dataHora,
    };

    setState(() {
      _mensagens.add(msgUsuario);
      _controller.clear();
      _carregando = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

    // 🔁 Envia para o backend FastAPI via ApiService
    await _obterRespostaIA(texto);
  }

  // ======================================================
  // 🧠 CHAMADA PARA A IA VIA API SERVICE
  // ======================================================
  Future<void> _obterRespostaIA(String texto) async {
    try {
      final agora = DateTime.now();
      final bool perguntaFinanceira = texto.toLowerCase().contains("gasto") ||
          texto.toLowerCase().contains("despesa") ||
          texto.toLowerCase().contains("saldo") ||
          texto.toLowerCase().contains("meta");

      final resposta = await _apiService.enviarMensagemIA(
        widget.token,
        texto,
        ano: perguntaFinanceira ? agora.year : null,
        mes: perguntaFinanceira ? agora.month : null,
      );

      final dataHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final msgBot = {
        'usuario_id': widget.usuarioId,
        'tipo': 'bot',
        'texto': resposta,
        'data_hora': dataHora,
      };

      setState(() {
        _mensagens.add(msgBot);
      });
    } catch (e) {
      setState(() {
        _mensagens.add({
          'tipo': 'bot',
          'texto':
          '❌ Ocorreu um erro ao comunicar com o assistente. Tente novamente.',
        });
      });
    } finally {
      setState(() => _carregando = false);
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  // ======================================================
  // 🧱 INTERFACE DO CHAT
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente Poup.ai')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _mensagens.length + (_carregando ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _mensagens.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final mensagem = _mensagens[index];
                final isUsuario = mensagem['tipo'] == 'usuario';

                return Align(
                  alignment:
                  isUsuario ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUsuario ? Colors.blue[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // 🔹 Usa MarkdownBody para mensagens da IA
                    child: isUsuario
                        ? Text(
                      mensagem['texto'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    )
                        : MarkdownBody(
                      data: mensagem['texto'] ?? '',
                      styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context))
                          .copyWith(
                        p: const TextStyle(fontSize: 15),
                        strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Campo de entrada de texto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey[100],
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Digite sua pergunta...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _enviarMensagem,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}