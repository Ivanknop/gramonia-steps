import 'package:sqflite/sqflite.dart';

/// Dónde se guardan los pasos de cada día.
abstract interface class StepHistoryStorage {
  /// Todos los días guardados (fecha aaaa-mm-dd → pasos).
  Future<Map<String, int>> load();

  /// Guarda (o reemplaza) los pasos de varios días.
  Future<void> save(Map<String, int> days);
}

/// Base de datos local (SQLite) en el celular.
class SqliteStepHistoryStorage implements StepHistoryStorage {
  SqliteStepHistoryStorage({this.fileName = 'pasos.db'});

  /// Se guarda en la carpeta de bases de datos de la app.
  final String fileName;

  static const _table = 'pasos_por_dia';

  Database? _db;

  Future<Database> _open() async => _db ??= await openDatabase(
    fileName,
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE $_table (fecha TEXT PRIMARY KEY, pasos INTEGER NOT NULL)',
    ),
  );

  @override
  Future<Map<String, int>> load() async {
    final rows = await (await _open()).query(_table);
    return {for (final r in rows) r['fecha'] as String: r['pasos'] as int};
  }

  @override
  Future<void> save(Map<String, int> days) async {
    if (days.isEmpty) return;
    final batch = (await _open()).batch();
    for (final MapEntry(:key, :value) in days.entries) {
      batch.insert(_table, {
        'fecha': key,
        'pasos': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}

/// Guarda en memoria (se pierde al cerrar la app). Para los tests.
class MemoryStepHistoryStorage implements StepHistoryStorage {
  MemoryStepHistoryStorage([Map<String, int> days = const {}])
    : days = {...days};

  final Map<String, int> days;
  int saveCount = 0;

  @override
  Future<Map<String, int>> load() async => {...days};

  @override
  Future<void> save(Map<String, int> days) async {
    this.days.addAll(days);
    saveCount++;
  }
}
