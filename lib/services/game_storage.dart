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

  static const key = 'game_save';

  /// Partidas de versiones anteriores. Se leen una vez para convertirlas y
  /// se borran al guardar en el formato nuevo.
  static const v2Key = 'game_save_v2';
  static const legacyKey = 'step_state_v1';

  @override
  Future<GameSave> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GameSave.decode(
      prefs.getString(key) ?? prefs.getString(v2Key),
      legacySource: prefs.getString(legacyKey),
      engine: engine,
      welcomeBonus: welcomeBonus,
    );
  }

  @override
  Future<void> save(GameSave game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, game.encode());
    for (final old in [v2Key, legacyKey]) {
      if (prefs.containsKey(old)) await prefs.remove(old);
    }
  }
}
