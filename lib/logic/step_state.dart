import 'dart:convert';

/// Estado de los pasos, guardado en el celular.
class StepState {
  const StepState({
    required this.lastReading,
    required this.totalSteps,
    required this.todaySteps,
    required this.todayDate,
    this.lastReadingAt,
  });

  /// Estado de una instalación nueva.
  const StepState.initial()
    : lastReading = null,
      totalSteps = 0,
      todaySteps = 0,
      todayDate = '',
      lastReadingAt = null;

  /// Última lectura del sensor (pasos desde el último reinicio del celular).
  /// Es nula si todavía no llegó ninguna lectura.
  final int? lastReading;
  final int totalSteps;
  final int todaySteps;

  /// Fecha (aaaa-mm-dd) a la que corresponde [todaySteps].
  final String todayDate;

  /// Cuándo llegó [lastReading]. Nula en las partidas de antes.
  final DateTime? lastReadingAt;

  StepState copyWith({
    int? lastReading,
    int? totalSteps,
    int? todaySteps,
    String? todayDate,
    DateTime? lastReadingAt,
  }) {
    return StepState(
      lastReading: lastReading ?? this.lastReading,
      totalSteps: totalSteps ?? this.totalSteps,
      todaySteps: todaySteps ?? this.todaySteps,
      todayDate: todayDate ?? this.todayDate,
      lastReadingAt: lastReadingAt ?? this.lastReadingAt,
    );
  }

  Map<String, Object?> toJson() => {
    'lastReading': lastReading,
    'totalSteps': totalSteps,
    'todaySteps': todaySteps,
    'todayDate': todayDate,
    'lastReadingAt': lastReadingAt?.toIso8601String(),
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
      lastReadingAt: switch (json['lastReadingAt']) {
        final String at => DateTime.parse(at),
        _ => null,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StepState &&
      other.lastReading == lastReading &&
      other.totalSteps == totalSteps &&
      other.todaySteps == todaySteps &&
      other.todayDate == todayDate &&
      other.lastReadingAt == lastReadingAt;

  @override
  int get hashCode => Object.hash(
    lastReading,
    totalSteps,
    todaySteps,
    todayDate,
    lastReadingAt,
  );

  @override
  String toString() =>
      'StepState(lastReading: $lastReading, total: $totalSteps, '
      'today: $todaySteps, date: $todayDate, at: $lastReadingAt)';
}
