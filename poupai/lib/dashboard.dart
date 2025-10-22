import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/api_services.dart';
import 'dashboard_widgets.dart';

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
  const DashboardPage({Key? key, required this.usuarioId}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : this;
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService api = ApiService();

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
    Colors.teal, Colors.amber, Colors.deepOrange, Colors.deepPurple,
    Colors.lightBlue, Colors.lightGreen, Colors.yellow, Colors.grey,
    Colors.blueGrey, Colors.black, Colors.white,
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

  // ===================== API Integration =====================
  Future<void> carregarCategoriasDoBanco() async {
    try {
      final mes = meses.indexOf(mesSelecionado) + 1;
      final resumo =
      await api.getResumo(anoSelecionado, mes, widget.usuarioId.toString());

      final categorias = resumo["categorias"] ?? [];

      dadosPorPeriodo['$mesSelecionado-$anoSelecionado'] =
          categorias.map<Map<String, dynamic>>((cat) {
            return {
              'id': cat['id'],
              'categoria': cat['nome'],
              'valor': (cat['valor'] ?? 0).toDouble(),
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
    } catch (e) {
      print("Erro ao carregar categorias: $e");
    }
  }

  Future<void> _excluirCategoria(int id) async {
    await api.excluirCategoria(id);
    await carregarCategoriasDoBanco();
  }

  Future<void> _salvarCategoria(Map<String, dynamic> categoria) async {
    if (categoria.containsKey('id')) {
      await api.atualizarCategoria(categoria['id'], categoria);
    } else {
      await api.criarCategoria(categoria);
    }
    await carregarCategoriasDoBanco();
  }

  // ===================== UI =====================

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

  Widget _construirGraficoDeBarras() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final categoriasFiltradas =
    categorias.where((c) => (c['valor'] ?? 0) > 0).toList();

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
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < categoriasFiltradas.length) {
                      final nome = categoriasFiltradas[idx]['categoria'] as String;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(nome, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _construirGraficoPizza() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final gastos =
    categorias.where((c) => c['tipo'] == 'Gasto' && (c['valor'] ?? 0) > 0).toList();

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

  Widget _construirDashboard() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    if (categorias.isEmpty) {
      return const Center(child: Text('Nenhuma categoria cadastrada.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirGraficoPizza(),
        const SizedBox(height: 30),
        const Text('Gastos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Gasto').toList(),
          onExcluir: (i) => _confirmarExcluirCategoria(categorias[i]['id']),
          onEditar: (i) {},
        ),
        const SizedBox(height: 16),
        const Text('Entradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        CategoriaListWidget(
          categorias: categorias.where((c) => c['tipo'] == 'Entrada').toList(),
          onExcluir: (i) => _confirmarExcluirCategoria(categorias[i]['id']),
          onEditar: (i) {},
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
            items: modosDeVisualizacao
                .map((modo) => DropdownMenuItem(value: modo, child: Text(modo)))
                .toList(),
          ),
        ),
        backgroundColor: const Color(0xFF006155),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategoria',
        onPressed: () {
          // Exemplo futuro: abrir modal de criação de categoria
        },
        backgroundColor: const Color(0xFF006155),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    items: meses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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
                    items: anos.map((a) => DropdownMenuItem(value: a, child: Text(a.toString()))).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  const Text('Resumo por Categoria',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (modoSelecionado == 'Dashboard')
                    _construirDashboard()
                  else
                    _construirGraficoDeBarras(),
                  const Divider(),
                  ListTile(
                    title: const Text('Entradas'),
                    trailing: Text(
                      'R\$ ${entradasFixas.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text('Gastos'),
                    trailing: Text(
                      'R\$ ${totalGastos.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text('Saldo'),
                    trailing: Text(
                      'R\$ ${saldo.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: saldo >= 0 ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
