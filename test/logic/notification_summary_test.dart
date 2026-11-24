import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/notification_summary.dart';
import 'package:test/test.dart';

void main() {
  final lila = chapter1.item('flor_lila');
  final agua = chapter1.item('semilla_agua');
  final gema = chapter1.item('gema');
  final casa = chapter1.stages[1];
  final nido = chapter1.stages[2];
  final puerto = chapter1.stages[4];

  test('un objeto: "¡Encontraste…!" y suena', () {
    final s = NotificationSummary()..add([ItemFound(casa, lila)]);
    final n = s.build();
    expect(n.title, '¡Encontraste una flor lila!');
    expect(n.lines, ['Flor lila']);
    expect(n.alert, isTrue);
  });

  test('muchos objetos de golpe: una sola notificación con la cuenta', () {
    final s = NotificationSummary()
      ..add([for (var i = 0; i < 7; i++) ItemFound(casa, lila)])
      ..add([ItemFound(nido, agua), ItemFound(nido, agua)]);
    final n = s.build();
    expect(n.title, '¡Encontraste 9 objetos!');
    expect(n.lines, ['Flor lila ×7', 'Semilla de agua ×2']);
  });

  test('las gemas no avisan', () {
    final s = NotificationSummary()..add([ItemFound(casa, gema)]);
    expect(s.isEmpty, isTrue);
  });

  test('al pasar de etapa, el título es la etapa', () {
    final s = NotificationSummary()
      ..add([ItemFound(casa, lila), StageCompleted(casa)]);
    final n = s.build();
    expect(n.title, '¡Etapa completada: ${casa.name}!');
    expect(n.lines, ['¡Etapa completada: ${casa.name}!', 'Flor lila']);
  });

  test('varias etapas y una llegada', () {
    final s = NotificationSummary()
      ..add([StageCompleted(casa), StageCompleted(nido), Arrived(puerto)]);
    final n = s.build();
    expect(n.title, '¡Completaste 2 etapas!');
    expect(n.lines.last, 'Llegaste al Muelle');
  });

  test('al actualizarla, solo suena si hay una etapa nueva', () {
    final s = NotificationSummary()..add([ItemFound(casa, lila)]);
    expect(s.build().alert, isTrue);
    s.add([ItemFound(casa, lila)]);
    final more = s.build();
    expect(more.alert, isFalse);
    expect(more.lines, ['Flor lila ×2']);
    s.add([StageCompleted(casa)]);
    expect(s.build().alert, isTrue);
  });

  test('al abrir el juego se empieza de cero', () {
    final s = NotificationSummary()..add([ItemFound(casa, lila)]);
    s.build();
    s.clear();
    expect(s.isEmpty, isTrue);
    s.add([ItemFound(casa, lila)]);
    expect(s.build().alert, isTrue);
  });
}
