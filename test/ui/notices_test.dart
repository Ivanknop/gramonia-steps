import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/strings.dart';
import 'package:rpg/ui/notices.dart';
import 'package:test/test.dart';

void main() {
  const engine = ChapterEngine(chapter1);
  const start = ChapterProgress.initial();
  String noticeAfter(int steps) =>
      noticeFor(engine.advance(start, steps).events);

  test('un objeto: dice cuál', () {
    expect(
      noticeAfter(250),
      Strings.itemCollected('Hoja dorada del árbol mágico'),
    );
  });

  test('terminar una etapa: dice cuál y su recompensa', () {
    final p = engine.advance(start, 900).progress;
    final events = engine.advance(p, 100).events;
    expect(
      noticeFor(events),
      Strings.stageCompleted('El árbol mágico', 'Caperuza de aprendiz'),
    );
  });

  test('varios objetos: un resumen', () {
    expect(noticeAfter(600), Strings.collectedSummary(2, 0));
    expect(noticeAfter(1500), Strings.collectedSummary(5, 1));
    expect(
      Strings.collectedSummary(7, 1),
      '¡Conseguiste 7 objetos y terminaste 1 etapa!',
    );
  });

  test('fin del capítulo: el barco zarpa', () {
    expect(noticeAfter(30000), Strings.chapterCompleted);
  });
}
