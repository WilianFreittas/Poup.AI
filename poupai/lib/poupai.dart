import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart'; // ajuste se necessário

class PoupaiPage extends StatefulWidget {
  final int usuarioId;

  const PoupaiPage({required this.usuarioId});

  @override
  _PoupaiPageState createState() => _PoupaiPageState();
}

class _PoupaiPageState extends State<PoupaiPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _mensagens = [];
  final ScrollController _scrollController = ScrollController();

  String? _nomeUsuario;
  bool _mensagemInicialEnviada = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final nome = await DatabaseHelper().obterNomeUsuario(widget.usuarioId);
    final mensagens = await DatabaseHelper().listarMensagensAssistente(widget.usuarioId);

    setState(() {
      _nomeUsuario = nome ?? 'usuário';
      _mensagens.addAll(mensagens);
    });

    if (!_mensagemInicialEnviada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _enviarMensagemInicial();
      });
    }
    await Future.delayed(Duration(milliseconds: 100));
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _enviarMensagemInicial() async {
    final saudacao = 'Olá, $_nomeUsuario! 👋 Sou o Poup.ai\nEm que posso te ajudar hoje?';
    final dataHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final mensagemInicial = {
      'usuario_id': widget.usuarioId,
      'tipo': 'bot',
      'texto': saudacao,
      'data_hora': dataHora,
    };

    await DatabaseHelper().inserirMensagemAssistente(mensagemInicial);
    setState(() {
      _mensagens.add(mensagemInicial);
      _mensagemInicialEnviada = true;
    });

    await Future.delayed(Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

    Future<void> _enviarMensagem() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final dataHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final msgUsuario = {
      'usuario_id': widget.usuarioId,
      'tipo': 'usuario',
      'texto': texto,
      'data_hora': dataHora,
    };

    final respostaTexto = await _gerarRespostaSimples(texto);

    final msgBot = {
      'usuario_id': widget.usuarioId,
      'tipo': 'bot',
      'texto': respostaTexto,
      'data_hora': dataHora,
    };

    await DatabaseHelper().inserirMensagemAssistente(msgUsuario);
    await DatabaseHelper().inserirMensagemAssistente(msgBot);

    setState(() {
      _mensagens.addAll([msgUsuario, msgBot]);
      _controller.clear();
    });

    await Future.delayed(Duration(milliseconds: 100));
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }


  Future<String> _gerarRespostaSimples(String pergunta) async {
    final lower = pergunta.toLowerCase();

    // Mapas de meses por nome
    final Map<String, int> meses = {
      'janeiro': 1,
      'fevereiro': 2,
      'março': 3,
      'marco': 3,
      'abril': 4,
      'maio': 5,
      'junho': 6,
      'julho': 7,
      'agosto': 8,
      'setembro': 9,
      'outubro': 10,
      'novembro': 11,
      'dezembro': 12,
    };

    // Verifica se há menção a um mês na frase
    for (final entrada in meses.entries) {
      if (lower.contains(entrada.key)) {
        final now = DateTime.now();
        int anoDetectado = now.year;

        // Tenta identificar o ano digitado (ex: "junho de 2024")
        final matchAno = RegExp(r'(\d{4})').firstMatch(lower);
        if (matchAno != null) {
          anoDetectado = int.tryParse(matchAno.group(1) ?? '${now.year}') ?? now.year;
        }

        final mesFormatado = entrada.value.toString().padLeft(2, '0');
        final mesAno = '$anoDetectado-$mesFormatado';

        final total = await DatabaseHelper().calcularGastosDoMes(widget.usuarioId, mesAno);
        final mesCapitalizado = entrada.key[0].toUpperCase() + entrada.key.substring(1);
        return 'Você gastou R\$ ${total.toStringAsFixed(2)} em $mesCapitalizado de $anoDetectado.';
      }
    }

    // Se usuário perguntar por "meta"
    if (lower.contains('meta')) {
      final metas = await DatabaseHelper().obterMetasPorUsuario(widget.usuarioId);
      if (metas.isEmpty) {
        return 'Você ainda não tem metas cadastradas.';
      }

      final buffer = StringBuffer();
      for (var meta in metas) {
        final titulo = meta['titulo'];
        final valor = meta['meta'] ?? 0.0;
        final depositado = meta['depositado'] ?? 0.0;
        final progresso = valor > 0 ? ((depositado / valor) * 100).clamp(0, 100) : 0.0;

        buffer.writeln(
            'Meta "$titulo": R\$ ${depositado.toStringAsFixed(2)} de R\$ ${valor.toStringAsFixed(2)} (${progresso.toStringAsFixed(1)}%)');
      }
      return buffer.toString().trim();
    }

    // Frase genérica se não reconhecer o que foi pedido
    return 'Ainda estou aprendendo! Em breve saberei te ajudar melhor.';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assistente Poup.ai')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _mensagens.length + 1, // 👈 item extra
              itemBuilder: (context, index) {
                if (index == _mensagens.length) {
                  return SizedBox(height: 60); // 👈 espaço no fim
                }
                final mensagem = _mensagens[index];
                final isUsuario = mensagem['tipo'] == 'usuario';
                return Container(
                  alignment: isUsuario ? Alignment.centerRight : Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUsuario ? Colors.blue[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(mensagem['texto'] ?? ''),
                  ),
                );
              },
            ),
          ),

          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Digite sua pergunta...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
