import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_services.dart';

/// ======================================================
/// FORMATADOR DE MOEDA
/// ======================================================
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

/// ======================================================
/// TELA DE METAS (API VERSION)
/// ======================================================
class MetasPage extends StatefulWidget {
  final String usuarioId;
  final String token;

  const MetasPage({super.key, required this.usuarioId, required this.token});

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
        metas = List<Map<String, dynamic>>.from(resposta.map((m) => {
          'id': m['id'],
          'titulo_metas': m['titulo_metas'] ?? '',
          'valor_metas': (m['valor_metas'] ?? 0).toDouble(),
          'depositado_metas': (m['depositado_metas'] ?? 0).toDouble(),
          'cor': m['cor'] ?? '#777777',
        }));
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
      'titulo_metas': titulo[0].toUpperCase() + titulo.substring(1),
      'valor_metas': valorMeta,
      'depositado_metas':
      index != null ? metas[index]['depositado_metas'] : 0.0,
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
      _tituloController.text = meta['titulo_metas'];
      _valorMetaController.text =
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
              .format(meta['valor_metas']);
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
            onPressed: () async {
              try {
                await _api.excluirMeta(widget.token, metas[index]['id']);
                await _carregarMetas();
              } catch (e) {
                debugPrint("Erro ao excluir meta: $e");
              }
              if (context.mounted) Navigator.pop(context);
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
                  ? meta['depositado_metas'] + valor
                  : (meta['depositado_metas'] - valor)
                  .clamp(0.0, meta['valor_metas']);

              final dados = {
                'titulo_metas': meta['titulo_metas'],
                'valor_metas': meta['valor_metas'],
                'depositado_metas': novoValor,
                'usuario_id': widget.usuarioId,
              };

              try {
                if (adicionar) {
                  await _api.aportarMeta(widget.token, meta['id'], valor);
                } else {
                  await _api.retirarMeta(widget.token, meta['id'], valor);
                }
                await _carregarMetas();
              } catch (e) {
                debugPrint("Erro ao registrar movimentação: $e");
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _construirGraficoComparativoMetas() {
    if (metas.isEmpty) return const SizedBox.shrink();

    final maxMeta = metas
        .map((e) => (e['valor_metas'] ?? 0).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.4,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxMeta * 1.2,
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
                        metas[index]['titulo_metas'].toString(),
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
            final valor = (meta['valor_metas'] ?? 0).toDouble();
            final depositado = (meta['depositado_metas'] ?? 0).toDouble();
            final progresso =
            valor > 0 ? (depositado / valor).clamp(0.0, 1.0) : 0.0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: valor.isFinite ? valor : 0,
                  width: 40,
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: depositado.isFinite ? depositado : 0,
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
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: metas.length,
                itemBuilder: (context, index) {
                  final meta = metas[index];
                  final progresso = ((meta['depositado_metas'] ?? 0.0) /
                      (meta['valor_metas'] ?? 1))
                      .clamp(0.0, 1.0);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        expandido[index] = !expandido[index];
                      });
                    },
                    child: Card(
                      elevation: 3,
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
                                  meta['titulo_metas'],
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (String result) {
                                    if (result == 'Editar') {
                                      _abrirFormularioNovaMeta(
                                          index: index);
                                    } else if (result == 'Excluir') {
                                      _removerMeta(index);
                                    }
                                  },
                                  itemBuilder:
                                      (BuildContext context) => const <
                                      PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'Editar',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem<String>(
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
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  _corProgresso(progresso)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '${(progresso * 100).toStringAsFixed(0)}% concluído'),
                            if (expandido[index]) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Valor da Meta:'),
                                  Text(NumberFormat.simpleCurrency(
                                      locale: 'pt_BR')
                                      .format(
                                      meta['valor_metas'] ?? 0.0)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Já depositado:'),
                                  Text(NumberFormat.simpleCurrency(
                                      locale: 'pt_BR')
                                      .format(meta[
                                  'depositado_metas'] ??
                                      0.0)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () =>
                                        _mostrarDialogValor(index,
                                            adicionar: true),
                                    child: const Text('Adicionar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _mostrarDialogValor(index,
                                            adicionar: false),
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
}