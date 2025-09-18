import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'perfil_page.dart';
import 'configuracoes_app_page.dart';
import 'configuracoes_conta_page.dart';
import 'database_helper.dart';


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


class MetasPage extends StatefulWidget {

  final int usuarioId;

  MetasPage({required this.usuarioId});

  @override
  _MetasPageState createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {

  List<Map<String, dynamic>> metas = [];
  List<bool> expandido = [];
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorMetaController = TextEditingController();

  double _getDoubleFromFormatted(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''))! / 100;
  }

  Color _corProgresso(double progresso) {
    if (progresso <= 0.25) return Colors.red;
    if (progresso <= 0.50) return Colors.orange;
    if (progresso <= 0.75) return Colors.yellow.shade700;
    return Colors.green;
  }

  void _abrirFormularioNovaMeta({int? index}) {
    if (index != null) {
      final meta = metas[index];
      _tituloController.text = meta['titulo'];
      _valorMetaController.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(meta['meta']);
    } else {
      _tituloController.clear();
      _valorMetaController.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(0);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? 'Nova Meta' : 'Editar Meta'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título da Meta'),
              ),
              TextField(
                controller: _valorMetaController,
                decoration: const InputDecoration(labelText: 'Valor da Meta'),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyTextInputFormatter()],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () async {
              final titulo = _tituloController.text.trim();
              final valorMeta = _getDoubleFromFormatted(_valorMetaController.text);

              if (titulo.isNotEmpty && valorMeta > 0) {
                final tituloCapitalizado = titulo[0].toUpperCase() + titulo.substring(1);
                final dbHelper = DatabaseHelper();

                if (index != null) {
                  final metaExistente = metas[index];
                  await dbHelper.atualizarMeta(metaExistente['id'], {
                    'titulo': tituloCapitalizado,
                    'meta': valorMeta,
                    'depositado': metaExistente['depositado'],
                    'usuario_id': widget.usuarioId,
                  });
                } else {
                  await dbHelper.inserirMeta({
                    'titulo': tituloCapitalizado,
                    'meta': valorMeta,
                    'depositado': 0.0,
                    'usuario_id': widget.usuarioId,
                  });
                }

                await _carregarMetasDoBanco();
                Navigator.pop(context);
              }

            },
          ),
        ],
      ),
    );
  }

  void _removerMeta(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir esta meta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() async {
                final dbHelper = DatabaseHelper();
                await dbHelper.deletarMeta(metas[index]['id']);
                await _carregarMetasDoBanco();
                Navigator.pop(context);
              });
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogValor(int index, {required bool adicionar}) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(adicionar ? 'Adicionar Valor' : 'Retirar Valor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Valor'),
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyTextInputFormatter()],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () async {
              final valor = _getDoubleFromFormatted(controller.text);

              final meta = metas[index];
              final novoValor = adicionar
                  ? meta['depositado'] + valor
                  : (meta['depositado'] - valor).clamp(0.0, meta['meta']);

              final dbHelper = DatabaseHelper();
              await dbHelper.atualizarMeta(meta['id'], {
                'titulo': meta['titulo'],
                'meta': meta['meta'],
                'depositado': novoValor,
                'usuario_id': widget.usuarioId,
              });

              await _carregarMetasDoBanco();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarMetasDoBanco();
  }

  Future<void> _carregarMetasDoBanco() async {
    final dbHelper = DatabaseHelper();
    final resultado = await dbHelper.obterMetasPorUsuario(widget.usuarioId); // ajuste aqui conforme o ID
    setState(() {
      metas = resultado;
      expandido = List.filled(metas.length, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('Minhas Metas'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioNovaMeta(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF006155),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: metas.isEmpty
            ? const Center(child: Text('Nenhuma meta adicionada ainda.'))
            : Column(
          children: [
            _construirGraficoComparativoMetas(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: metas.length,
                itemBuilder: (context, index) {
                  final meta = metas[index];
                  final progresso = ((meta['depositado'] ?? 0.0) / meta['meta']).clamp(0.0, 1.0);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        expandido[index] = !expandido[index];
                      });
                    },
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  meta['titulo'],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (String result) {
                                    if (result == 'Editar') {
                                      _abrirFormularioNovaMeta(index: index);
                                    } else if (result == 'Excluir') {
                                      _removerMeta(index);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'Editar',
                                      child: Text('Editar'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Excluir',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progresso,
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_corProgresso(progresso)),
                            ),
                            const SizedBox(height: 6),
                            Text('${(progresso * 100).toStringAsFixed(0)}% concluído'),
                            if (expandido[index]) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Valor da Meta:'),
                                  Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(meta['meta'])),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Já depositado:'),
                                  Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(meta['depositado'])),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _mostrarDialogValor(index, adicionar: true),
                                    child: const Text('Adicionar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _mostrarDialogValor(index, adicionar: false),
                                    child: const Text('Retirar'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGraficoComparativoMetas() {
    if (metas.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 1.4,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: metas.map((e) => e['meta'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < metas.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        metas[index]['titulo'].toString(),
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
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
          barGroups: List.generate(metas.length, (index) {
            final meta = metas[index];
            final valor = meta['meta'] as double;
            final depositado = meta['depositado'] as double;
            final progresso = (depositado / valor).clamp(0.0, 1.0);

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: valor,
                  width: 40,
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: depositado,
                  width: 40,
                  color: _corProgresso(progresso),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),

        ),
      ),
    );
  }


}