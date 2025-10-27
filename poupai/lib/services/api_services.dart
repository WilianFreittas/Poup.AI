import 'package:dio/dio.dart';

class ApiService {
  // =============================================
  // 🔗 CONFIGURAÇÃO BÁSICA DO CLIENTE DIO
  // =============================================
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000", // se estiver testando no emulador Android
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  // ======================================================
  // 🧾 CATEGORIAS
  // ======================================================

  Future<List<dynamic>> getCategorias(String token) async {
    try {
      final response = await _dio.get(
        "/v1/categorias",
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao buscar categorias: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarCategoria(String token, Map<String, dynamic> categoria) async {
    try {
      await _dio.post(
        "/v1/categorias",
        data: categoria,
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
    } on DioException catch (e) {
      print("Erro ao criar categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarCategoria(String token, int id, Map<String, dynamic> categoria) async {
    try {
      await _dio.put(
        "/v1/categorias/$id",
        data: categoria,
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
    } on DioException catch (e) {
      print("Erro ao atualizar categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirCategoria(String token, int id) async {
    try {
      await _dio.delete(
        "/v1/categorias/$id",
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
    } on DioException catch (e) {
      print("Erro ao excluir categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 💰 TRANSAÇÕES
  // ======================================================

  Future<List<dynamic>> listarTransacoes(String token) async {
    try {
      final response = await _dio.get(
        "/v1/transacoes",
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao listar transações: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarTransacao(Map<String, dynamic> transacao) async {
    try {
      await _dio.post("/v1/transacoes", data: transacao);
    } on DioException catch (e) {
      print("Erro ao criar transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirTransacao(int id) async {
    try {
      await _dio.delete("/v1/transacoes/$id");
    } on DioException catch (e) {
      print("Erro ao excluir transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // METAS
  // ======================================================

  Future<List<dynamic>> getMetas(String token) async {
    try {
      final response = await _dio.get(
        "/v1/metas",
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao buscar metas: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarMeta(String token, Map<String, dynamic> meta) async {
    try {
      await _dio.post(
        "/v1/metas",
        data: meta,
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
    } on DioException catch (e) {
      print("Erro ao criar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarMeta(String token, int id, Map<String, dynamic> meta) async {
    try {
      await _dio.put(
        "/v1/metas/$id",
        data: meta,
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
    } on DioException catch (e) {
      print("Erro ao atualizar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirMeta(String token, int id) async {
    try {
      await _dio.delete(
        "/v1/metas/$id",
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
    } on DioException catch (e) {
      print("Erro ao excluir meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // ANALYTICS (RESUMO FINANCEIRO)
  // ======================================================

  Future<Map<String, dynamic>> getResumo(int ano, int mes, String token) async {
    try {
      final response = await _dio.get(
        "/v1/analytics/resumo",
        queryParameters: {"ano": ano, "mes": mes},
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao buscar resumo: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // INTELIGÊNCIA ARTIFICIAL
  // ======================================================

  Future<String> enviarMensagemIA(String token, String mensagem, int ano, int mes) async {
    try {
      final response = await _dio.post(
        "/v1/ia/chat",
        data: {
          "mensagem": mensagem,
          "ano": ano,
          "mes": mes,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data["resposta"];
    } on DioException catch (e) {
      print("Erro ao comunicar com a IA: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }
  // ======================================================
  // EXPORTAÇÃO / RESUMO COMPLETO
  // ======================================================
  Future<List<dynamic>> getResumoCompleto(String token) async {
    try {
      final response = await _dio.get(
        "/v1/analytics/resumo_completo", // ou "/analytics/export", conforme seu backend
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao exportar dados: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }
  // ======================================================
  // 🧾 CADASTRO DE USUÁRIO
  // ======================================================
  Future<bool> cadastrarUsuario(String email, String senha) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {
          "email": email,
          "password": senha,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Erro ao cadastrar usuário: ${response.data}");
        return false;
      }
    } on DioException catch (e) {
      print("Erro API cadastrarUsuario: ${e.response?.data ?? e.message}");
      return false;
    }
  }

}