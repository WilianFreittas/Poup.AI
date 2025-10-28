import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// =========================================================
/// WIDGET: GRÁFICO DE PIZZA
/// =========================================================
class PieChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final double totalGastos;

  const PieChartWidget({
    super.key,
    required this.categorias,
    required this.totalGastos,
  });

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty || totalGastos <= 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum gasto registrado neste período.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 3,
          sections: categorias.map((item) {
            final valor = (item['valor'] ?? 0.0).toDouble();
            final cor = item['cor'] is Color
                ? item['cor'] as Color
                : Color(int.tryParse(item['cor'].toString()) ?? 0xFF9E9E9E);
            final porcentagem = totalGastos > 0 ? (valor / totalGastos) * 100 : 0.0;

            return PieChartSectionData(
              color: cor,
              value: valor,
              title: '${porcentagem.toStringAsFixed(1)}%',
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
              radius: 60,
            );
          }).toList(),
        ),
      ),
    );
  }
}

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
    // Ícones de entrada
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

  return Icons.help; // fallback se não encontrar
}


/// =========================================================
/// WIDGET: LISTA DE CATEGORIAS (GASTOS / ENTRADAS)
/// =========================================================
class CategoriaListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final Function(int) onEditar;
  final Function(int) onExcluir;

  const CategoriaListWidget({
    Key? key,
    required this.categorias,
    required this.onEditar,
    required this.onExcluir,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'Nenhuma categoria disponível.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final categoria = categorias[index];
        final nome = categoria['categoria'] ?? categoria['nome'] ?? 'Sem nome';
        final valor = (categoria['valor'] ?? 0.0).toDouble();
        final cor = categoria['cor'] is Color
            ? categoria['cor'] as Color
            : Color(int.tryParse(categoria['cor'].toString()) ?? 0xFF9E9E9E);
        final icone = categoria['icone'] is IconData
            ? categoria['icone'] as IconData
            : getIconFromName(categoria['icone']?.toString() ?? 'Outros');

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cor,
              child: Icon(icone, color: Colors.white),
            ),
            title: Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'R\$ ${valor.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.black54),
            ),
            onTap: () => onEditar(index),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Excluir Categoria'),
                    content: Text(
                      'Deseja realmente excluir "$nome"?',
                      style: const TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Excluir',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  onExcluir(index);
                }
              },
            ),
          ),
        );
      },
    );
  }
}