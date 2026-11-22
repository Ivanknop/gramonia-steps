import 'package:rpg/logic/chapter_progress.dart';
import 'package:test/test.dart';

void main() {
  test('ida y vuelta por JSON', () {
    const p = ChapterProgress(
      stageIndex: 2,
      stepsInStage: 1234,
      collected: ['a', 'b', 'c'],
    );
    expect(ChapterProgress.fromJson(p.toJson()), p);
  });

  test('has() dice si un objeto está en el inventario', () {
    const p = ChapterProgress(stageIndex: 0, stepsInStage: 0, collected: ['x']);
    expect(p.has('x'), isTrue);
    expect(p.has('y'), isFalse);
  });
}
