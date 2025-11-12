import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// 🔄 Converte nome de ícone (string) vindo da API em IconData
IconData getIconFromName(String nome) {
  const mapaCompleto = {
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
    'Salário': Icons.attach_money,
    'Freelancer': Icons.work,
    'Rendimentos': Icons.trending_up,
    'Reembolso': Icons.replay,
    'InvestimentosEntrada': Icons.account_balance,
  };

  for (final entry in mapaCompleto.entries) {
    if (entry.key.toLowerCase() == nome.toLowerCase()) {
      return entry.value;
    }
  }

  return Icons.help;
}

/// ========================================================
/// WIDGET: LISTA DE CATEGORIAS MODERNIZADA COM PAINEL EXPANSÍVEL
/// ========================================================
class CategoriaListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> categorias;
  final Function(dynamic transacaoId) onEditar; // ✅ tipo ajustado
  final Function(dynamic transacaoId) onExcluir; // ✅ tipo ajustado
  final NumberFormat fmt;

  const CategoriaListWidget({
    Key? key,
    required this.categorias,
    required this.onEditar,
    required this.onExcluir,
    required this.fmt,
  }) : super(key: key);

  @override
  State<CategoriaListWidget> createState() => CategoriaListWidgetState();
}

class CategoriaListWidgetState extends State<CategoriaListWidget> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.categorias.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Nenhuma categoria disponível.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.categorias.length,
      itemBuilder: (context, index) {
        final categoria = widget.categorias[index];
        final nome = categoria['categoria'] ?? categoria['nome'] ?? 'Sem nome';
        final valor = (categoria['valor'] ?? 0.0).toDouble();
        final cor = categoria['cor'] is Color
            ? categoria['cor'] as Color
            : Color(int.tryParse(categoria['cor'].toString()) ?? 0xFF9E9E9E);
        final icone = categoria['icone'] is IconData
            ? categoria['icone'] as IconData
            : getIconFromName(categoria['icone']?.toString() ?? 'Outros');

        final transacoes = (categoria['transacoes'] as List<Map<String, dynamic>>?) ?? [];
        final isExpanded = expandedIndex == index;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                // Card principal
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cor.withOpacity(0.7), cor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: cor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icone, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.fmt.format(valor),
                                  style: TextStyle(
                                      color: cor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (transacoes.isNotEmpty)
                                  Text(
                                    '${transacoes.length} transaç${transacoes.length == 1 ? 'ão' : 'ões'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(Icons.keyboard_arrow_down,
                                color: cor, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Painel expansível com transações
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        ...transacoes.map((transacao) {
                          final valorTrans =
                          (transacao['valor'] ?? 0.0).toDouble();
                          final data = transacao['data'] ?? '';
                          final observacao =
                              transacao['observacao'] ?? 'Sem descrição';
                          final transacaoId = transacao['transacao_id'];
                          final categoriaId =
                              categoria['id'] ?? categoria['categoria_id'];

                          String dataFormatada = '';
                          try {
                            final dt = DateTime.parse(data);
                            dataFormatada =
                                DateFormat('dd/MM/yyyy').format(dt);
                          } catch (e) {
                            dataFormatada = data;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                // Data
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        dataFormatada.split('/')[0],
                                        style: TextStyle(
                                          color: cor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        dataFormatada.substring(3),
                                        style: TextStyle(
                                          color: cor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Descrição e valor
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        observacao,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.fmt.format(valorTrans),
                                        style: TextStyle(
                                          color: cor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botões de ação
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 20),
                                      color: Colors.blue,
                                      onPressed: () {
                                        widget.onEditar(transacaoId);
                                      }, // ✅ Corrigido
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      color: Colors.redAccent,
                                      onPressed: () async {
                                        final confirm =
                                        await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(20),
                                            ),
                                            title: Row(
                                              children: [
                                                Icon(
                                                    Icons
                                                        .warning_amber_rounded,
                                                    color: Colors.orange[700]),
                                                const SizedBox(width: 8),
                                                const Text('Excluir Transação'),
                                              ],
                                            ),
                                            content: Text(
                                              'Deseja realmente excluir esta transação de $dataFormatada?',
                                              style:
                                              const TextStyle(fontSize: 14),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                  Colors.redAccent,
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          widget.onExcluir(transacaoId);
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}