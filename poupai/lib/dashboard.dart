import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/api_services.dart';
import 'dashboard_widgets.dart';

/// Formatter de moeda BR (R$) para TextField
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

class _DashboardPageState extends State<DashboardPage> {
  final ApiService api = ApiService();
  final _fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');

  // ================== Estado Básico ==================
  final List<String> meses = const [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  final List<int> anos = List.generate(3, (i) => 2023 + i);

  String mesSelecionado = 'Junho';
  int anoSelecionado = DateTime.now().year;

  String get periodoAtual => '$mesSelecionado-$anoSelecionado';

  /// Estrutura: { "Mes-Ano": [ {id, categoria, valor, cor: Color, icone: IconData, tipo, data, usuario_id}, ... ] }
  Map<String, List<Map<String, dynamic>>> dadosPorPeriodo = {};

  String modoSelecionado = 'Dashboard';
  final List<String> modosDeVisualizacao = const ['Dashboard', 'Gráfico de Barras'];

  // Paleta de cores disponíveis (usadas para bloquear duplicidade no período)
  final List<Color> coresDisponiveis = const [
    Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple,
    Colors.pink, Colors.brown, Colors.cyan, Colors.indigo, Colors.lime,
    Colors.teal, Colors.amber, Colors.deepOrange, Colors.deepPurple,
    Colors.lightBlue, Colors.lightGreen, Colors.yellow, Colors.grey,
    Colors.blueGrey, Colors.black, Colors.white,
  ];

  // Ícones padrão
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

  // ================== Agregados ==================
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
    carregarCategoriasDoBanco();
  }

  // ================== API: Carregar & CRUD ==================
  Future<void> carregarCategoriasDoBanco() async {
    try {
      final mesNum = meses.indexOf(mesSelecionado) + 1;
      final resumo = await api.getResumo(anoSelecionado, mesNum, widget.token);

      final categorias = (resumo["categorias"] ?? []) as List<dynamic>;

      dadosPorPeriodo[periodoAtual] = categorias.map<Map<String, dynamic>>((cat) {
        final corStr = cat['cor']?.toString() ?? '0';
        final corInt = int.tryParse(corStr) ?? 0xFF9E9E9E;
        final iconeInt = int.tryParse(cat['icone']?.toString() ?? '') ?? Icons.help.codePoint;

        return {
          'id': cat['id'],
          'categoria': cat['nome'],
          'valor': (cat['valor'] ?? 0).toDouble(),
          'cor': Color(corInt),
          'icone': IconData(iconeInt, fontFamily: 'MaterialIcons'),
          'tipo': cat['tipo'],
          'data': cat['data'],
          'usuario_id': cat['usuario_id'],
        };
      }).toList();

      setState(() {});
    } catch (e) {
      // Em produção: trate melhor (dialog/telemetria)
      debugPrint("Erro ao carregar categorias: $e");
    }
  }

  Future<void> _excluirCategoria(int id) async {
    await api.excluirCategoria(widget.token, id);
    await carregarCategoriasDoBanco();
    setState(() {});
  }

  Future<void> _salvarCategoria(Map<String, dynamic> categoria) async {
    // Decide com base na existência de 'id'
    if (categoria.containsKey('id') && categoria['id'] != null) {
      await api.atualizarCategoria(widget.token, categoria['id'], categoria);
    } else {
      await api.criarCategoria(widget.token, categoria);
    }
    await carregarCategoriasDoBanco();
    setState(() {});
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
    Color corSelecionada = (categoria?['cor'] ?? Colors.blue) as Color;

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
                            backgroundColor: selecionado ? const Color(0xFF006155) : Colors.grey[300],
                            foregroundColor: selecionado ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setStateDialog(() {
                            tipoSelecionado = tipo;
                            iconesUsados = tipoSelecionado == 'Entrada' ? iconesEntrada : iconesDisponiveis;
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
                      final selecionado = operacao == op;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selecionado ? Colors.green : Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => setStateDialog(() => operacao = op),
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
                    decoration: const InputDecoration(labelText: 'Valor a ajustar (R\$)'),
                  ),
                  const SizedBox(height: 12),

                  // Nome da categoria
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome da categoria'),
                  ),
                  const SizedBox(height: 12),

                  // Cor
                  Row(
                    children: [
                      const Text('Cor:'),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Escolha uma cor'),
                              content: BlockPicker(
                                pickerColor: corSelecionada,
                                onColorChanged: (color) {
                                  // Bloqueio de cores já usadas no período (exceto a própria ao editar)
                                  final usadas = (dadosPorPeriodo[periodoAtual] ?? [])
                                      .where((c) => !isEditando || c['id'] != idCategoria)
                                      .map((c) => (c['cor'] as Color).value)
                                      .toSet();

                                  if (usadas.contains(color.value)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Essa cor já está sendo usada neste período.')),
                                    );
                                    return;
                                  }

                                  setStateDialog(() => corSelecionada = color);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: corSelecionada,
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
                            nomeController.text = entry.key; // atualiza o nome sempre
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: selecionado
                              ? const Color(0xFF006155).withOpacity(0.8)
                              : Colors.grey.shade200,
                          child: Icon(entry.value, color: Colors.black87),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006155)),
                onPressed: () async {
                  final nomeFinal = nomeController.text.trim().capitalize();
                  final valorDigitadoCent = double.tryParse(
                    valorAjusteController.text.replaceAll(RegExp(r'[^\d]'), ''),
                  ) ??
                      0.0;
                  final ajuste = valorDigitadoCent / 100.0;

                  if (nomeFinal.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha o nome da categoria.')),
                    );
                    return;
                  }

                  // Calcula novo valor (incremento/decremento) a partir do valor atual
                  final delta = operacao == 'Adicionar' ? ajuste : -ajuste;
                  final novoValor = (valorAtual + delta).clamp(0.0, double.infinity);

                  final dataSelecionada = DateFormat('yyyy-MM-dd').format(
                    DateTime(anoSelecionado, meses.indexOf(mesSelecionado) + 1, 1),
                  );

                  // Monta payload coerente com API (enviando o valor final)
                  final iconeCodePoint = (tipoSelecionado == 'Entrada'
                      ? iconesEntrada[iconeSelecionado]
                      : iconesDisponiveis[iconeSelecionado])
                      ?.codePoint ??
                      Icons.category.codePoint;

                  final payloadBase = {
                    'nome': nomeFinal,
                    'tipo': tipoSelecionado,
                    'valor': novoValor, // valor final após ajuste
                    'cor': corSelecionada.value.toString(), // API espera string
                    'icone': iconeCodePoint,
                    'usuario_id': widget.usuarioId,
                    'data': dataSelecionada,
                  };

                  if (isEditando) {
                    await _salvarCategoria({'id': idCategoria, ...payloadBase});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoria atualizada com sucesso!')),
                    );
                  } else {
                    await _salvarCategoria(payloadBase);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoria criada com sucesso!')),
                    );
                  }

