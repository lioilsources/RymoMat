import 'package:rymo_core/rymo_core.dart';
import 'package:test/test.dart';

void main() {
  final p = CzechProfile();

  test('lineEnd takes the last word and counts line syllables', () {
    final e = lineEndOf(p, 'Byl pozdní večer, první máj,');
    expect(e.word, 'máj');
    expect(e.phon, 'mAj');
    expect(e.syl, 8);
  });

  test('analyze groups rhymes and letters per stanza', () {
    const text =
        'byl pozdní večer první máj\n'
        'večerní máj byl lásky čas\n'
        'hrdliččin zval ku lásce háj\n'
        'kde borový zaváněl hvozd\n'
        '\n'
        'o lásce šeptal tichý mech\n'
        'a nic tu není\n'
        'kvetoucí strom lhal lásky žel\n'
        'svou lásku slavík růži pěl';
    final a = analyzePoem(p, text);
    final letters = a.lines.map((l) => l.letter ?? '-').join();
    expect(letters, 'ABAC-ABCC');
    expect(a.lines[0].group, a.lines[2].group);
    expect(a.lines[0].group, isNotNull);
    expect(a.lines[1].group, isNull);
    expect(a.lines[7].group, a.lines[8].group);
  });
}
