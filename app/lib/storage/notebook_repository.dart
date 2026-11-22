import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rymo_core/rymo_core.dart';

/// A notebook file `notebooks/<slug>.yaml`.
class NotebookEntry {
  final String slug;
  final Notebook notebook;
  const NotebookEntry(this.slug, this.notebook);
}

/// Stores notebooks as PoetryStream YAML files (plan §9.3).
class NotebookRepository {
  final Directory dir;
  NotebookRepository(Directory documents)
    : dir = Directory(p.join(documents.path, 'notebooks'));

  File _file(String slug) => File(p.join(dir.path, '$slug.yaml'));

  Future<List<NotebookEntry>> list() async {
    if (!dir.existsSync()) return const [];
    final out = <NotebookEntry>[];
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.yaml')) continue;
      final slug = p.basenameWithoutExtension(f.path);
      try {
        out.add(
          NotebookEntry(
            slug,
            Notebook.fromYaml(await f.readAsString(), fallbackTitle: slug),
          ),
        );
      } on Exception {
        // A broken file is skipped, never overwritten.
      }
    }
    out.sort(
      (a, b) => a.notebook.title.toLowerCase().compareTo(
        b.notebook.title.toLowerCase(),
      ),
    );
    return out;
  }

  Future<NotebookEntry> create(Notebook nb) async {
    final slug = _uniqueSlug(slugify(nb.title));
    await save(slug, nb);
    return NotebookEntry(slug, nb);
  }

  /// Atomic write: temporary file, then rename.
  Future<void> save(String slug, Notebook nb) async {
    dir.createSync(recursive: true);
    final tmp = File(p.join(dir.path, '.$slug.yaml.tmp'));
    await tmp.writeAsString(nb.toYaml(), flush: true);
    await tmp.rename(_file(slug).path);
  }

  Future<void> delete(String slug) async {
    final f = _file(slug);
    if (f.existsSync()) await f.delete();
  }

  String filePath(String slug) => _file(slug).path;

  String _uniqueSlug(String base) {
    var slug = base;
    for (var i = 2; _file(slug).existsSync(); i++) {
      slug = '$base-$i';
    }
    return slug;
  }

  /// Imports a `.yaml` notebook (both PoetryStream variants) or a `.txt`
  /// poem (new notebook named after the file).
  Future<NotebookEntry> import(String fileName, String content) async {
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.yaml' || ext == '.yml') {
      return create(Notebook.fromYaml(content, fallbackTitle: base));
    }
    final poem = Notebook.poemFromText(
      content,
      fallbackTitle: base,
      titleFromFirstLine: true,
    );
    return create(Notebook(title: base, poems: [poem]));
  }
}
