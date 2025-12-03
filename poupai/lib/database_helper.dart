import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _versao = 2; // Aumentado para forçar o onUpgrade

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'poupai.db');
    return await openDatabase(
      path,
      version: _versao,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        email TEXT UNIQUE,
        senha TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        tipo TEXT,
        cor INTEGER,
        icone INTEGER,
        data TEXT,
        usuario_id INTEGER,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE metas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        meta REAL,
        depositado REAL,
        usuario_id INTEGER,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE mensagens_assistente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
        tipo TEXT,
        texto TEXT,
        data_hora TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mensagens_assistente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
        tipo TEXT,
        texto TEXT,
        data_hora TEXT
      )
    ''');
  }

  // ================= USUÁRIOS =================
  Future<int> inserirUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    return await db.insert('usuarios', usuario);
  }

  // ================= CATEGORIAS =================
  Future<int> inserirCategoria(Map<String, dynamic> categoria) async {
    final db = await database;
    return await db.insert('categorias', categoria);
  }

  Future<int> atualizarCategoria(int id, Map<String, dynamic> categoria) async {
    final db = await database;
    return await db.update('categorias', categoria, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarCategoria(int id) async {
    final db = await database;
    return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> obterCategoriasPorUsuario(int usuarioId) async {
    final db = await database;
    return await db.query('categorias', where: 'usuario_id = ?', whereArgs: [usuarioId]);
  }

  Future<List<Map<String, dynamic>>> obterCategoriasPorPeriodo(String dataFormatada, int usuarioId) async {
    final db = await database;
    return await db.query(
      'categorias',
      where: "data LIKE ? AND usuario_id = ?",
      whereArgs: ['$dataFormatada%', usuarioId],
    );
  }

  // ================= TRANSAÇÕES =================
  Future<int> inserirTransacao(Map<String, dynamic> transacao) async {
    final db = await database;
    return await db.insert('transacoes', transacao);
  }

  Future<List<Map<String, dynamic>>> obterTransacoesPorPeriodo(int usuarioId, String mesAno) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, c.nome AS nome_categoria, c.icone, c.cor
      FROM transacoes t
      JOIN categorias c ON t.categoria_id = c.id
      WHERE t.usuario_id = ? AND t.data LIKE ?
    ''', [usuarioId, '$mesAno%']);
  }

  // ================= METAS =================
  Future<int> inserirMeta(Map<String, dynamic> meta) async {
    final db = await database;
    return await db.insert('metas', meta);
  }

  Future<int> atualizarMeta(int id, Map<String, dynamic> meta) async {
    final db = await database;
    return await db.update('metas', meta, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarMeta(int id) async {
    final db = await database;
    return await db.delete('metas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> obterMetasPorUsuario(int usuarioId) async {
    final db = await database;
    return await db.query('metas', where: 'usuario_id = ?', whereArgs: [usuarioId]);
  }

  // ================= MENSAGENS ASSISTENTE =================
  Future<void> inserirMensagemAssistente(Map<String, dynamic> mensagem) async {
    final db = await database;
    await db.insert('mensagens_assistente', mensagem);
  }

  Future<List<Map<String, dynamic>>> listarMensagensAssistente(int usuarioId) async {
    final db = await database;
    return await db.query(
      'mensagens_assistente',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_hora ASC',
    );
  }
  Future<String?> obterNomeUsuario(int usuarioId) async {
    final db = await database;
    final resultado = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );
    if (resultado.isNotEmpty) {
      return resultado.first['nome'] as String?;
    }
    return null;
  }
  Future<double> calcularGastosDoMes(int usuarioId, String mesAno) async {
    final db = await database;
    final resultado = await db.rawQuery('''
    SELECT SUM(valor) AS total
    FROM transacoes
    WHERE usuario_id = ?
      AND LOWER(tipo) = 'gasto'
      AND data LIKE ?
  ''', [usuarioId, '$mesAno%']);

    final total = resultado.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }
}