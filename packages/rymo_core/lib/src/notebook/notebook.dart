import 'package:yaml/yaml.dart';

/// One poem of a notebook.
class NotebookPoem {
  final String title;
  final String author;
  final String text;

  const NotebookPoem({required this.title, this.author = '', this.text = ''});

  NotebookPoem copyWith({String? title, String? author, String? text}) =>
      NotebookPoem(
        title: title ?? this.title,
        author: author ?? this.author,
        text: text ?? this.text,
      );

  @override
  bool operator ==(Object other) =>
      other is NotebookPoem &&
      other.title == title &&
      other.author == author &&
      other.text == text;

  @override
  int get hashCode => Object.hash(title, author, text);
}

/// A notebook stored in the PoetryStream YAML format (map variant, plan §9.3).
class Notebook {
  final String title;
  final String lang;

  /// Set by the publisher; kept untouched on round-trips.
  final String? productId;
  final List<NotebookPoem> poems;

  const Notebook({
    required this.title,
    this.lang = 'cs',
    this.productId,
    this.poems = const [],
  });

  Notebook copyWith({String? title, List<NotebookPoem>? poems}) => Notebook(
    title: title ?? this.title,
    lang: lang,
    productId: productId,
    poems: poems ?? this.poems,
  );

  static const int schema = 1;

  /// Writes the fixed schema: quoted titles, text as a `|` block.
  String toYaml() {
    final b = StringBuffer()
      ..writeln('title: ${quoteYaml(title)}')
      ..writeln('rymomat: {lang: $lang, schema: $schema}');
    if (productId != null) b.writeln('product_id: ${quoteYaml(productId!)}');
    if (poems.isEmpty) {
      b.writeln('poems: []');
      return b.toString();
    }
    b.writeln('poems:');
    for (final p in poems) {
      b.writeln('- title: ${quoteYaml(p.title)}');
      if (p.author.isNotEmpty) b.writeln('  author: ${quoteYaml(p.author)}');
      b.write(_textBlock(p.text));
    }
    return b.toString();
  }

  /// Parses both PoetryStream variants: a plain list of poems or a map with
  /// `poems`. [fallbackTitle] is used for the list variant.
  static Notebook fromYaml(String source, {String fallbackTitle = ''}) {
    final doc = loadYaml(source);
    YamlList? list;
    var title = fallbackTitle;
    var lang = 'cs';
    String? productId;
    if (doc is YamlMap) {
      title = (doc['title'] as String?) ?? fallbackTitle;
      productId = doc['product_id']?.toString();
      final meta = doc['rymomat'];
      if (meta is YamlMap && meta['lang'] is String) lang = meta['lang'];
      final p = doc['poems'];
      if (p is YamlList) list = p;
    } else if (doc is YamlList) {
      list = doc;
    } else if (doc != null) {
      throw const FormatException('Not a PoetryStream notebook');
    }
    final poems = <NotebookPoem>[
      for (final item in list ?? YamlList())
        if (item is YamlMap)
          NotebookPoem(
            title: item['title']?.toString() ?? '',
            author: item['author']?.toString() ?? '',
            text: _trimText(item['text']?.toString() ?? ''),
          ),
    ];
    return Notebook(
      title: title,
      lang: lang,
      productId: productId,
      poems: poems,
    );
  }

  /// Plain text import: one poem; a first line followed by a blank line is
  /// taken as the title when [titleFromFirstLine] is set.
  static NotebookPoem poemFromText(
    String text, {
    String fallbackTitle = '',
    bool titleFromFirstLine = false,
  }) {
    final t = text.replaceAll('\r\n', '\n');
    if (titleFromFirstLine) {
      final lines = t.split('\n');
      if (lines.length > 2 && lines[1].trim().isEmpty) {
        return NotebookPoem(
          title: lines.first.trim(),
          text: _trimText(lines.skip(2).join('\n')),
        );
      }
    }
    return NotebookPoem(title: fallbackTitle, text: _trimText(t));
  }

  /// Trailing spaces of each line and trailing blank lines are dropped.
  static String _trimText(String s) {
    final lines = s.replaceAll('\r\n', '\n').split('\n');
    return lines.map((l) => l.trimRight()).join('\n').trimRight();
  }

  static String _textBlock(String raw) {
    final text = _trimText(raw);
    if (text.isEmpty) return '  text: ""\n';
    final lines = text.split('\n');
    // A leading space (or tab) in the first line needs an indentation indicator.
    final first = lines.first;
    final indicator = first.isNotEmpty && (first[0] == ' ' || first[0] == '\t')
        ? '|2'
        : '|';
    final b = StringBuffer('  text: $indicator\n');
    for (final l in lines) {
      b.writeln(l.isEmpty ? '' : '    $l');
    }
    return b.toString();
  }
}

/// Double-quoted YAML scalar with escaping.
String quoteYaml(String s) {
  final b = StringBuffer('"');
  for (final r in s.runes) {
    switch (r) {
      case 0x22:
        b.write(r'\"');
      case 0x5c:
        b.write(r'\\');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        if (r < 0x20) {
          b.write('\\x${r.toRadixString(16).padLeft(2, '0')}');
        } else {
          b.writeCharCode(r);
        }
    }
  }
  b.write('"');
  return b.toString();
}

/// File-system friendly slug of a notebook title.
String slugify(String title) {
  const map = {
    'á': 'a',
    'č': 'c',
    'ď': 'd',
    'é': 'e',
    'ě': 'e',
    'í': 'i',
    'ň': 'n',
    'ó': 'o',
    'ř': 'r',
    'š': 's',
    'ť': 't',
    'ú': 'u',
    'ů': 'u',
    'ý': 'y',
    'ž': 'z',
    'ä': 'a',
    'ö': 'o',
    'ü': 'u',
    'ľ': 'l',
    'ĺ': 'l',
    'ŕ': 'r',
  };
  final b = StringBuffer();
  for (final c in title.toLowerCase().split('')) {
    final m = map[c] ?? c;
    if (RegExp(r'[a-z0-9]').hasMatch(m)) {
      b.write(m);
    } else if (b.isNotEmpty && !b.toString().endsWith('-')) {
      b.write('-');
    }
  }
  var s = b.toString();
  while (s.endsWith('-')) {
    s = s.substring(0, s.length - 1);
  }
  return s.isEmpty ? 'sbirka' : s;
}
