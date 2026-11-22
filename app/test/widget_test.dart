import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rymo_core/rymo_core.dart';
import 'package:rymomat/storage/notebook_repository.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('rymomat'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('repository creates unique slugs and round-trips notebooks', () async {
    final repo = NotebookRepository(dir);
    final a = await repo.create(const Notebook(title: 'Máj'));
    final b = await repo.create(const Notebook(title: 'máj'));
    expect([a.slug, b.slug], ['maj', 'maj-2']);
    await repo.save(
      a.slug,
      a.notebook.copyWith(
        poems: [const NotebookPoem(title: 'I.', text: 'verš\n\nsloka')],
      ),
    );
    final list = await repo.list();
    expect(list.length, 2);
    expect(
      list.firstWhere((e) => e.slug == 'maj').notebook.poems.single.text,
      'verš\n\nsloka',
    );
  });

  test('import yaml (list variant) and txt', () async {
    final repo = NotebookRepository(dir);
    final y = await repo.import(
      'default.yaml',
      '- title: "A"\n  text: |\n    jedna\n',
    );
    expect(y.notebook.title, 'default');
    final t = await repo.import('Noc.txt', 'Noc\n\nhvězdy\nnad lesem\n');
    expect(t.notebook.poems.single.title, 'Noc');
    expect(t.notebook.poems.single.text, 'hvězdy\nnad lesem');
  });
}
