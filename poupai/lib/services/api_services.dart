import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  // =============================================
  // 🔗 CONFIGURAÇÃO BÁSICA DO CLIENTE DIO
  // =============================================
  final String baseUrl = "http://192.168.18.7:8000";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.18.7:8000",
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ),
  );

  // ======================================================
  // MÉTODOS GENÉRICOS
  // ======================================================

  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? query, String? token}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: query,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ Erro GET $endpoint: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ Erro PUT $endpoint: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 👤 CONTA
  // ======================================================

  Future<void> alterarSenha(String token, String novaSenha) async {
    try {
      await _dio.put(
        "/auth/change_password",
        data: {"nova_senha": novaSenha},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data["detail"] ?? "Erro ao alterar senha.");
    }
  }

  Future<void> excluirConta(String token) async {
    try {
      await _dio.delete(
        "/auth/delete_account",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data["detail"] ?? "Erro ao excluir conta.");
    }
  }

  // ======================================================
  // 🧾 CATEGORIAS
  // ======================================================

  Future<List<dynamic>> getCategorias(String token) async {
    try {
      final response = await _dio.get(
        "/v1/categorias",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ Erro ao buscar categorias: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarCategoria(String token, Map<String, dynamic> categoria) async {
    try {
      await _dio.post(
        "/v1/categorias",
        data: categoria,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao criar categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarCategoria(String token, int categoriaId, Map<String, dynamic> payload) async {
    try {
      await _dio.put(
        "/v1/categorias/$categoriaId",
        data: payload,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao atualizar categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirCategoria(String token, int id) async {
    try {
      await _dio.delete(
        "/v1/categorias/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao excluir categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 💰 TRANSAÇÕES
  // ======================================================

  Future<List<dynamic>> getTransacoes(String token, int ano, int mes) async {
    final url = Uri.parse('$baseUrl/v1/transacoes?ano=$ano&mes=$mes');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Erro ao carregar transações: ${response.body}');
      throw Exception('Erro ao buscar transações (${response.statusCode})');
    }
  }

  Future<void> criarTransacao(String token, Map<String, dynamic> transacao) async {
    try {
      await _dio.post(
        "/v1/transacoes",
        data: transacao,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao criar transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarTransacao(String token, int id, Map<String, dynamic> transacao) async {
    try {
      await _dio.put(
        "/v1/transacoes/$id",
        data: transacao,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao atualizar transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirTransacao(String token, int id) async {
    try {
      await _dio.delete(
        "/v1/transacoes/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao excluir transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 🎯 METAS
  // ======================================================

  Future<List<dynamic>> getMetas(String token) async {
    try {
      final response = await _dio.get(
        "/v1/metas",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ Erro ao buscar metas: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarMeta(String token, Map<String, dynamic> meta) async {
    try {
      await _dio.post(
        "/v1/metas",
        data: meta,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao criar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarMeta(String token, int id, Map<String, dynamic> meta) async {
    try {
      await _dio.put(
        "/v1/metas/$id",
        data: meta,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao atualizar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirMeta(String token, int id) async {
    try {
      await _dio.delete(
        "/v1/metas/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao excluir meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ================================
  // 📌 NOVO — CRIA EVENTOS DE META
  // ================================

  Future<void> aportarMeta(String token, int metaId, double valor) async {
    try {
      await _dio.post(
        "/v1/metas/$metaId/aportar",
        data: {"valor": valor},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao aportar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> retirarMeta(String token, int metaId, double valor) async {
    try {
      await _dio.post(
        "/v1/metas/$metaId/retirar",
        data: {"valor": valor},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Erro ao retirar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  /// 📜 Lista todos os eventos da meta
  Future<List<Map<String, dynamic>>> getEventosMeta(String token, int metaId) async {
    try {
      final response = await _dio.get(
        "/v1/metas/$metaId/eventos",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print("❌ Erro ao buscar eventos da meta $metaId: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 📊 ANALYTICS
  // ======================================================

  Future<void> exportarPdf(String token,
      {required int ano, required int mes, required BuildContext context}) async {
    try {
      if (!await Permission.manageExternalStorage.isGranted &&
          !await Permission.storage.isGranted) {
        await Permission.manageExternalStorage.request();
        await Permission.storage.request();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/v1/analytics/exportar_pdf?ano=$ano&mes=$mes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao gerar PDF: ${response.statusCode}');
      }

      final downloadsDir = await getDownloadsDirectory();
      Directory dir = downloadsDir ?? await getApplicationDocumentsDirectory();

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '${dir.path}/extrato_${ano}_${mes}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📄 PDF salvo em ${dir.path}')),
      );

      await OpenFilex.open(file.path);
    } catch (e) {
      print('❌ Erro ao exportar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro ao exportar PDF: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> getResumo(String token, int ano, int mes) async {
    try {
      final response = await _dio.get(
        '/v1/analytics/resumo',
        queryParameters: {'ano': ano, 'mes': mes},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      print('❌ Erro ao obter resumo: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<dynamic>> getResumoCompleto(String token) async {
    try {
      final response = await _dio.get(
        "/v1/analytics/resumo_completo",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ Erro ao exportar dados: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

// IA
//======================================================

  Future<String> enviarMensagemIA(String token, String mensagem,
      {int? ano, int? mes}) async {
    try {
      // 👇 aqui estava o erro: precisava tipar como Map<String, dynamic>
      final Map<String, dynamic> data = {"mensagem": mensagem};
      if (ano != null) data["ano"] = ano;
      if (mes != null) data["mes"] = mes;

      final response = await _dio.post(
        "/v1/ia/chat",
        data: data,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (response.statusCode == 200 &&
          response.data["resposta"] != null) {
        return response.data["resposta"];
      } else {
        throw Exception("Resposta inválida da IA: ${response.data}");
      }
    } on DioException catch (e) {
      print("❌ Erro ao comunicar com IA: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 🔐 AUTENTICAÇÃO
  // ======================================================

  Future<bool> cadastrarUsuario(String email, String senha, {String? nome}) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {"email": email, "password": senha, "nome": nome ?? "Usuário"},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print("❌ Erro API cadastrarUsuario: ${e.response?.data ?? e.message}");
      return false;
    }
  }
}
