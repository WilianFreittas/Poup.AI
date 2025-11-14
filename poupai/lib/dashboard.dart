import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import 'dashboard_widgets.dart';

String colorToHex(Color c) {
  final v = c.value.toRadixString(16).padLeft(8, '0');
  return '#${v.substring(2).toUpperCase()}';
}

class CurrencyTextInputFormatter extends TextInputFormatter {
  CurrencyTextInputFormatter({this.locale = 'pt_BR', this.symbol = 'R\$'});

  final String locale;
  final String symbol;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) digitsOnly = '0';

    double value = double.parse(digitsOnly) / 100;
    final formatter = NumberFormat.currency(locale: locale, symbol: symbol);
    String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String usuarioId;
  final String token;

  const DashboardPage({
    Key? key,
    required this.usuarioId,
    required this.token,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : this;
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final ApiService api = ApiService();
  final _fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');

  // Estado do gráfico de pizza interativo
  int touchedIndex = -1;
  late AnimationController _animationController;

  final List<String> meses = const [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  final List<int> anos = List.generate(3, (i) => 2023 + i);

  String mesSelecionado = 'Junho';
  int anoSelecionado = DateTime.now().year;

  String get periodoAtual => '$mesSelecionado-$anoSelecionado';

  Map<String, List<Map<String, dynamic>>> dadosPorPeriodo = {};

  String modoSelecionado = 'Dashboard';
  final List<String> modosDeVisualizacao = const ['Dashboard', 'Gráfico de Barras'];

  final List<Color> coresDisponiveis = const [
    Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple,
    Colors.pink, Colors.brown, Colors.cyan, Colors.indigo, Colors.lime,
    Colors.teal, Colors.amber, Colors.deepOrange, Colors.deepPurple,
    Colors.lightBlue, Colors.lightGreen, Colors.yellow, Colors.grey,
    Colors.blueGrey, Colors.black, Colors.white,
  ];

  final Map<String, IconData> iconesDisponiveis = const {
    'Restaurante': Icons.restaurant,
    'Carro': Icons.directions_car,
    'Casa': Icons.home,
    'Lazer': Icons.sports_esports,
    'Mercado': Icons.shopping_cart,
    'Outros': Icons.category,
    'Educação': Icons.school,
    'Saúde': Icons.local_hospital,
    'Tecnologia': Icons.devices,
    'Viagem': Icons.flight,
    'Entretenimento': Icons.movie,
    'Fitness': Icons.fitness_center,
    'Pets': Icons.pets,
    'Presentes': Icons.card_giftcard,
    'Beleza': Icons.brush,
    'Investimentos': Icons.trending_up,
    'Serviços': Icons.build,
    'Esportes': Icons.sports,
  };

  final Map<String, IconData> iconesEntrada = const {
    'Salário': Icons.attach_money,
    'Freelancer': Icons.work,
    'Rendimentos': Icons.trending_up,
    'Investimentos': Icons.account_balance,
    'Reembolso': Icons.replay,
    'Outros': Icons.add_card,
  };

  double get entradasFixas {
    final lista = dadosPorPeriodo[periodoAtual];
    if (lista == null) return 0.0;
    return lista
        .where((item) => item['tipo'] == 'Entrada')
        .fold(0.0, (total, item) => total + ((item['valor'] ?? 0.0) as double));
  }

  double get totalGastos {
    final lista = dadosPorPeriodo[periodoAtual];
    if (lista == null) return 0.0;
    return lista
        .where((item) => item['tipo'] == 'Gasto')
        .fold(0.0, (total, item) => total + ((item['valor'] ?? 0.0) as double));
  }

  double get saldo => entradasFixas - totalGastos;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    carregarCategoriasDoBanco();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> carregarCategoriasDoBanco() async {
    try {
      final mesNum = meses.indexOf(mesSelecionado) + 1;

      final categorias = await api.getCategorias(widget.token);
      final transacoes = await api.getTransacoes(widget.token, anoSelecionado, mesNum);

      final agrupado = <String, Map<String, dynamic>>{};

      for (var trans in transacoes) {
        final categoriaId = trans['categoria_id'];
        final cat = categorias.firstWhere(
              (c) => c['id'] == categoriaId,
          orElse: () => {'nome': 'Sem Categoria', 'cor': '#9E9E9E', 'icone': 'Outros'},
        );

        final tipo = trans['tipo_transacao'] == 'receita' ? 'Entrada' : 'Gasto';
        final valor = double.tryParse(trans['valor_transacao'].toString()) ?? 0.0;
        final corStr = cat['cor'].toString();
        final cor = corStr.startsWith('#')
            ? Color(int.parse(corStr.substring(1), radix: 16) + 0xFF000000)
            : Color(int.tryParse(corStr) ?? 0xFF9E9E9E);
        final nome = trans['observacao'] ?? cat['nome'];
        final iconeStr = cat['icone']?.toString() ?? 'Outros';

        // Cria chave única usando categoria_id
        final chave = 'cat_$categoriaId';

        if (!agrupado.containsKey(chave)) {
          agrupado[chave] = {
            'id': categoriaId,
            'categoria': cat['nome'] ?? nome,
            'valor': 0.0,
            'tipo': tipo,
            'cor': cor,
            'icone': getIconFromName(iconeStr),
            'transacoes': <Map<String, dynamic>>[],
          };
        }

        agrupado[chave]!['valor'] += valor;

        // Adiciona transação individual
        (agrupado[chave]!['transacoes'] as List).add({
          'transacao_id': trans['id'],
          'valor': valor,
          'data': trans['data_transacao'],
          'observacao': trans['observacao'] ?? cat['nome'],
          'tipo': tipo,
        });
      }

      dadosPorPeriodo[periodoAtual] = agrupado.values.toList();
      setState(() {});
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  Future<void> _excluirTransacao(dynamic id) async {
    try {
      await api.excluirTransacao(widget.token, id);
      await carregarCategoriasDoBanco();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação excluída com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir transação: $e')),
      );
    }
  }

  Color obterProximaCorDisponivel() {
    final usadas = (dadosPorPeriodo[periodoAtual] ?? [])
        .map((c) => (c['cor'] as Color).value)
        .toSet();

    for (final cor in coresDisponiveis) {
      if (!usadas.contains(cor.value)) {
        return cor;
      }
    }
    return Colors.grey;
  }

// ================== Diálogo de Cadastro/Edição ==================
  void _abrirCadastroCategoria({int? idCategoria}) {
    final bool isEditando = idCategoria != null;
    final listaPeriodo = dadosPorPeriodo[periodoAtual] ?? [];

    final Map<String, dynamic>? categoria = isEditando
        ? listaPeriodo.firstWhere((c) => c['id'] == idCategoria, orElse: () => {})
        : null;

    String tipoSelecionado = (categoria?['tipo'] ?? 'Gasto') as String;
    String nome = (categoria?['categoria'] ?? '') as String;
    final double valorAtual = (categoria?['valor'] ?? 0.0) as double;
    Color corSelecionada = categoria?['cor'] != null
        ? categoria!['cor'] as Color
        : obterProximaCorDisponivel();

    // Ícones por tipo
    Map<String, IconData> iconesUsados =
    tipoSelecionado == 'Entrada' ? iconesEntrada : iconesDisponiveis;
    String iconeSelecionado = 'Outros';

    // Operação incremental (igual versão antiga)
    String operacao = 'Adicionar';

    final nomeController = TextEditingController(text: nome);
    final valorAjusteController = TextEditingController(
      text: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(0),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEditando ? 'Editar ${tipoSelecionado}' : 'Nova ${tipoSelecionado}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Gasto', 'Entrada'].map((tipo) {
                      final bool selecionado = tipoSelecionado == tipo;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selecionado
                                ? const Color(0xFF006155)
                                : Colors.grey[300],
                            foregroundColor: selecionado ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setStateDialog(() {
                            tipoSelecionado = tipo;
                            iconesUsados = tipoSelecionado == 'Entrada'
                                ? iconesEntrada
                                : iconesDisponiveis;
                            if (!iconesUsados.containsKey(iconeSelecionado)) {
                              iconeSelecionado = 'Outros';
                            }
                          }),
                          child: Text(tipo),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Valor atual
                  Text('Valor atual: ${_fmt.format(valorAtual)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),

                  // Operação Adicionar/Remover (incremental)
                  const Text('Operação:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Adicionar', 'Remover'].map((op) {
                      final bool selecionado = operacao == op;
                      final bool ehAdicionar = op == 'Adicionar';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selecionado
                                ? (ehAdicionar ? Colors.green : Colors.redAccent)
                                : Colors.grey[300],
                            foregroundColor:
                            selecionado ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              operacao = op; // ✅ Atualiza corretamente
                            });
                          },
                          child: Text(op),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Valor a ajustar (currency)
                  TextField(
                    controller: valorAjusteController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyTextInputFormatter()],
                    decoration:
                    const InputDecoration(labelText: 'Valor a ajustar (R\$)'),
                  ),
                  const SizedBox(height: 12),

                  // Nome da categoria
                  TextField(
                    controller: nomeController,
                    decoration:
                    const InputDecoration(labelText: 'Nome da categoria'),
                  ),
                  const SizedBox(height: 12),

                  // Cor
                  Row(
                    children: [
                      const Text('Cor:'),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final usadas = (dadosPorPeriodo[periodoAtual] ?? [])
                              .where(
                                  (c) => !isEditando || c['id'] != idCategoria)
                              .map((c) {
                            final valor = c['cor'];
                            if (valor is Color) return valor.value;
                            if (valor is String && valor.startsWith('#')) {
                              return int.parse(valor.substring(1), radix: 16) +
                                  0xFF000000;
                            }
                            if (valor is String && valor.isNotEmpty) {
                              return int.tryParse(valor) ?? 0;
                            }
                            return Colors.transparent.value;
                          })
                              .toSet();
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Escolha uma cor'),
                              content: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: coresDisponiveis.map((color) {
                                    final bloqueada = usadas.any(
                                            (u) => (u & 0xFFFFFF) ==
                                            (color.value & 0xFFFFFF));
                                    return GestureDetector(
                                      onTap: bloqueada
                                          ? null
                                          : () {
                                        setStateDialog(() =>
                                        corSelecionada = color);
                                        setState(() {});
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(
                                              bloqueada ? 0.3 : 1.0),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: bloqueada
                                                ? Colors.redAccent
                                                .withOpacity(0.5)
                                                : Colors.grey.shade400,
                                            width: bloqueada ? 2 : 1,
                                          ),
                                        ),
                                        child: bloqueada
                                            ? const Icon(Icons.block,
                                            color: Colors.white, size: 16)
                                            : (color == corSelecionada
                                            ? const Icon(Icons.check,
                                            color: Colors.white, size: 16)
                                            : null),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: corSelecionada ?? obterProximaCorDisponivel(),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ícones (dinâmico conforme tipo)
                  const Text('Ícone:'),
                  Wrap(
                    spacing: 8,
                    children: iconesUsados.entries.map((entry) {
                      final bool selecionado = entry.key == iconeSelecionado;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            iconeSelecionado = entry.key;
                            nomeController.text = entry.key; // atualiza o nome
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: selecionado
                              ? const Color(0xFF006155).withOpacity(0.8)
                              : Colors.grey.shade200,
                          child:
                          Icon(entry.value, color: Colors.black87),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006155)),
                onPressed: () async {
                  final nomeFinal = nomeController.text.trim().capitalize();
                  final valorDigitadoCent = double.tryParse(
                    valorAjusteController.text
                        .replaceAll(RegExp(r'[^\d]'), ''),
                  ) ??
                      0.0;
                  final ajuste = valorDigitadoCent / 100.0;

                  if (nomeFinal.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Preencha o nome da categoria.')),
                    );
                    return;
                  }

                  final delta = operacao == 'Adicionar' ? ajuste : -ajuste;
                  final novoValor =
                  (valorAtual + delta).clamp(0.0, double.infinity);

                  final dataSelecionada = DateFormat('yyyy-MM-dd').format(
                    DateTime(anoSelecionado,
                        meses.indexOf(mesSelecionado) + 1, 1),
                  );

                  if (isEditando) {
                    final transacaoId = categoria?['transacao_id'] ?? 1;
                    final categoriaId = categoria?['id'] ?? idCategoria ?? 1;

                    if (categoriaId != null && categoriaId > 0) {
                      try {
                        await api.atualizarCategoria(
                          widget.token,
                          categoriaId,
                          {
                            'cor': colorToHex(corSelecionada),
                            'icone': iconeSelecionado,
                            'nome': nomeFinal,
                          },
                        );
                      } catch (e) {
                        debugPrint(
                            '⚠️ Falha ao atualizar categoria: $e');
                      }
                    }

                    final payload = {
                      'usuario_id': widget.usuarioId,
                      'categoria_id': categoriaId,
                      'tipo_transacao':
                      tipoSelecionado == 'Entrada'
                          ? 'receita'
                          : 'despesa',
                      'valor_transacao': novoValor,
                      'data_transacao': dataSelecionada,
                      'observacao': nomeFinal,
                      'cor': colorToHex(corSelecionada),
                      'icone': iconeSelecionado,
                      'nome': nomeFinal,
                    };

                    await api.atualizarTransacao(
                        widget.token, transacaoId, payload);
                  } else {
                    final categoriaId = idCategoria ?? categoria?['id'] ?? 1;
                    final corFinal =
                        corSelecionada ?? obterProximaCorDisponivel();

                    final payload = {
                      'usuario_id': widget.usuarioId,
                      'categoria_id': categoriaId,
                      'tipo_transacao':
                      tipoSelecionado == 'Entrada'
                          ? 'receita'
                          : 'despesa',
                      'valor_transacao': novoValor,
                      'data_transacao': dataSelecionada,
                      'observacao': nomeFinal,
                      'cor': colorToHex(corFinal),
                      'icone': iconeSelecionado,
                      'nome': nomeFinal,
                    };

                    await api.criarTransacao(widget.token, payload);
                  }

                  await carregarCategoriasDoBanco();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditando
                            ? 'Transação atualizada com sucesso!'
                            : 'Transação criada com sucesso!'),
                      ),
                    );
                  }
                  setState(() {});
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmarExcluirCategoria(dynamic id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir esta categoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _excluirTransacao(id);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // 🎨 GRÁFICO DE PIZZA INTERATIVO MODERNIZADO
  Widget _construirGraficoPizzaModerno() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final gastos = categorias
        .where((c) => c['tipo'] == 'Gasto' && ((c['valor'] ?? 0.0) as double) > 0)
        .toList();

    if (gastos.isEmpty) {
      return _buildEmptyState('Nenhum gasto registrado');
    }

    final total = gastos.fold<double>(
      0.0,
          (soma, item) => soma + (item['valor'] as double),
    );

    return Column(
      children: [
        // Gráfico de pizza com animação
        SizedBox(
          height: 280,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(gastos.length, (index) {
                final categoria = gastos[index];
                final valor = categoria['valor'] as double;
                final cor = categoria['cor'] as Color;
                final icone = categoria['icone'] as IconData;
                final porcentagem = total > 0 ? (valor / total) * 100 : 0.0;
                final isTouched = index == touchedIndex;
                final fontSize = isTouched ? 18.0 : 14.0;
                final radius = isTouched ? 75.0 : 60.0;

                return PieChartSectionData(
                  color: cor,
                  value: valor,
                  title: isTouched
                      ? '${categoria['categoria']}\n${porcentagem.toStringAsFixed(1)}%'
                      : '${porcentagem.toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  badgeWidget: isTouched
                      ? _buildBadge(icone, cor)
                      : null,
                  badgePositionPercentageOffset: 1.3,
                );
              }),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
            ),
            swapAnimationDuration: const Duration(milliseconds: 300),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),

        const SizedBox(height: 24),

        // Legenda moderna
        _buildLegenda(gastos, total),
      ],
    );
  }

  Widget _buildBadge(IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icone, color: cor, size: 24),
    );
  }

  Widget _buildLegenda(List<Map<String, dynamic>> gastos, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: gastos.map((categoria) {
          final valor = categoria['valor'] as double;
          final cor = categoria['cor'] as Color;
          final icone = categoria['icone'] as IconData;
          final nome = categoria['categoria'] as String;
          final porcentagem = total > 0 ? (valor / total) * 100 : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: cor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: porcentagem / 100,
                        backgroundColor: cor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(cor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt.format(valor),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${porcentagem.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 📊 GRÁFICO DE BARRAS MODERNIZADO
  Widget _construirGraficoDeBarras() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final categoriasFiltradas =
    categorias.where((c) => ((c['valor'] ?? 0.0) as double) > 0).toList();

    if (categoriasFiltradas.isEmpty) {
      return _buildEmptyState('Nenhuma categoria cadastrada');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 300,
          width: categoriasFiltradas.length * 90,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: categoriasFiltradas
                  .map((e) => e['valor'] as double)
                  .reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: const Color(0xFF006155),
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.all(12),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final cat = categoriasFiltradas[groupIndex];
                    final nome = cat['categoria'];
                    final valor = cat['valor'] as double;

                    return BarTooltipItem(
                      '$nome\n${_fmt.format(valor)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < categoriasFiltradas.length) {
                        final categoria = categoriasFiltradas[idx];
                        final icone = categoria['icone'] as IconData;
                        final cor = categoria['cor'] as Color;

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(icone, color: cor, size: 20),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) => Text(
                      _fmt.format(value),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200],
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(categoriasFiltradas.length, (index) {
                final categoria = categoriasFiltradas[index];
                final valor = categoria['valor'] as double;
                final cor = categoria['cor'] as Color;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: valor,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      gradient: LinearGradient(
                        colors: [cor.withOpacity(0.7), cor],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDashboard() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    if (categorias.isEmpty) {
      return _buildEmptyState('Nenhuma categoria cadastrada para este período.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirGraficoPizzaModerno(),
        const SizedBox(height: 30),

        _buildSectionTitle('Gastos', Icons.arrow_downward, Colors.redAccent),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Gasto').toList(),
          onExcluir: (transacaoId) {
            _confirmarExcluirCategoria(transacaoId);
          },
          onEditar: (transacaoId) {
            _abrirCadastroCategoria(idCategoria: transacaoId);
          },
          fmt: _fmt,
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('Entradas', Icons.arrow_upward, Colors.green),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Entrada').toList(),
          onExcluir: (i) {
            final lista = categorias.where((c) => c['tipo'] == 'Entrada').toList();
            _confirmarExcluirCategoria(lista[i]['transacao_id']);
          },
          onEditar: (i) {
            final lista = categorias.where((c) => c['tipo'] == 'Entrada').toList();
            _abrirCadastroCategoria(idCategoria: lista[i]['id']);
          },
          fmt: _fmt,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF006155),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: modoSelecionado,
            dropdownColor: const Color(0xFF006155),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            onChanged: (novoModo) {
              setState(() => modoSelecionado = novoModo!);
            },
            items: modosDeVisualizacao
                .map((modo) => DropdownMenuItem(value: modo, child: Text(modo)))
                .toList(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarCategoriasDoBanco,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addCategoria',
        onPressed: () async {
          await carregarCategoriasDoBanco();
          _abrirCadastroCategoria();
        },
        backgroundColor: const Color(0xFF006155),
        icon: const Icon(Icons.add),
        label: const Text('Nova Transação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 🔹 Seletor de período modernizado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF006155)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: mesSelecionado,
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (novo) async {
                        setState(() => mesSelecionado = novo!);
                        await carregarCategoriasDoBanco();
                      },
                      items: meses
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<int>(
                      value: anoSelecionado,
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (novo) async {
                        setState(() => anoSelecionado = novo!);
                        await carregarCategoriasDoBanco();
                      },
                      items: anos
                          .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.toString()),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Cards de resumo (agora scrollam junto)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Entradas',
                    entradasFixas,
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Gastos',
                    totalGastos,
                    Icons.arrow_downward,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Saldo',
              saldo,
              saldo >= 0 ? Icons.check_circle : Icons.warning,
              saldo >= 0 ? const Color(0xFF006155) : Colors.orange,
            ),

            const SizedBox(height: 20),

            // 🔹 Conteúdo principal (Dashboard ou Gráfico)
            if (modoSelecionado == 'Dashboard')
              _construirDashboard()
            else
              _construirGraficoDeBarras(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt.format(valor),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

