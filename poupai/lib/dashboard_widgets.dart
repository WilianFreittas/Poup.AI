import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'perfil_page.dart';
import 'configuracoes_app_page.dart';
import 'configuracoes_conta_page.dart';


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
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 3,
          sections: categorias.map((item) {
            final valor = item['valor'] ?? 0.0;
            return PieChartSectionData(
              color: item['cor'],
              value: valor,
              title: '${((valor / totalGastos) * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(color: Colors.white),
              radius: 60,
            );
          }).toList(),
        ),
      ),
    );
  }
}

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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final categoria = categorias[index];
        final nome = categoria['categoria'] ?? categoria['nome'];
        final valor = categoria['valor'] ?? 0.0;
        final cor = categoria['cor'] as Color;
        final icone = categoria['icone'] as IconData;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cor,
              child: Icon(icone, color: Colors.white),
            ),
            title: Text(nome),
            subtitle: Text('R\$ ${valor.toStringAsFixed(2)}'),
            onTap: () => onEditar(index), // <- ESSENCIAL PARA FUNCIONAR!
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onExcluir(index),
            ),
          ),
        );
      },
    );
  }
}
