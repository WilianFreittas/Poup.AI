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

    final value = double.parse(digitsOnly) / 100;
    final formatter = NumberFormat.currency(locale: locale, symbol: symbol);
    final newText = formatter.format(value);

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

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final ApiService api = ApiService();
  final _fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');

  int touchedIndex = -1;
  late AnimationController _animationController;

  final List<String> meses = const [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  final List<int> anos = List.generate(3, (i) => 2023 + i);

  String mesSelecionado = 'Dezembro';
  int anoSelecionado = DateTime.now().year;

  String get periodoAtual => '$mesSelecionado-$anoSelecionado';

  /// Lista completa de categorias do usuário (vinda da API)
  List<Map<String, dynamic>> categoriasUsuario = [];

  /// Mapa de categorias agregadas por período
  Map<String, List<Map<String, dynamic>>> dadosPorPeriodo = {};

  String modoSelecionado = 'Dashboard';
  final List<String> modosDeVisualizacao = const [
    'Dashboard',
    'Gráfico de Barras'
  ];

  // Paleta base de cores para categorias
  final List<Color> coresDisponiveis = const [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
    Colors.teal,
    Colors.amber,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.yellow,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  final Map<String, IconData> iconesGasto = const {
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
        .fold(0.0, (total, item) => total + (item['valor'] as double));
  }

  double get totalGastos {
    final lista = dadosPorPeriodo[periodoAtual];
    if (lista == null) return 0.0;
    return lista
        .where((item) => item['tipo'] == 'Gasto')
        .fold(0.0, (total, item) => total + (item['valor'] as double));
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

  // =========================================================
  // 🔧 Helper: parse de cor (hex ou int) -> Color
  // =========================================================
  Color _parseCor(String corStr) {
    if (corStr.isEmpty) return const Color(0xFF9E9E9E);

    // Hex do tipo "#RRGGBB"
    if (corStr.startsWith('#')) {
      final hex = corStr.substring(1);
      final val = int.tryParse(hex, radix: 16) ?? 0x9E9E9E;
      return Color(0xFF000000 | val);
    }

    // Int direto
    final intVal = int.tryParse(corStr);
    if (intVal == null) return const Color(0xFF9E9E9E);
    if (intVal <= 0xFFFFFF) {
      return Color(0xFF000000 | intVal);
    }
    return Color(intVal);
  }

  // ==========================
  // 🔄 Carregar dados da API
  // ==========================
  Future<void> carregarCategoriasDoBanco() async {
    try {
      final mesNum = meses.indexOf(mesSelecionado) + 1;

      final categorias = await api.getCategorias(widget.token);
      final transacoes =
      await api.getTransacoes(widget.token, anoSelecionado, mesNum);

      // Guarda lista completa de categorias
      categoriasUsuario = List<Map<String, dynamic>>.from(
        categorias.map((c) => Map<String, dynamic>.from(c)),
      );

      final agrupado = <String, Map<String, dynamic>>{};

      // 🔢 Agrega transações por categoria+tipo
      for (final trans in transacoes) {
        final categoriaId = trans['fk_categorias_cat_id'];
        final idx =
        categoriasUsuario.indexWhere((c) => c['cat_id'] == categoriaId);

        Map<String, dynamic> cat;
        if (idx == -1) {
          cat = {
            'cat_id': categoriaId,
            'cat_nome': 'Sem Categoria',
            'cat_cor': '#9E9E9E',
            'cat_icone': 'Outros',
            'cat_tipo': trans['tra_tipo'] == 'receita' ? 'Entrada' : 'Gasto',
          };
        } else {
          cat = categoriasUsuario[idx];
        }

        final tipo = trans['tra_tipo'] == 'receita' ? 'Entrada' : 'Gasto';

        final valor = (trans['tra_valor'] is num)
            ? (trans['tra_valor'] as num).toDouble()
            : double.tryParse(trans['tra_valor'].toString()) ?? 0.0;

        final corStr = (cat['cat_cor'] ?? '#9E9E9E').toString();
        final cor = _parseCor(corStr);

        final nome = (cat['cat_nome'] ?? 'Sem Categoria').toString();
        final iconeStr = (cat['cat_icone'] ?? 'Outros').toString();

        final chave = '${nome.toLowerCase()}_$tipo';

        if (!agrupado.containsKey(chave)) {
          agrupado[chave] = {
            'cat_id': categoriaId,
            'categoria': nome,
            'valor': 0.0,
            'tipo': tipo,
            'cor': cor,
            'icone': getIconFromName(iconeStr),
            'transacoes': <Map<String, dynamic>>[],
          };
        }

        agrupado[chave]!['valor'] =
            (agrupado[chave]!['valor'] as double) + valor;

        (agrupado[chave]!['transacoes'] as List<Map<String, dynamic>>).add({
          'tra_id': trans['tra_id'],
          'fk_categorias_cat_id': categoriaId,
          'valor': valor,
          'data': trans['tra_data'],
          'tra_observacao': (trans['tra_observacao'] ?? '').toString(),
          'tipo': tipo,
          'cor': cor,
          'icone': getIconFromName(iconeStr),
        });
      }

      final lista = agrupado.values.toList()
        ..sort((a, b) => (a['categoria'] as String)
            .toLowerCase()
            .compareTo((b['categoria'] as String).toLowerCase()));

      dadosPorPeriodo[periodoAtual] = lista;

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  // =========================================================
  // 🔍 Helper para achar transação por ID no mapa agregado
  // =========================================================
  Map<String, dynamic>? _encontrarTransacaoPorId(int transacaoId) {
    final lista = dadosPorPeriodo[periodoAtual] ?? [];
    for (final cat in lista) {
      final transList =
      (cat['transacoes'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final t in transList) {
        if (t['tra_id'] == transacaoId) {
          return {
            'transacao': t,
            'categoria': cat,
          };
        }
      }
    }
    return null;
  }
  Widget _itemCategoriaSemExcluir(Map<String, dynamic> cat) {
    final icone = getIconFromName((cat['cat_icone'] ?? 'Outros').toString());
    final cor = _parseCor((cat['cat_cor'] ?? '#9E9E9E').toString());
    final nome = (cat['cat_nome'] ?? '').toString();

    return Row(
      children: [
        Icon(icone, size: 20, color: cor),
        const SizedBox(width: 8),
        Text(nome),
      ],
    );
  }
  // ===========================
  // NOVA / EDITAR TRANSAÇÃO
  // ===========================
  Future<void> _abrirNovaTransacao({Map<String, dynamic>? transacaoInicial}) async {
    String tipoSelecionado =
        transacaoInicial?['tipo']?.toString() ?? 'Gasto';

    int? categoriaSelecionadaId = transacaoInicial != null
        ? transacaoInicial['fk_categorias_cat_id'] as int
        : null;

    final valorController = TextEditingController(
      text: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(transacaoInicial?['valor'] ?? 0),
    );

    final observacaoController = TextEditingController(
      text: transacaoInicial?['tra_observacao']?.toString() ?? '',
    );
    bool isEdicao = transacaoInicial != null;

    String operacao = "Adicionar";
    final operacaoValorController = TextEditingController();

    final valorAtual = transacaoInicial != null
        ? (transacaoInicial['valor'] as double)
        : 0.0;

    DateTime dataSelecionada = transacaoInicial != null
        ? (DateTime.tryParse(transacaoInicial['data'].toString()) ??
        DateTime(anoSelecionado, meses.indexOf(mesSelecionado) + 1, 1))
        : DateTime(anoSelecionado, meses.indexOf(mesSelecionado) + 1, 1);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Filtra categorias por tipo selecionado
            final categoriasFiltradas = categoriasUsuario.where((c) {
              final tipoCat = (c['cat_tipo'] ?? '').toLowerCase();

              if (tipoSelecionado == 'Entrada') {
                return tipoCat == 'receita' || tipoCat == 'entrada';
              } else {
                return tipoCat == 'despesa' ||
                    tipoCat == 'gasto' ||
                    tipoCat == 'saída' ||
                    tipoCat == 'saida';
              }
            }).toList()
              ..sort((a, b) => (a['cat_nome'] ?? '')
                  .toString()
                  .toLowerCase()
                  .compareTo(
                (b['cat_nome'] ?? '').toString().toLowerCase(),
              ));

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                transacaoInicial == null
                    ? 'Nova Transação'
                    : 'Editar Transação',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tipo
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Tipo",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Gasto', 'Entrada'].map((tipo) {
                        final bool selecionado = tipoSelecionado == tipo;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            label: Text(tipo),
                            selected: selecionado,
                            selectedColor: const Color(0xFF006155),
                            labelStyle: TextStyle(
                              color:
                              selecionado ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) {
                              setStateDialog(() {
                                tipoSelecionado = tipo;
                                categoriaSelecionadaId = null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Categoria
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Categoria",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (categoriasFiltradas.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: categoriaSelecionadaId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text("Selecione uma categoria"),
                        selectedItemBuilder: (context) {
                          return categoriasFiltradas.map((cat) {
                            return _itemCategoriaSemExcluir(cat);
                          }).toList();
                        },
                        items: [
                          ... categoriasFiltradas.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat['cat_id'],
                              child: _itemCategoriaComExcluir(
                                cat,
                                    () {
                                  Navigator.pop(context); // 🔥 FECHA O DROPDOWN ANTES DE EXCLUIR

                                  _confirmarExcluirCategoria(
                                    cat['cat_id'],
                                    refreshDialog: () {
                                      setStateDialog(() {
                                        categoriaSelecionadaId = null; // evita value inválido
                                      });
                                    },
                                  );
                                },
                              ),
                            );
                          }),
                          const DropdownMenuItem(
                            value: -1,
                            child: Row(
                              children: [
                                Icon(Icons.add, color: Colors.blue),
                                SizedBox(width: 6),
                                Text("Criar nova categoria"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == -1) {
                            final novoId = await _abrirWizardCategoria();
                            if (novoId != null) {
                              await carregarCategoriasDoBanco();
                              setStateDialog(() {
                                categoriaSelecionadaId = novoId;
                              });
                            }
                            return;
                          }

                          setStateDialog(() {
                            categoriaSelecionadaId = value;
                          });
                        },
                      )
                    else
                      TextButton.icon(
                        onPressed: () async {
                          final novoId = await _abrirWizardCategoria();
                          if (novoId != null) {
                            await carregarCategoriasDoBanco();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                            "Nenhuma categoria. Criar primeira categoria."),
                      ),

                    const SizedBox(height: 16),

                    // Valor
                    // ===============================
// VALOR — MODO DE EDIÇÃO
// ===============================
                    if (isEdicao) ...[
                      // Valor atual fixo
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Valor atual",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                              .format(valorAtual),
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Escolher operação
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Operação",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ["Adicionar", "Retirar"].map((op) {
                          final selected = operacao == op;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ChoiceChip(
                              label: Text(op),
                              selected: selected,
                              selectedColor: const Color(0xFF006155),
                              labelStyle:
                              TextStyle(color: selected ? Colors.white : Colors.black87),
                              onSelected: (_) {
                                setStateDialog(() => operacao = op);
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Valor da operação
                      TextField(
                        controller: operacaoValorController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyTextInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: "Valor da operação",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      // ===============================
                      // NOVA TRANSAÇÃO — campo normal
                      // ===============================
                      TextField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyTextInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Valor (R\$)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Data
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataSelecionada,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() => dataSelecionada = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Data",
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(dataSelecionada),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Observação
                    TextField(
                      controller: observacaoController,
                      decoration: const InputDecoration(
                        labelText: 'Observação (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006155),
                  ),
            onPressed: () async {
            double valorFinal;

            if (isEdicao) {
            final raw = operacaoValorController.text.replaceAll(RegExp(r'[^\d]'), '');
            final operacaoValor = (double.tryParse(raw) ?? 0) / 100;

            // Se o usuário não mexeu no valor → mantém o valor atual
            if (operacaoValor == 0) {
            valorFinal = valorAtual;
            } else {
            valorFinal = operacao == "Adicionar"
            ? valorAtual + operacaoValor
                : valorAtual - operacaoValor;
            }

            // ❌ Proíbe valor final 0 ou negativo
            if (valorFinal <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text("O valor final deve ser maior que zero."),
            ),
            );
            return;
            }
            }
            else {
            // NOVA TRANSAÇÃO
            final raw = valorController.text.replaceAll(RegExp(r'[^\d]'), '');
            valorFinal = (double.tryParse(raw) ?? 0) / 100;

            if (valorFinal <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text("Informe um valor maior que zero."),
            ),
            );
            return;
            }
            }

            if (categoriaSelecionadaId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text("Selecione uma categoria."),
            ),
            );
            return;
            }

            final payload = {
            "tra_tipo": tipoSelecionado == 'Entrada' ? 'receita' : 'despesa',
            "tra_valor": valorFinal,
            "tra_data": DateFormat('yyyy-MM-dd').format(dataSelecionada),
            "fk_categorias_cat_id": categoriaSelecionadaId,
            "tra_observacao": observacaoController.text.trim(),
            };

            try {
            if (isEdicao) {
            await api.atualizarTransacao(
            widget.token,
            transacaoInicial['tra_id'],
            payload,
            );
            } else {
            await api.criarTransacao(widget.token, payload);
            }

            await carregarCategoriasDoBanco();
            if (context.mounted) Navigator.pop(context);
            } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao salvar: $e")),
            );
            }
            },

            child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _abrirEditarTransacao(int transacaoId) {
    final dados = _encontrarTransacaoPorId(transacaoId);
    if (dados == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação não encontrada.')),
      );
      return;
    }
    final transacao = dados['transacao'] as Map<String, dynamic>;
    _abrirNovaTransacao(transacaoInicial: transacao);
  }

  Widget _itemCategoriaComExcluir(
      Map<String, dynamic> cat,
      void Function() onExcluir,
      ) {
    final icone = getIconFromName((cat['cat_icone'] ?? 'Outros').toString());
    final cor = _parseCor((cat['cat_cor'] ?? '#9E9E9E').toString());
    final nome = (cat['cat_nome'] ?? '').toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icone, size: 20, color: cor),
            const SizedBox(width: 8),
            Text(nome),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onExcluir,
        )
      ],
    );
  }
  void _confirmarExcluirCategoria(
      int catId, {
        void Function()? refreshDialog,
      }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Excluir categoria'),
        content: const Text('Tem certeza que deseja excluir esta categoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await api.excluirCategoria(widget.token, catId);
                await carregarCategoriasDoBanco();

                // 🔥 Atualiza o modal, se estiver aberto
                if (refreshDialog != null) {
                  refreshDialog();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoria excluída com sucesso!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir categoria: $e')),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ==============================
  // 🧩 Wizard de Nova / Editar Categoria
  // ==============================
  Future<int?> _abrirWizardCategoria({Map<String, dynamic>? categoriaInicial}) async {
    String tipoSelecionado =
    (categoriaInicial?['cat_tipo'] ?? 'despesa').toString() == 'receita'
        ? 'Entrada'
        : 'Gasto';

    final nomeController = TextEditingController(
      text: (categoriaInicial?['cat_nome'] ?? '').toString(),
    );
    String iconeSelecionado =
    (categoriaInicial?['cat_icone'] ?? 'Outros').toString();

    Color corSelecionada;
    final corStr = (categoriaInicial?['cat_cor'] ?? '#006155').toString();
    corSelecionada = _parseCor(corStr);

    return showDialog<int?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final iconesMapa =
            tipoSelecionado == 'Entrada' ? iconesEntrada : iconesGasto;

            // Cores já usadas nesse tipo (evita repetição de cor entre categorias do mesmo tipo)
            final coresUsadas = categoriasUsuario.where((c) {
              final tipoCat = (c['cat_tipo'] ?? '').toLowerCase();
              final mesmoTipo = tipoSelecionado == 'Entrada'
                  ? (tipoCat == 'receita' || tipoCat == 'entrada')
                  : (tipoCat == 'despesa' ||
                  tipoCat == 'gasto' ||
                  tipoCat == 'saída' ||
                  tipoCat == 'saida');
              if (!mesmoTipo) return false;
              if (categoriaInicial == null) return true;
              return c['cat_id'] != categoriaInicial['cat_id'];
            }).map<int>((c) {
              final cStr = (c['cat_cor'] ?? '').toString();
              return _parseCor(cStr).value;
            }).toSet();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                categoriaInicial == null
                    ? 'Nova Categoria'
                    : 'Editar Categoria',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tipo
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tipo da categoria',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Gasto', 'Entrada'].map((tipo) {
                        final selecionado = tipoSelecionado == tipo;
                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                          child: ChoiceChip(
                            label: Text(tipo),
                            selected: selecionado,
                            selectedColor: const Color(0xFF006155),
                            labelStyle: TextStyle(
                              color:
                              selecionado ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) {
                              setStateDialog(() {
                                tipoSelecionado = tipo;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Nome
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nome da categoria',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Casa, Mercado, Salário...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ícone
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ícone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: iconesMapa.entries.map((entry) {
                        final selecionado =
                            iconeSelecionado == entry.key;
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              iconeSelecionado = entry.key;
                              if (nomeController.text.trim().isEmpty ||
                                  iconesMapa.containsKey(
                                      nomeController.text.trim())) {
                                nomeController.text = entry.key;
                              }
                            });
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: selecionado
                                ? const Color(0xFF006155)
                                : Colors.grey.shade200,
                            child: Icon(
                              entry.value,
                              color: selecionado
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Cor
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cor',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: coresDisponiveis.map((color) {
                        final selecionado = (color.value & 0xFFFFFF) ==
                            (corSelecionada.value & 0xFFFFFF);

                        final bloqueada = coresUsadas.any(
                              (c) =>
                          (c & 0xFFFFFF) ==
                              (color.value & 0xFFFFFF),
                        );

                        // Bloqueia uso de cor já usada por outro, mas permite manter a própria
                        final isDisabled = bloqueada && !selecionado;

                        return GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () {
                            setStateDialog(() {
                              corSelecionada = color;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(
                                      isDisabled ? 0.3 : 1.0),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selecionado
                                        ? Colors.black
                                        : Colors.white,
                                    width: selecionado ? 2 : 1,
                                  ),
                                ),
                              ),
                              if (isDisabled)
                                const Icon(
                                  Icons.block,
                                  size: 16,
                                  color: Colors.white,
                                ),
                            ],
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
                    backgroundColor: const Color(0xFF006155),
                  ),
                  onPressed: () async {
                    final nome = nomeController.text.trim().capitalize();
                    if (nome.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha o nome da categoria.')),
                      );
                      return;
                    }

                    final tipoCategoria = tipoSelecionado;

                    final payload = {
                      'cat_nome': nome,
                      'cat_tipo': tipoCategoria == "Entrada" ? "Entrada" : "Gasto",
                      'cat_cor': colorToHex(corSelecionada),
                      'cat_icone': iconeSelecionado,
                    };

                    try {
                      int novoId;

                      if (categoriaInicial == null) {
                        final nova = await api.criarCategoria(widget.token, payload);
                        novoId = nova['cat_id'];
                        Navigator.pop(context, novoId);   // RETORNA O ID
                      } else {
                        final id = categoriaInicial!['cat_id'];
                        await api.atualizarCategoria(widget.token, id, payload);
                        Navigator.pop(context, id);       // RETORNA O ID
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar categoria: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================
  // 🗑 Excluir transação
  // ===========================
  void _confirmarExcluirTransacao(dynamic id) {
    if (id == null) return;
    final int transacaoId =
    id is int ? id : int.tryParse(id.toString()) ?? -1;
    if (transacaoId <= 0) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Exclusão'),
        content:
        const Text('Deseja realmente excluir esta transação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);;
              try {
                await api.excluirTransacao(widget.token, transacaoId);
                await carregarCategoriasDoBanco();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('Transação excluída com sucesso!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao excluir transação. Detalhes: $e',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // 🎨 GRÁFICO DE PIZZA
  Widget _construirGraficoPizzaModerno() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final gastos = categorias
        .where((c) =>
    c['tipo'] == 'Gasto' && (c['valor'] as double) > 0)
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
        SizedBox(
          height: 280,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!
                            .touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(gastos.length, (index) {
                final categoria = gastos[index];
                final valor = categoria['valor'] as double;
                final cor = categoria['cor'] as Color;
                final icone = categoria['icone'] as IconData;
                final porcentagem =
                total > 0 ? (valor / total) * 100 : 0.0;
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
                      Shadow(color: Colors.black26, blurRadius: 2),
                    ],
                  ),
                  badgeWidget:
                  isTouched ? _buildBadge(icone, cor) : null,
                  badgePositionPercentageOffset: 1.3,
                );
              }),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
            ),
            swapAnimationDuration:
            const Duration(milliseconds: 300),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),
        const SizedBox(height: 24),
        _buildLegenda(gastos.cast<Map<String, dynamic>>(), total),
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
          final porcentagem =
          total > 0 ? (valor / total) * 100 : 0.0;

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
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                        valueColor:
                        AlwaysStoppedAnimation<Color>(cor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
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

  // 📊 GRÁFICO DE BARRAS
  Widget _construirGraficoDeBarras() {
    final categorias = dadosPorPeriodo[periodoAtual] ?? [];
    final categoriasFiltradas = categorias
        .where((c) =>
    c['tipo'] == 'Gasto' && (c['valor'] as double) > 0)
        .toList();

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
                  .reduce((a, b) => a > b ? a : b) *
                  1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: const Color(0xFF006155),
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.all(12),
                  getTooltipItem:
                      (group, groupIndex, rod, rodIndex) {
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
                      if (idx >= 0 &&
                          idx < categoriasFiltradas.length) {
                        final categoria =
                        categoriasFiltradas[idx];
                        final icone =
                        categoria['icone'] as IconData;
                        final cor =
                        categoria['cor'] as Color;

                        return Padding(
                          padding:
                          const EdgeInsets.only(top: 8),
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
                    reservedSize: 50, // um pouco maior para caber os textos
                    getTitlesWidget: (value, meta) {
                      String texto;

                      if (value < 1000) {
                        // até 999 → mostra com 2 casas decimais
                        texto = NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: '',
                          decimalDigits: 2,
                        ).format(value);
                      } else {
                        // acima de 1000 → mostra como "1k", "1.5k", etc.
                        texto = NumberFormat.compactCurrency(
                          decimalDigits: 1,
                          symbol: '',
                        ).format(value).toLowerCase();
                      }

                      return Text(
                        texto,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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
              barGroups:
              List.generate(categoriasFiltradas.length, (index) {
                final categoria = categoriasFiltradas[index];
                final valor = categoria['valor'] as double;
                final cor = categoria['cor'] as Color;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: valor,
                      width: 40,
                      borderRadius:
                      const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
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
      return _buildEmptyState(
        'Nenhuma categoria cadastrada para este período.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirGraficoPizzaModerno(),
        const SizedBox(height: 30),
        _buildSectionTitle(
            'Gastos', Icons.arrow_downward, Colors.redAccent),
        CategoriaListWidget(
          categorias:
          categorias.where((c) => c['tipo'] == 'Gasto').toList(),
          onExcluir: (transacaoId) {
            _confirmarExcluirTransacao(transacaoId);
          },
          onEditar: (transacaoId) {
            _abrirEditarTransacao(transacaoId);
          },
          fmt: _fmt,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(
            'Entradas', Icons.arrow_upward, Colors.green),
        CategoriaListWidget(
          categorias: categorias
              .where((c) => c['tipo'] == 'Entrada')
              .toList(),
          onExcluir: (transacaoId) {
            _confirmarExcluirTransacao(transacaoId);
          },
          onEditar: (transacaoId) {
            _abrirEditarTransacao(transacaoId);
          },
          fmt: _fmt,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      String title, IconData icon, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildSummaryCard(
      String title, double valor, IconData icon, Color color) {
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fmt.format(valor),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: color,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (novoModo) {
              setState(() => modoSelecionado = novoModo!);
            },
            items: modosDeVisualizacao
                .map(
                  (modo) => DropdownMenuItem(
                value: modo,
                child: Text(modo),
              ),
            )
                .toList(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarCategoriasDoBanco,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'nova_categoria') {
                _abrirWizardCategoria();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'nova_categoria',
                child: Text('Nova categoria'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addTransacao',
        onPressed: () async {
          await carregarCategoriasDoBanco(); // ← garante lista nova
          if (mounted) _abrirNovaTransacao();
        },
        backgroundColor: const Color(0xFF006155),
        icon: const Icon(Icons.add),
        label: const Text('Nova Transação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Seletor de período
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
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF006155),
                  ),
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
                          .map(
                            (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ),
                      )
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
                          .map(
                            (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.toString()),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cards de resumo
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
              saldo >= 0
                  ? const Color(0xFF006155)
                  : Colors.orange,
            ),
            const SizedBox(height: 20),

            if (modoSelecionado == 'Dashboard')
              _construirDashboard()
            else
              Column(
                children: [
                  _construirGraficoDeBarras(),
                  const SizedBox(height: 30),

                  /// 🔴 LISTA DE GASTOS
                  _buildSectionTitle('Gastos', Icons.arrow_downward, Colors.redAccent),
                  CategoriaListWidget(
                    categorias: (dadosPorPeriodo[periodoAtual] ?? [])
                        .where((c) => c['tipo'] == 'Gasto')
                        .toList(),
                    onExcluir: _confirmarExcluirTransacao,
                    onEditar: (id) => _abrirEditarTransacao(id as int),
                    fmt: _fmt,
                  ),

                  const SizedBox(height: 24),

                  /// 🟢 LISTA DE ENTRADAS
                  _buildSectionTitle('Entradas', Icons.arrow_upward, Colors.green),
                  CategoriaListWidget(
                    categorias: (dadosPorPeriodo[periodoAtual] ?? [])
                        .where((c) => c['tipo'] == 'Entrada')
                        .toList(),
                    onExcluir: _confirmarExcluirTransacao,
                    onEditar: (id) => _abrirEditarTransacao(id as int),
                    fmt: _fmt,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}