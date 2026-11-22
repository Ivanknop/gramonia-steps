import 'dart:convert';

/// Estado de los pasos, guardado en el celular.
class StepState {
  const StepState({
    required this.lastReading,
    required this.totalSteps,
    required this.todaySteps,
    required this.todayDate,
  });

  /// Estado de una instalación nueva.
  const StepState.initial()
    : lastReading = null,
      totalSteps = 0,
      todaySteps = 0,
      todayDate = '';

  /// Última lectura del sensor (pasos desde el último reinicio del celular).
  /// Es nula si todavía no llegó ninguna lectura.
  final int? lastReading;
  final int totalSteps;
  final int todaySteps;

  /// Fecha (aaaa-mm-dd) a la que corresponde [todaySteps].
  final String todayDate;

  StepState copyWith({
    int? lastReading,
    int? totalSteps,
    int? todaySteps,
    String? todayDate,
  }) {
    return StepState(
      lastReading: lastReading ?? this.lastReading,
      totalSteps: totalSteps ?? this.totalSteps,
      todaySteps: todaySteps ?? this.todaySteps,
      todayDate: todayDate ?? this.todayDate,
    );
  }

  Map<String, Object?> toJson() => {
    'lastReading': lastReading,
    'totalSteps': totalSteps,
    'todaySteps': todaySteps,
    'todayDate': todayDate,
  };

  String encode() => jsonEncode(toJson());

  /// Lee un estado guardado. Si falta o está roto, devuelve el estado inicial.
  static StepState decode(String? source) {
    if (source == null || source.isEmpty) return const StepState.initial();
    try {
      return fromJson(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return const StepState.initial();
    }
  }

  /// Lanza una excepción si el JSON no tiene la forma esperada.
  static StepState fromJson(Map<String, dynamic> json) {
    return StepState(
      lastReading: json['lastReading'] as int?,
      totalSteps: json['totalSteps'] as int,
      todaySteps: json['todaySteps'] as int,
      todayDate: json['todayDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StepState &&
      other.lastReading == lastReading &&
      other.totalSteps == totalSteps &&
      other.todaySteps == todaySteps &&
      other.todayDate == todayDate;

  @override
  int get hashCode =>
      Object.hash(lastReading, totalSteps, todaySteps, todayDate);

  @override
  String toString() =>
      'StepState(lastReading: $lastReading, total: $totalSteps, '
      'today: $todaySteps, date: $todayDate)';
}
