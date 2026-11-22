import 'package:shared_preferences/shared_preferences.dart';

import '../logic/step_state.dart';

/// Dónde se guarda el estado de los pasos.
abstract interface class StepStorage {
  Future<StepState> load();
  Future<void> save(StepState state);
}

/// Guarda el estado en el celular con SharedPreferences.
class PrefsStepStorage implements StepStorage {
  static const _key = 'step_state_v1';

  @override
  Future<StepState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StepState.decode(prefs.getString(_key));
  }

  @override
  Future<void> save(StepState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.encode());
  }
}
