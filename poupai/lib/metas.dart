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
  /// TELA DE METAS
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

    // ===============================
    // SUPPORT
    // ===============================

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
            'id': m['met_id'],
            'met_titulo': m['met_titulo'] ?? '',
            'met_valor': (m['met_valor'] ?? 0).toDouble(),
            'met_depositado': (m['met_depositado'] ?? 0).toDouble(),
            'cor': m['met_cor'] ?? '#777777',
            'eventos': <Map<String, dynamic>>[],
          }));

          expandido = List<bool>.filled(metas.length, false);
          _carregando = false;
        });
      } catch (e) {
        debugPrint("Erro ao carregar metas: $e");
        setState(() => _carregando = false);
      }
    }

    Future<void> _carregarEventos(int index) async {
      try {
        final id = metas[index]['id'];
        final eventos = await _api.getEventosMeta(widget.token, id);

        setState(() {
          metas[index]['eventos'] = List<Map<String, dynamic>>.from(eventos);
        });
      } catch (e) {
        debugPrint("Erro ao carregar eventos da meta: $e");
      }
    }

    // ===============================
    // CRUD
    // ===============================

    Future<void> _salvarMeta({int? index}) async {
      final titulo = _tituloController.text.trim();
      final valorMeta = _getDoubleFromFormatted(_valorMetaController.text);
      if (titulo.isEmpty || valorMeta <= 0) return;

      final dados = {
        'met_titulo': titulo[0].toUpperCase() + titulo.substring(1),
        'met_valor': valorMeta,
        'met_depositado': index != null ? metas[index]['met_depositado'] : 0.0,
        'met_cor': index != null ? metas[index]['cor'] : "#777777",
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
        _tituloController.text = meta['met_titulo'];
        _valorMetaController.text =
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                .format(meta['met_valor']);
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
                  decoration:
                  const InputDecoration(labelText: 'Título da Meta'),
                ),
                TextField(
                  controller: _valorMetaController,
                  decoration:
                  const InputDecoration(labelText: 'Valor da Meta'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyTextInputFormatter()],
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
                await _salvarMeta(index: index);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    }

    void _removerMeta(int index) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excluir Meta'),
          content: const Text('Tem certeza que deseja excluir esta meta?'),
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

    // ===============================
    // Movimentações
    // ===============================

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
                if (valor <= 0) return;

                final meta = metas[index];
                final double atual = meta['met_depositado'] ?? 0.0;
                final double total = meta['met_valor'] ?? 0.0;

                // 🚫 REGRA: NÃO PERMITIR ULTRAPASSAR A META
                if (adicionar && (atual + valor) > total) {
                  final falta = total - atual;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'O valor ultrapassa o total da meta.\n'
                            'Falta apenas R\$ ${falta.toStringAsFixed(2)} para completar.',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                final metaId = meta['id'];

                try {
                  if (adicionar) {
                    await _api.aportarMeta(widget.token, metaId, {'valor': valor});
                  } else {
                    await _api.retirarMeta(widget.token, metaId, {'valor': valor});
                  }

                  await _carregarMetas();
                  await _carregarEventos(index);

                } catch (e) {
                  debugPrint("Erro ao movimentar meta: $e");
                }

                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }

    // ===============================
    // GRÁFICO COMPARATIVO
    // ===============================

    Widget _construirGraficoComparativoMetas() {
      if (metas.isEmpty) return const SizedBox.shrink();

      final maxMeta = metas
          .map((e) => (e['met_valor'] ?? 0).toDouble())
          .fold<double>(0, (a, b) => a > b ? a : b);

      return SizedBox(
        height: 280,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(metas.length, (index) {
              final meta = metas[index];
              final valor = (meta['met_valor'] ?? 0).toDouble();
              final depositado = (meta['met_depositado'] ?? 0).toDouble();
              final progresso = valor > 0 ? (depositado / valor).clamp(0.0, 1.0) : 0.0;

              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    /// GRÁFICO
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          maxY: maxMeta * 1.25,
                          groupsSpace: 20,

                          /// ---- BARRAS ----
                          barGroups: [
                            BarChartGroupData(
                              x: index,
                              barsSpace: 12,
                              barRods: [
                                /// Fundo (valor total)
                                BarChartRodData(
                                  toY: valor,
                                  width: 20,
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),

                                /// Depositado
                                BarChartRodData(
                                  toY: depositado,
                                  width: 20,
                                  color: _corProgresso(progresso),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                          ],

                          /// ---- SEM BORDAS / EIXOS ----
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(),
                            rightTitles: AxisTitles(),
                            topTitles: AxisTitles(),
                            bottomTitles: AxisTitles(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// TÍTULO DA META
                    Text(
                      meta['met_titulo'],
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// PERCENTUAL
                    Text(
                      "${(progresso * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 15,
                        color: _corProgresso(progresso),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              );
            }),
          ),
        ),
      );
    }

    // ===============================
    // CARD DA META
    // ===============================

    Widget _buildMetaCard(int index) {
      final meta = metas[index];

      final progresso = ((meta['met_depositado'] ?? 0.0) /
          (meta['met_valor'] ?? 1))
          .clamp(0.0, 1.0);

      return GestureDetector(
        onTap: () async {
          setState(() => expandido[index] = !expandido[index]);
          if (expandido[index]) {
            await _carregarEventos(index);
          }
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
                /// Cabeçalho
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meta['met_titulo'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'Editar') {
                          _abrirFormularioNovaMeta(index: index);
                        } else if (value == 'Excluir') {
                          _removerMeta(index);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'Editar',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'Excluir',
                          child: Text('Excluir'),
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 8),

                /// Depositado + Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Depositado: R\$ ${meta['met_depositado'].toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    Text(
                      "Total: R\$ ${meta['met_valor'].toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Barra de progresso
                LinearProgressIndicator(
                  value: progresso,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                  AlwaysStoppedAnimation<Color>(_corProgresso(progresso)),
                ),
                const SizedBox(height: 6),
                Text("${(progresso * 100).toStringAsFixed(0)}% concluído"),

                /// Movimentações
                if (expandido[index]) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Movimentações:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if ((meta['eventos'] ?? []).isEmpty)
                    const Text("Nenhuma movimentação ainda."),

                  ...List.generate((meta['eventos'] as List).length, (eIndex) {
                    final e = meta['eventos'][eIndex] as Map<String, dynamic>;

                    final double delta = (e['evm_delta_valor'] ?? 0).toDouble();

                    // Correção -> tenta vários nomes de campos de data
                    final rawData = e['criado_em'] ?? e['evm_criado_em'] ?? e['created_at'];

                    String dataTexto;
                    if (rawData != null) {
                      try {
                        dataTexto = DateFormat("dd/MM/yyyy HH:mm")
                            .format(DateTime.parse(rawData.toString()));
                      } catch (_) {
                        dataTexto = "-";
                      }
                    } else {
                      dataTexto = "-";
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (e['evm_tipo'] == "aporte")
                                ? "Aporte"
                                : (e['evm_tipo'] == "retirada")
                                ? "Retirada"
                                : "Movimentação",
                            style: TextStyle(
                              color: delta > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${delta > 0 ? '+' : ''} R\$ ${delta.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: delta > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(dataTexto),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _mostrarDialogValor(index, adicionar: true),
                        child: const Text("Adicionar"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _mostrarDialogValor(index, adicionar: false),
                        child: const Text("Retirar"),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    Widget _buildBlocoGrafico() {
      return Card(
        elevation: 3,
        color: Colors.white,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Progresso das Metas",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _construirGraficoComparativoMetas(),
            ],
          ),
        ),
      );
    }

    // ===============================
    // BUILD
    // ===============================

    @override
    Widget build(BuildContext context) {
      if (_carregando) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),

        floatingActionButton: FloatingActionButton(
          onPressed: () => _abrirFormularioNovaMeta(),
          backgroundColor: const Color(0xFF006155),
          child: const Icon(Icons.add),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: metas.isEmpty
              ? const Center(child: Text("Nenhuma meta adicionada ainda."))
              : ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _buildBlocoGrafico(),
              const SizedBox(height: 20),
              ...List.generate(metas.length, _buildMetaCard),
            ],
          ),
        ),
      );
    }
  }