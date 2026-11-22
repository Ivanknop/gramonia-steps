import 'package:shared_preferences/shared_preferences.dart';

import '../data/chapter1.dart';
import '../logic/chapter_engine.dart';
import '../logic/game_save.dart';

/// Dónde se guarda la partida.
abstract interface class GameStorage {
  Future<GameSave> load();
  Future<void> save(GameSave game);
}

/// Guarda la partida en el celular con SharedPreferences.
class PrefsGameStorage implements GameStorage {
  PrefsGameStorage({this.engine = const ChapterEngine(chapter1)});

  final ChapterEngine engine;

  static const key = 'game_save_v2';

  /// Partida de la versión anterior (solo pasos). Se lee una vez para
  /// convertirla y se borra al guardar en el formato nuevo.
  static const legacyKey = 'step_state_v1';

  @override
  Future<GameSave> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GameSave.decode(
      prefs.getString(key),
      legacySource: prefs.getString(legacyKey),
      engine: engine,
    );
  }

  @override
  Future<void> save(GameSave game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, game.encode());
    if (prefs.containsKey(legacyKey)) await prefs.remove(legacyKey);
  }
}