                  await carregarCategoriasDoBanco();
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

  // ================== Exclusão (confirmação) ==================
  void _confirmarExcluirCategoria(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir esta categoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _excluirCategoria(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categoria excluída com sucesso.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ================== Gráficos ==================
  Widget _construirGraficoDeBarras() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final categoriasFiltradas =
    categorias.where((c) => ((c['valor'] ?? 0.0) as double) > 0).toList();

    if (categoriasFiltradas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nenhuma categoria cadastrada para este período.'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 300,
        width: categoriasFiltradas.length * 90,
        child: BarChart(
          BarChartData(
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
                    borderRadius: BorderRadius.circular(4),
                    color: cor,
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < categoriasFiltradas.length) {
                      final nome = categoriasFiltradas[idx]['categoria'] as String;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: SizedBox(
                          width: 70,
                          child: Text(
                            nome,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final cat = categoriasFiltradas[groupIndex];
                  final nome = cat['categoria'];
                  final valor = cat['valor'] as double;
                  return BarTooltipItem(
                    '$nome\n${_fmt.format(valor)}',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirGraficoPizza() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final gastos = categorias
        .where((c) => c['tipo'] == 'Gasto' && ((c['valor'] ?? 0.0) as double) > 0)
        .toList();

    if (gastos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nenhum gasto registrado neste período.'),
        ),
      );
    }

    final total = gastos.fold<double>(
      0.0,
          (soma, item) => soma + (item['valor'] as double),
    );

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: List.generate(gastos.length, (index) {
            final categoria = gastos[index];
            final valor = categoria['valor'] as double;
            final porcentagem = total > 0 ? (valor / total) * 100 : 0.0;
            return PieChartSectionData(
              color: categoria['cor'] as Color,
              value: valor,
              title: '${porcentagem.toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            );
          }),
          sectionsSpace: 2,
          centerSpaceRadius: 30,
        ),
      ),
    );
  }

  // ================== Bloco: Dashboard ==================
  Widget _construirDashboard() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    if (categorias.isEmpty) {
      return const Center(child: Text('Nenhuma categoria cadastrada para este período.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirGraficoPizza(),
        const SizedBox(height: 30),

        const Text('Gastos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Gasto').toList(),
          onExcluir: (i) {
            final lista = categorias.where((c) => c['tipo'] == 'Gasto').toList();
            _confirmarExcluirCategoria(lista[i]['id']);
          },
          onEditar: (i) {
            final lista = categorias.where((c) => c['tipo'] == 'Gasto').toList();
            _abrirCadastroCategoria(idCategoria: lista[i]['id']);
          },
        ),
        const SizedBox(height: 16),

        const Text('Entradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Entrada').toList(),
          onExcluir: (i) {
            final lista = categorias.where((c) => c['tipo'] == 'Entrada').toList();
            _confirmarExcluirCategoria(lista[i]['id']);
          },
          onEditar: (i) {
            final lista = categorias.where((c) => c['tipo'] == 'Entrada').toList();
            _abrirCadastroCategoria(idCategoria: lista[i]['id']);
          },
        ),
      ],
    );
  }

  // ================== Build ==================
  @override
  Widget build(BuildContext context) {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final categoriasFiltradas =
    categorias.where((c) => ((c['valor'] ?? 0.0) as double) > 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006155),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: modoSelecionado,
            dropdownColor: const Color(0xFF006155),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            onChanged: (novoModo) {
              setState(() => modoSelecionado = novoModo!);
            },
            items: modosDeVisualizacao
                .map((modo) => DropdownMenuItem(value: modo, child: Text(modo)))
                .toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategoria',
        onPressed: () => _abrirCadastroCategoria(),
        backgroundColor: const Color(0xFF006155),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Seleção de período (mês/ano)
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: mesSelecionado,
                    isExpanded: true,
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
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  const Text(
                    'Resumo por Categoria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (modoSelecionado == 'Dashboard')
                    _construirDashboard()
                  else
                    _construirGraficoDeBarras(),

                  const Divider(),

                  // Agregados (Entradas, Gastos, Saldo)
                  ListTile(
                    title: const Text('Entradas'),
                    trailing: Text(
                      _fmt.format(entradasFixas),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Gastos'),
                    trailing: Text(
                      _fmt.format(totalGastos),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Saldo'),
                    trailing: Text(
                      _fmt.format(saldo),
                      style: TextStyle(
                        color: saldo >= 0 ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}