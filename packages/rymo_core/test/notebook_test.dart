import 'package:rymo_core/rymo_core.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  const maj =
      'byl pozdní večer – první máj –\n'
      'večerní máj – byl lásky čas.\n'
      '\n'
      'hrdliččin zval ku lásce hlas,\n'
      'kde borový zaváněl háj.';

  test('round-trip keeps text, blank lines and odd titles', () {
    final nb = Notebook(
      title: 'Máj: "zpěv" \\ první',
      poems: [
        const NotebookPoem(title: 'I.', author: 'K. H. Mácha', text: maj),
        const NotebookPoem(title: '', text: '  odsazený začátek\n\n\nkonec'),
        const NotebookPoem(title: 'prázdná'),
        const NotebookPoem(
          title: 'tab\tnový\nřádek',
          text: '# není komentář\n- není seznam',
        ),
      ],
    );
    final yaml = nb.toYaml();
    final back = Notebook.fromYaml(yaml);
    expect(back.title, nb.title);
    expect(back.lang, 'cs');
    expect(back.poems, nb.poems);
    // What PoetryStream reads: loadYaml + poems[].title/text.
    final doc = loadYaml(yaml) as YamlMap;
    final first = (doc['poems'] as YamlList).first as YamlMap;
    expect((first['text'] as String).trimRight(), maj);
    expect(doc['rymomat']['schema'], 1);
  });

  test('trailing spaces are trimmed', () {
    final nb = Notebook(
      title: 't',
      poems: [const NotebookPoem(title: 'a', text: 'verš   \ndruhý \n\n')],
    );
    expect(Notebook.fromYaml(nb.toYaml()).poems.single.text, 'verš\ndruhý');
  });

  test('reads the PoetryStream list variant', () {
    const src =
        '- title: "A"\n  text: |\n    jedna\n\n    dvě\n- title: B\n  text: x\n';
    final nb = Notebook.fromYaml(src, fallbackTitle: 'default');
    expect(nb.title, 'default');
    expect(nb.poems.map((p) => p.text), ['jedna\n\ndvě', 'x']);
  });

  test('keeps product_id', () {
    const src = 'title: "S"\nproduct_id: com.x.y\npoems: []\n';
    final nb = Notebook.fromYaml(src);
    expect(nb.productId, 'com.x.y');
    expect(Notebook.fromYaml(nb.toYaml()).productId, 'com.x.y');
  });

  test('plain text import', () {
    final p = Notebook.poemFromText(
      'Název\n\nverš\nverš',
      titleFromFirstLine: true,
    );
    expect([p.title, p.text], ['Název', 'verš\nverš']);
  });

  test('slugify', () {
    expect(slugify('Ježíš hraje na sitár!'), 'jezis-hraje-na-sitar');
    expect(slugify('???'), 'sbirka');
  });
}
