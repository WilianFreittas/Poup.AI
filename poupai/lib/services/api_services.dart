import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000",
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 45),
      headers: {"Content-Type": "application/json"},
    ),
  );

  // ======================================================
  // 🔧 MÉTODOS GENÉRICOS (GET / PUT)
  // ======================================================

  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? query, String? token}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: query,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ GET $endpoint: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ PUT $endpoint: ${e.response?.data ?? e.message}");
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
      print("❌ Erro categorias: ${e.response?.data}");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> criarCategoria(
      String token, Map<String, dynamic> categoria) async {
    try {
      final response = await _dio.post(
        "/v1/categorias",
        data: {
          "cat_nome": categoria["cat_nome"],
          "cat_tipo": categoria["cat_tipo"],
          "cat_cor": categoria["cat_cor"],
          "cat_icone": categoria["cat_icone"],
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print("❌ Criar categoria: ${e.response?.data}");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> atualizarCategoria(
      String token, int catId, Map<String, dynamic> categoria) async {
    try {
      final response = await _dio.put(
        "/v1/categorias/$catId",
        data: {
          "cat_nome": categoria["cat_nome"],
          "cat_tipo": categoria["cat_tipo"],
          "cat_cor": categoria["cat_cor"],
          "cat_icone": categoria["cat_icone"],
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print("❌ Atualizar categoria: ${e.response?.data}");
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
      print("❌ Excluir categoria: ${e.response?.data}");
      rethrow;
    }
  }

  // ======================================================
  // 💰 TRANSAÇÕES
  // ======================================================

  Future<List<dynamic>> getTransacoes(String token, int ano, int mes) async {
    try {
      final response = await _dio.get(
        "/v1/transacoes",
        queryParameters: {"ano": ano, "mes": mes},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      print("❌ GET transações: ${e.response?.data}");
      rethrow;
    }
  }

  Future<void> criarTransacao(String token, Map<String, dynamic> t) async {
    try {
      await _dio.post(
        "/v1/transacoes",
        data: {
          "tra_tipo": t["tra_tipo"],
          "tra_valor": t["tra_valor"],
          "tra_data": t["tra_data"],
          "tra_observacao": t["tra_observacao"],
          "fk_categorias_cat_id": t["fk_categorias_cat_id"],
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Criar transação: ${e.response?.data}");
      rethrow;
    }
  }

  Future<void> atualizarTransacao(
      String token, int id, Map<String, dynamic> t) async {
    try {
      await _dio.put(
        "/v1/transacoes/$id",
        data: {
          "tra_tipo": t["tra_tipo"],
          "tra_valor": t["tra_valor"],
          "tra_data": t["tra_data"],
          "tra_observacao": t["tra_observacao"],
          "fk_categorias_cat_id": t["fk_categorias_cat_id"],
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Atualizar transação: ${e.response?.data}");
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
      print("❌ Excluir transação: ${e.response?.data}");
      rethrow;
    }
  }

  // ======================================================
// 📜 EVENTOS DAS METAS
// ======================================================
  Future<List<dynamic>> getEventosMeta(String token, int metaId) async {
    try {
      final response = await _dio.get(
        "/v1/metas/$metaId/eventos",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      print("❌ Erro ao buscar eventos da meta: ${e.response?.data}");
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
      print("❌ GET metas: ${e.response?.data}");
      rethrow;
    }
  }

  Future<void> criarMeta(String token, Map<String, dynamic> m) async {
    try {
      await _dio.post(
        "/v1/metas",
        data: {
          "met_titulo": m["met_titulo"],
          "met_valor": m["met_valor"],
          "met_depositado": m["met_depositado"] ?? 0.0,
          "met_cor": m["met_cor"] ?? "#777777",
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Criar meta: ${e.response?.data}");
      rethrow;
    }
  }

  Future<void> atualizarMeta(String token, int id, Map<String, dynamic> m) async {
    try {
      await _dio.put(
        "/v1/metas/$id",
        data: {
          "met_titulo": m["met_titulo"],
          "met_valor": m["met_valor"],
          "met_depositado": m["met_depositado"],
          "met_cor": m["met_cor"],
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      print("❌ Atualizar meta: ${e.response?.data}");
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
      print("❌ Excluir meta: ${e.response?.data}");
      rethrow;
    }
  }

  // ======================================================
  // 💰 APORTAR META
  // ======================================================
  Future<Map<String, dynamic>> aportarMeta(
      String token, int metaId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        "/v1/metas/$metaId/aportar",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      print("❌ Erro ao aportar meta: ${e.response?.data}");
      rethrow;
    }
  }

  // ======================================================
  // 💸 RETIRAR META
  // ======================================================
  Future<Map<String, dynamic>> retirarMeta(
      String token, int metaId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        "/v1/metas/$metaId/retirar",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      print("❌ Erro ao retirar meta: ${e.response?.data}");
      rethrow;
    }
  }

  // ======================================================
  // 📊 ANALYTICS
  // ======================================================

  Future<Map<String, dynamic>> getResumo(String token, int ano, int mes) async {
    try {
      final response = await _dio.get(
        "/v1/analytics/resumo",
        queryParameters: {"ano": ano, "mes": mes},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data;
    } on DioException catch (e) {
      print("❌ Resumo analytics: ${e.response?.data}");
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
      print("❌ Resumo completo: ${e.response?.data}");
      rethrow;
    }
  }

  // Download do PDF
  Future<void> exportarPdf(String token,
      {required int ano,
        required int mes,
        required BuildContext context}) async {
    try {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/v1/analytics/exportar_pdf?ano=$ano&mes=$mes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception("Erro ao gerar PDF");
      }

      final dir = await getDownloadsDirectory();
      final path = "${dir!.path}/extrato_${ano}_${mes}.pdf";

      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ PDF salvo em $path")),
      );

      await OpenFilex.open(path);
    } catch (e) {
      print("❌ PDF erro: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erro ao exportar PDF: $e")),
      );
    }
  }

  // ======================================================
  // 🤖 INTELIGÊNCIA ARTIFICIAL
  // ======================================================

  Future<String> enviarMensagemIA(String token, String mensagem,
      {int? ano, int? mes}) async {
    try {
      final Map<String, dynamic> body = {"mensagem": mensagem};

      if (ano != null) body["ano"] = ano;
      if (mes != null) body["mes"] = mes;

      final response = await _dio.post(
        "/v1/ia/chat",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data["resposta"] ?? "Sem resposta";
    } on DioException catch (e) {
      print("❌ IA erro: ${e.response?.data}");
      rethrow;
    }
  }

  // ======================================================
  // 🔐 AUTENTICAÇÃO
  // ======================================================

  Future<Map<String, dynamic>?> login(String email, String senha) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {
          "email": email,
          "password": senha,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        // ✅ CORRIGIDO: retorna tanto token quanto user_id
        return {
          "access_token": response.data["access_token"],
          "user_id": response.data["user_id"],
        };
      }

      return null;
    } on DioException catch (e) {
      print("❌ Erro login: ${e.response?.data ?? e.message}");
      return null;
    }
  }

  Future<bool> cadastrarUsuario(String email, String senha, {String? nome}) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {
          "email": email,
          "password": senha,
          "nome": nome ?? "Usuário",
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print("❌ Cadastro erro: ${e.response?.data}");
      return false;
    }
  }
}