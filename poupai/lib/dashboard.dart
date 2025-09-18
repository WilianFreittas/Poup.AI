import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poupai/database_helper.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dashboard_widgets.dart';

class CurrencyTextInputFormatter extends TextInputFormatter {
  CurrencyTextInputFormatter({this.locale = 'pt_BR', this.symbol = 'R\$'});

  final String locale;
  final String symbol;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
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
  final int usuarioId;
  const DashboardPage({Key? key, required this.usuarioId}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : this;
}

class _DashboardPageState extends State<DashboardPage> {
  Widget _construirGraficoDeBarras() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];

    final categoriasFiltradas = categorias.where((c) => (c['valor'] ?? 0) > 0).toList();

    if (categoriasFiltradas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nenhuma categoria cadastrada para este período.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: 300,
            width: categoriasFiltradas.length * 80,
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'R\$ ${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
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
                              width: 50,
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
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final categoria = categoriasFiltradas[groupIndex]['categoria'];
                      final valor = categoriasFiltradas[groupIndex]['valor'] as double;
                      return BarTooltipItem(
                        '$categoria\nR\$ ${valor.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text('Gastos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Gasto').toList(),
          onEditar: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Gasto').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _abrirCadastroCategoria(index: indexReal);
          },

          onExcluir: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Gasto').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _confirmarExcluirCategoria(indexReal);
          },

        ),
        const SizedBox(height: 16),
        const Text('Entradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Entrada').toList(),
          onEditar: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Entrada').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _abrirCadastroCategoria(index: indexReal);
          },

          onExcluir: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Entrada').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _confirmarExcluirCategoria(indexReal);
          },

        ),
      ],
    );
  }

  List<String> meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  List<int> anos = List.generate(3, (i) => 2023 + i);

  String mesSelecionado = 'Junho';
  int anoSelecionado = DateTime.now().year;

  String get periodoAtual => '$mesSelecionado-$anoSelecionado';
  Map<String, List<Map<String, dynamic>>> dadosPorPeriodo = {};

  String modoSelecionado = 'Dashboard';
  List<String> modosDeVisualizacao = ['Dashboard', 'Gráfico de Barras'];

  List<Color> coresDisponiveis = [
    Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple,
    Colors.pink, Colors.brown, Colors.cyan, Colors.indigo, Colors.lime,
    Colors.teal, Colors.amber, Colors.deepOrange, Colors.deepPurple, Colors.lightBlue,
    Colors.lightGreen, Colors.yellow, Colors.grey, Colors.blueGrey,
    Colors.black, Colors.white, Colors.lightGreenAccent, Colors.deepPurpleAccent,
    Colors.blueAccent, Colors.orangeAccent
  ];

  Map<String, IconData> iconesDisponiveis = {
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

  Map<String, IconData> iconesEntrada = {
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
        .fold(0.0, (total, item) => total + (item['valor'] ?? 0.0));
  }

  double get totalGastos {
    final lista = dadosPorPeriodo[periodoAtual];
    if (lista == null) return 0.0;
    return lista
        .where((item) => item['tipo'] == 'Gasto')
        .fold(0.0, (total, item) => total + (item['valor'] ?? 0.0));
  }

  double get saldo => entradasFixas - totalGastos;

  @override
  void initState() {
    super.initState();
    carregarCategoriasDoBanco();
  }

  Future<void> carregarCategoriasDoBanco() async {
    final db = await DatabaseHelper().database;

    // Garantir que o mês seja encontrado corretamente mesmo com diferenças de acento ou maiúsculas
    final idxMes = meses.indexWhere((m) => m.toLowerCase() == mesSelecionado.toLowerCase());

    if (idxMes == -1) {
      print('Mês inválido: $mesSelecionado');
      return;
    }

    final mes = (meses.indexOf(mesSelecionado) + 1).toString().padLeft(2, '0');
    final dataFormatada = '$anoSelecionado-$mes';
    final dataInicio = '$anoSelecionado-$mes-01';
    final dataFim = DateFormat('yyyy-MM-dd').format(
      DateTime(anoSelecionado, idxMes + 2, 1).subtract(const Duration(days: 1)),
    );

    final resultados = await db.rawQuery('''
  SELECT c.*, 
         IFNULL(SUM(t.valor), 0.0) as valor
    FROM categorias c
    LEFT JOIN transacoes t
      ON t.categoria_id = c.id
     AND t.usuario_id = ?
     AND t.data LIKE ?
   WHERE c.usuario_id = ?
     AND c.data LIKE ?
   GROUP BY c.id
''', [widget.usuarioId, '$dataFormatada%', widget.usuarioId, '$dataFormatada%']);

    final mesAno = '$mesSelecionado-$anoSelecionado';
    dadosPorPeriodo[mesAno] = resultados.map((cat) {
      return {
        'id': cat['id'],
        'categoria': cat['nome'],
        'valor': cat['valor'] ?? 0.0,
        'cor': Color(int.tryParse(cat['cor'].toString()) ?? 0xFF9E9E9E),
        'icone': IconData(
          int.tryParse(cat['icone'].toString()) ?? Icons.help.codePoint,
          fontFamily: 'MaterialIcons',
        ),
        'tipo': cat['tipo'],
        'data': cat['data'],
        'usuario_id': cat['usuario_id'],
      };
    }).toList();

    setState(() {});
  }


  void _confirmarExcluirCategoria(int index) {
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
              final categoria = dadosPorPeriodo[periodoAtual]![index];
              final db = await DatabaseHelper().database;

              // Deleta transações relacionadas
              await db.delete(
                'transacoes',
                where: 'categoria_id = ? AND data = ? AND usuario_id = ?',
                whereArgs: [categoria['id'], categoria['data'], widget.usuarioId],
              );

              // Deleta a categoria
              await db.delete(
                'categorias',
                where: 'id = ? AND usuario_id = ?',
                whereArgs: [categoria['id'], widget.usuarioId],
              );

              await carregarCategoriasDoBanco();
              Navigator.pop(context);
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
  void _abrirCadastroCategoria({int? index, String tipoInicial = 'Gasto', Color? corInicial}) {
    final isEditando = index != null;
    final categoria = isEditando ? dadosPorPeriodo[periodoAtual]![index!] : null;
    final int? idCategoriaEditando = categoria?['id'];

    String tipoSelecionado = categoria?['tipo'] ?? tipoInicial;
    String operacaoEntrada = 'Adicionar';

    final valorAtual = categoria?['valor'] ?? 0.0;

    final nomeController = TextEditingController(text: categoria?['categoria'] ?? categoria?['nome'] ?? '');
    final valorAjusteController = TextEditingController(
      text: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(0),
    );

    Color corSelecionada;

    if (categoria != null) {
      corSelecionada = categoria['cor'] is int
          ? Color(categoria['cor'])
          : categoria['cor'];
    } else {
      final usadas = dadosPorPeriodo[periodoAtual]?.map((cat) {
        final cor = cat['cor'];
        return cor is int ? cor : (cor as Color).value;
      }).toSet() ?? {};

      final primeiraDisponivel = coresDisponiveis.firstWhere(
            (cor) => !usadas.contains(cor.value),
        orElse: () => coresDisponiveis.first,
      );

      corSelecionada = primeiraDisponivel;
    }

    late Map<String, IconData> iconesUsados;
    late String iconeSelecionadoNome;

    void atualizarIconesPorTipo(String tipo) {
      iconesUsados = tipo == 'Entrada' ? iconesEntrada : iconesDisponiveis;

      final iconeAtual = categoria?['icone'] ?? Icons.category;
      final entradaPadrao = tipo == 'Entrada' ? 'Outros' : 'Outros';

      iconeSelecionadoNome = iconesUsados.entries
          .firstWhere((e) => e.value == iconeAtual,
          orElse: () => MapEntry(entradaPadrao, iconesUsados[entradaPadrao]!))
          .key;
    }

    atualizarIconesPorTipo(tipoSelecionado);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditando ? 'Editar $tipoSelecionado' : 'Nova $tipoSelecionado'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEditando)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Gasto', 'Entrada'].map((tipo) {
                      final bool selecionado = tipoSelecionado == tipo;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selecionado ? Colors.blueAccent : Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              tipoSelecionado = tipo;
                              atualizarIconesPorTipo(tipo);
                            });
                          },
                          child: Text(tipo),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        tipoSelecionado,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Valor atual: R\$ ${valorAtual.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: valorAjusteController,
                  decoration: const InputDecoration(labelText: 'Valor a ajustar'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyTextInputFormatter()],
                ),
                const SizedBox(height: 16),
                const Text('Operação:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['Adicionar', 'Remover'].map((opcao) {
                    final bool selecionado = operacaoEntrada == opcao;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selecionado ? Colors.green : Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => setStateDialog(() => operacaoEntrada = opcao),
                        child: Text(opcao),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome da categoria'),
                ),
                const SizedBox(height: 16),
                const Text('Cor:'),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Escolha a cor'),
                        content: StatefulBuilder(
                          builder: (context, setStateInterno) {
                            return Wrap(
                              spacing: 8,
                              children: coresDisponiveis.map((cor) {
                                final corJaUsada = dadosPorPeriodo[periodoAtual]?.any((cat) {
                                  final corCategoria = cat['cor'] is int
                                      ? cat['cor']
                                      : (cat['cor'] as Color).value;
                                  return corCategoria == cor.value && (!isEditando || cat['id'] != idCategoriaEditando);
                                }) ?? false;

                                final selecionada = cor == corSelecionada;

                                return GestureDetector(
                                  onTap: () {
                                    if (corJaUsada) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Essa cor já está sendo usada neste período.'),
                                        ),
                                      );
                                      return;
                                    }

                                    setStateDialog(() {
                                      corSelecionada = cor; // atualiza a cor no dialog principal
                                    });

                                    Navigator.pop(context); // agora sim, após atualizar visual
                                  },

                                  child: CircleAvatar(
                                    backgroundColor: cor.withOpacity(corJaUsada ? 0.3 : 1.0),
                                    child: selecionada
                                        ? const Icon(Icons.check, color: Colors.white)
                                        : corJaUsada
                                        ? const Icon(Icons.block, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: corSelecionada,
                    radius: 20,
                  ),
                ),



                const SizedBox(height: 16),
                const Text('Ícone:'),
                Wrap(
                  spacing: 8,
                  children: iconesUsados.entries.map((entry) {
                    final bool selecionado = entry.key == iconeSelecionadoNome;
                    return GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          iconeSelecionadoNome = entry.key;
                          nomeController.text = entry.key;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: selecionado
                            ? Colors.blueAccent.withOpacity(0.8)
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
              onPressed: () async {
                if (nomeController.text.trim().isEmpty ||
                    valorAjusteController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos corretamente.')),
                  );
                  return;
                }

                final delta = (operacaoEntrada == 'Adicionar' ? 1 : -1) *
                    (double.tryParse(valorAjusteController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0) / 100;

                final dbHelper = DatabaseHelper();
                final nomeFinal = nomeController.text.trim().capitalize();
                final dataAtual = DateFormat('yyyy-MM-dd').format(
                  DateTime(anoSelecionado, meses.indexOf(mesSelecionado) + 1, 1),
                );
                // Verifica se categoria já existe (busca id)
                int? categoriaId = categoria?['id'];

                if (isEditando && categoria != null) {
                  // Atualiza categoria existente
                  final categoriaId = categoria['id'];
                  await dbHelper.atualizarCategoria(
                    categoriaId,
                    {
                      'nome': nomeFinal,
                      'tipo': tipoSelecionado,
                      'cor': corSelecionada.value,
                      'icone': iconesUsados[iconeSelecionadoNome]!.codePoint,
                      'data': dataAtual,
                      'usuario_id': widget.usuarioId,
                    },
                  );
                } else {
                  // Cria nova categoria
                  categoriaId = await dbHelper.inserirCategoria({
                    'nome': nomeFinal,
                    'tipo': tipoSelecionado,
                    'cor': corSelecionada.value,
                    'icone': iconesUsados[iconeSelecionadoNome]!.codePoint,
                    'data': dataAtual,
                    'usuario_id': widget.usuarioId,
                  });
                }

// Transação vinculada
                if (categoriaId != null) {
                  await dbHelper.inserirTransacao({
                    'valor': delta,
                    'categoria_id': categoriaId,
                    'tipo': tipoSelecionado,
                    'data': dataAtual,
                    'usuario_id': widget.usuarioId,
                  });
                }


                await carregarCategoriasDoBanco();
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
  void _abrirDialogEditarEntradas() {
    _abrirCadastroCategoria(tipoInicial: 'Entrada');
  }
  // Gráfico de Pizza
  Widget _construirGraficoPizza() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final gastos = categorias.where((c) => c['tipo'] == 'Gasto' && (c['valor'] ?? 0) > 0).toList();


    if (gastos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nenhum gasto registrado neste período.'),
        ),
      );
    }

    final total = gastos.fold(0.0, (soma, item) => soma + (item['valor'] as double));

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: List.generate(gastos.length, (index) {
            final categoria = gastos[index];
            final valor = categoria['valor'] as double;
            final porcentagem = (valor / total) * 100;
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

// Chamadas dentro do modo Dashboard
  Widget _construirDashboard() {
    final categorias = dadosPorPeriodo[periodoAtual];

    if (categorias == null || categorias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nenhuma categoria cadastrada para este período.', textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirGraficoPizza(),
        const SizedBox(height: 30),
        const Text('Gastos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Gasto').toList(),
          onEditar: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Gasto').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _abrirCadastroCategoria(index: indexReal);
          },

          onExcluir: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Gasto').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _confirmarExcluirCategoria(indexReal);
          },

        ),
        const SizedBox(height: 16),
        const Text('Entradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Entrada').toList(),
          onEditar: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Entrada').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _abrirCadastroCategoria(index: indexReal);
          },

          onExcluir: (filteredIndex) {
            final todas = dadosPorPeriodo[periodoAtual] ?? [];
            final listaFiltrada = todas.where((c) => c['tipo'] == 'Entrada').toList();
            final item = listaFiltrada[filteredIndex];
            final indexReal = todas.indexOf(item);
            _confirmarExcluirCategoria(indexReal);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final categoriasFiltradas = categorias.where((c) => (c['valor'] ?? 0) > 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: modoSelecionado,
            dropdownColor: Colors.white,
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            onChanged: (novoModo) {
              setState(() => modoSelecionado = novoModo!);
            },
            items: modosDeVisualizacao.map((modo) {
              return DropdownMenuItem(value: modo, child: Text(modo));
            }).toList(),
          ),
        ),
        backgroundColor: const Color(0xFF006155),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategoria',
        onPressed: () {
          final usadas = dadosPorPeriodo[periodoAtual]?.map((cat) => cat['cor']).toSet() ?? {};

          final coresUsadas = dadosPorPeriodo[periodoAtual]?.map((cat) {
            final cor = cat['cor'];
            return cor is int ? cor : (cor as Color).value;
          }).toSet() ?? {};

          final corDisponivel = coresDisponiveis.firstWhere(
                (cor) => !coresUsadas.contains(cor.value),
            orElse: () => coresDisponiveis.first,
          );

          _abrirCadastroCategoria(tipoInicial: 'Gasto', corInicial: corDisponivel);
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF006155),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdowns sempre visíveis
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: mesSelecionado,
                    isExpanded: true,
                    onChanged: (novo) async {
                      setState(() {
                        mesSelecionado = novo!;
                      });

                      await carregarCategoriasDoBanco(); // Recarrega dados só desse período
                    },
                    items: meses.map((mes) => DropdownMenuItem(
                      value: mes,
                      child: Text(mes),
                    )).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<int>(
                    value: anoSelecionado,
                    isExpanded: true,
                    onChanged: (novo) async {
                      setState(() {
                        anoSelecionado = novo!;
                      });

                      await carregarCategoriasDoBanco(); // Também recarrega quando muda o ano
                    },
                    items: anos.map((ano) => DropdownMenuItem(
                      value: ano,
                      child: Text(ano.toString()),
                    )).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Se não houver dados, exibe só a mensagem
            if (categoriasFiltradas.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Nenhum gasto registrado neste período',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Resumo por Categoria',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (modoSelecionado == 'Dashboard') ...[
                      _construirDashboard()
                    ] else ...[
                      _construirGraficoDeBarras()
                    ],
                    const Divider(),
                    ListTile(
                      title: const Text('Entradas'),
                      trailing: GestureDetector(
                        onTap: _abrirDialogEditarEntradas,
                        child: Text(
                          'R\$ ${entradasFixas.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            decoration: TextDecoration.underline,
                            fontSize: 18, // Aumenta a fonte
                            fontWeight: FontWeight.bold, // Opcional para destacar
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Gastos'),
                      trailing: Text(
                        'R\$ ${totalGastos.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18, // Aumenta a fonte
                          fontWeight: FontWeight.bold, // Opcional
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Saldo'),
                      trailing: Text(
                        'R\$ ${saldo.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: saldo >= 0 ? Colors.green : Colors.red,
                          fontSize: 18, // Aumenta a fonte
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