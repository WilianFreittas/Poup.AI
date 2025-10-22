import 'package:dio/dio.dart';

class ApiService {
  // =============================================
  // 🔗 CONFIGURAÇÃO BÁSICA DO CLIENTE DIO
  // =============================================
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000/v1", // se estiver testando no emulador Android
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

  Future<List<dynamic>> getCategorias(String usuarioId) async {
    try {
      final response = await _dio.get(
        "/categorias",
        options: Options(headers: {"usuario_id": usuarioId}),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao buscar categorias: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarCategoria(Map<String, dynamic> categoria) async {
    try {
      await _dio.post("/categorias", data: categoria);
    } on DioException catch (e) {
      print("Erro ao criar categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarCategoria(int id, Map<String, dynamic> categoria) async {
    try {
      await _dio.put("/categorias/$id", data: categoria);
    } on DioException catch (e) {
      print("Erro ao atualizar categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirCategoria(int id) async {
    try {
      await _dio.delete("/categorias/$id");
    } on DioException catch (e) {
      print("Erro ao excluir categoria: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // 💰 TRANSAÇÕES
  // ======================================================

  Future<List<dynamic>> listarTransacoes(String usuarioId) async {
    try {
      final response = await _dio.get(
        "/transacoes",
        options: Options(headers: {"usuario_id": usuarioId}),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao listar transações: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarTransacao(Map<String, dynamic> transacao) async {
    try {
      await _dio.post("/transacoes", data: transacao);
    } on DioException catch (e) {
      print("Erro ao criar transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirTransacao(int id) async {
    try {
      await _dio.delete("/transacoes/$id");
    } on DioException catch (e) {
      print("Erro ao excluir transação: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // METAS
  // ======================================================

  Future<List<dynamic>> getMetas(String usuarioId) async {
    try {
      final response = await _dio.get(
        "/metas",
        options: Options(headers: {"usuario_id": usuarioId}),
      );
      return response.data;
    } on DioException catch (e) {
      print("Erro ao buscar metas: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> criarMeta(Map<String, dynamic> meta) async {
    try {
      await _dio.post("/metas", data: meta);
    } on DioException catch (e) {
      print("Erro ao criar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> atualizarMeta(int id, Map<String, dynamic> meta) async {
    try {
      await _dio.put("/metas/$id", data: meta);
    } on DioException catch (e) {
      print("Erro ao atualizar meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<void> excluirMeta(int id) async {
    try {
      await _dio.delete("/metas/$id");
    } on DioException catch (e) {
      print("Erro ao excluir meta: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  // ======================================================
  // ANALYTICS (RESUMO FINANCEIRO)
  // ======================================================

  Future<Map<String, dynamic>> getResumo(int ano, int mes, String usuarioId) async {
    try {
      final response = await _dio.get(
        "/analytics/resumo",
        queryParameters: {"ano": ano, "mes": mes},
        options: Options(headers: {"usuario_id": usuarioId}),
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

  Future<String> enviarMensagemIA(String usuarioId, String mensagem) async {
    try {
      final response = await _dio.post(
        "/ia/chat",
        data: {"mensagem": mensagem},
        options: Options(headers: {"usuario_id": usuarioId}),
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
  Future<List<dynamic>> getResumoCompleto(String usuarioId) async {
    try {
      final response = await _dio.get(
        "/analytics/resumo_completo", // ou "/analytics/export", conforme seu backend
        options: Options(headers: {"usuario_id": usuarioId}),
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
  Future<bool> cadastrarUsuario(String nome, String email, String senha) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {
          "nome": nome,
          "email": email,
          "senha": senha,
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
