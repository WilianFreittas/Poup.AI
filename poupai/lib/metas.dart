import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_services.dart';  // << usa o ApiService

/// =========================================================
/// FORMATADOR DE MOEDA
/// =========================================================
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

/// =========================================================
/// TELA DE METAS (INTEGRADA À API)
/// =========================================================
class MetasPage extends StatefulWidget {
  final String usuarioId;
  final String token;

  const MetasPage({super.key, required this.usuarioId, required this.token,});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final ApiService _api = ApiService();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorMetaController = TextEditingController();

  List<Map<String, dynamic>> metas = [];
  List<bool> expandido = [];

  bool _carregando = true;

  double _getDoubleFromFormatted(String value) {
    final clean = value.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return 0.0;
    return double.parse(clean) / 100;
  }

  Color _corProgresso(double progresso) {
    if (progresso <= 0.25) return Colors.red;
    if (progresso <= 0.50) return Colors.orange;
    if (progresso <= 0.75) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  Future<void> _carregarMetas() async {
    try {
      final resposta = await _api.getMetas(widget.token);
      setState(() {
        metas = List<Map<String, dynamic>>.from(resposta);
        expandido = List.filled(metas.length, false);
        _carregando = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar metas: $e");
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarMeta({int? index}) async {
    final titulo = _tituloController.text.trim();
    final valorMeta = _getDoubleFromFormatted(_valorMetaController.text);
    if (titulo.isEmpty || valorMeta <= 0) return;

    final dados = {
      'titulo': titulo[0].toUpperCase() + titulo.substring(1),
      'meta': valorMeta,
      'depositado': index != null ? metas[index]['depositado'] : 0.0,
      'usuario_id': widget.usuarioId,
    };

    try {
      if (index != null) {
        await _api.atualizarMeta(widget.token, metas[index]['id'], dados);
      } else {
        await _api.criarMeta(widget.token, dados);
      }
      await _carregarMetas();
    } catch (e) {
      debugPrint("Erro ao salvar meta: $e");
    }
  }

  void _abrirFormularioNovaMeta({int? index}) {
    if (index != null) {
      final meta = metas[index];
      _tituloController.text = meta['titulo'];
      _valorMetaController.text =
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
              .format(meta['meta']);
    } else {
      _tituloController.clear();
      _valorMetaController.text =
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(0);
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
              await _salvarMeta(index: index);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _removerMeta(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir meta'),
        content: const Text('Tem certeza que deseja excluir esta meta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.excluirMeta(widget.token, id);
      await _carregarMetas();
    } catch (e) {
      debugPrint("Erro ao excluir meta: $e");
    }
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () async {
              final valor = _getDoubleFromFormatted(controller.text);
              final meta = metas[index];

              final novoValor = adicionar
                  ? meta['depositado'] + valor
                  : (meta['depositado'] - valor).clamp(0.0, meta['meta']);

              await _api.atualizarMeta(
                widget.token,
                meta['id'],
                {
                  'titulo': meta['titulo'],
                  'meta': meta['meta'],
                  'depositado': novoValor,
                  'usuario_id': widget.usuarioId,
                },
              );

              await _carregarMetas();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _construirGraficoComparativoMetas() {
    if (metas.isEmpty) return const SizedBox.shrink();

    final maxMeta =
    metas.map((e) => e['meta'] as double).reduce((a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.4,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxMeta * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles:
            AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
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
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(metas.length, (index) {
            final meta = metas[index];
            final valor = meta['meta'] as double;
            final depositado = meta['depositado'] as double;
            final progresso = (depositado / valor).clamp(0.0, 1.0);

            return BarChartGroupData(x: index, barRods: [
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
            ]);
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('Minhas Metas'),
        backgroundColor: const Color(0xFF006155),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioNovaMeta(),
        backgroundColor: const Color(0xFF006155),
        child: const Icon(Icons.add),
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
                itemCount: metas.length,
                itemBuilder: (context, index) {
                  final meta = metas[index];
                  final progresso =
                  ((meta['depositado'] ?? 0.0) / meta['meta'])
                      .clamp(0.0, 1.0);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                meta['titulo'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'Editar') {
                                    _abrirFormularioNovaMeta(index: index);
                                  } else if (value == 'Excluir') {
                                    _removerMeta(meta['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'Editar',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _corProgresso(progresso)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                              '${(progresso * 100).toStringAsFixed(0)}% concluído'),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Meta total:'),
                              Text(NumberFormat.simpleCurrency(
                                  locale: 'pt_BR')
                                  .format(meta['meta'])),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Depositado:'),
                              Text(NumberFormat.simpleCurrency(
                                  locale: 'pt_BR')
                                  .format(meta['depositado'])),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => _mostrarDialogValor(index,
                                    adicionar: true),
                                child: const Text('Adicionar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _mostrarDialogValor(index,
                                    adicionar: false),
                                child: const Text('Retirar'),
                              ),
                            ],
                          ),
                        ],
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
}
