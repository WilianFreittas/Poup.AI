import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ========================================================
/// Função utilitária: converte nome de ícone em IconData
/// ========================================================
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

  return Icons.help_outline;
}

/// ========================================================
/// WIDGET PRINCIPAL: Lista de categorias com expansão
/// ========================================================
class CategoriaListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> categorias;
  final Function(dynamic transacaoId) onEditar;
  final Function(dynamic transacaoId) onExcluir;
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              "Nenhuma categoria encontrada.",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.categorias.length,
      itemBuilder: (context, index) {
        final categoria = widget.categorias[index];
        final nome = categoria['categoria'] ?? "Sem nome";
        final valor = (categoria['valor'] ?? 0.0).toDouble();
        final cor = categoria['cor'] as Color;
        final icone = categoria['icone'] as IconData;
        final transacoes =
            (categoria['transacoes'] as List<Map<String, dynamic>>?) ?? [];

        final isExpanded = expandedIndex == index;

        return Container(
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
              // ================= CABEÇALHO DO CARD =================
              InkWell(
                onTap: () {
                  setState(() => expandedIndex = isExpanded ? null : index);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icone, color: cor, size: 30),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.fmt.format(valor),
                              style: TextStyle(
                                color: cor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (transacoes.isNotEmpty)
                              Text(
                                "${transacoes.length} transações",
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
                        child: Icon(Icons.keyboard_arrow_down, color: cor),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= ÁREA EXPANDIDA =================
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final transacao in transacoes)
                        _buildTransacaoItem(
                          transacao,
                          cor,
                          widget.fmt,
                          onEditar: widget.onEditar,
                          onExcluir: widget.onExcluir,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ========================================================
  /// ITEM INDIVIDUAL DA TRANSAÇÃO (resumo da transação)
  /// ========================================================
  Widget _buildTransacaoItem(
      Map<String, dynamic> transacao,
      Color cor,
      NumberFormat fmt, {
        required Function(dynamic id) onEditar,
        required Function(dynamic id) onExcluir,
      }) {
    final valor = (transacao['valor'] ?? 0.0).toDouble();
    final data = transacao['data'] ?? "";
    final observacao = (transacao['tra_observacao'] ?? "Sem descrição").toString().trim();
    final id = transacao['tra_id'];

    String dataFormatada = data;
    try {
      dataFormatada = DateFormat("dd/MM/yyyy").format(DateTime.parse(data));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Data
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  dataFormatada.split('/')[0],
                  style: TextStyle(
                    color: cor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dataFormatada.substring(3),
                  style: TextStyle(color: cor, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Texto (observação + valor)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 Observação / descrição da transação
                Text(
                  observacao,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  fmt.format(valor),
                  style: TextStyle(
                    color: cor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Ações
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Colors.blue,
            onPressed: () => onEditar(id),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => onExcluir(id),
          ),
        ],
      ),
    );
  }
}