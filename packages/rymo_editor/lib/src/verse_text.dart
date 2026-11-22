import 'package:flutter/services.dart';
import 'package:rymo_core/rymo_core.dart';

import 'rhyme_source.dart';

final _letters = RegExp(r'[\p{L}]+$', unicode: true);

/// Line layout of the editor text.
class VerseText {
  final String text;
  final List<String> lines;
  final List<int> starts;

  VerseText(this.text) : lines = text.split('\n'), starts = _starts(text);

  static List<int> _starts(String t) {
    final s = [0];
    for (var i = 0; i < t.length; i++) {
      if (t.codeUnitAt(i) == 10) s.add(i + 1);
    }
    return s;
  }

  /// Index of the line containing [offset].
  int lineAt(int offset) {
    var lo = 0, hi = starts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (starts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  int lineEnd(int line) => starts[line] + lines[line].length;

  bool isBlank(int line) => lines[line].trim().isEmpty;

  /// Written prefix being typed: cursor at the end of a line whose last token
  /// does not end with a space. Empty otherwise.
  String typingPrefix(int cursor) {
    final li = lineAt(cursor);
    if (cursor != lineEnd(li)) return '';
    final m = _letters.firstMatch(lines[li]);
    return m?.group(0) ?? '';
  }

  /// Verse indexes (non-blank lines) of the stanza the active line belongs
  /// to, before the active line. A blank active line right after a verse
  /// continues that stanza.
  List<int> stanzaBefore(int active) {
    final out = <int>[];
    for (var i = active - 1; i >= 0 && !isBlank(i); i--) {
      out.add(i);
    }
    return out; // nearest first
  }

  /// Last verse of the stanza before the one that contains [active].
  int? previousStanzaLast(int active) {
    var i = active - 1;
    while (i >= 0 && !isBlank(i)) {
      i--;
    }
    while (i >= 0 && isBlank(i)) {
      i--;
    }
    return i >= 0 ? i : null;
  }
}

/// A line end the active verse may rhyme with.
class RhymeTarget {
  final int line;
  final LineEnd end;

  /// Already rhymes with another verse of the stanza.
  final bool partnered;
  const RhymeTarget(this.line, this.end, {this.partnered = false});
}

/// Free mode targets (plan §9.2): previous verse ends of the same stanza
/// (max [maxCandidates], nearest first); with fewer than 2 verses the last
/// verse of the previous stanza joins. Unpartnered ends go first.
List<RhymeTarget> freeModeTargets(
  RhymeSource src,
  VerseText vt,
  int active, {
  int maxCandidates = 6,
}) {
  final before = vt.stanzaBefore(active).take(maxCandidates).toList();
  final cand = [...before];
  if (before.length < 2) {
    final prev = vt.previousStanzaLast(active);
    if (prev != null) cand.add(prev);
  }
  final ends = <int, LineEnd>{
    for (final i in cand) i: src.lineEnd(vt.lines[i]),
  };
  ends.removeWhere((_, e) => e.keys == null);
  final lines = ends.keys.toList();
  final free = <RhymeTarget>[], rhymed = <RhymeTarget>[];
  for (final i in lines) {
    var partner = false;
    for (final j in lines) {
      if (i == j) continue;
      final lvl = src.classify(ends[i]!, ends[j]!);
      if (lvl != RhymeLevel.none && lvl.atLeast(RhymeLevel.loose)) {
        partner = true;
        break;
      }
    }
    (partner ? rhymed : free).add(RhymeTarget(i, ends[i]!, partnered: partner));
  }
  return [...free, ...rhymed];
}

/// Line-end words of the whole text (for `Suggestion.used`).
Set<String> lineEndWords(RhymeSource src, VerseText vt, {int? except}) => {
  for (var i = 0; i < vt.lines.length; i++)
    if (i != except && !vt.isBlank(i)) src.lineEnd(vt.lines[i]).word,
}..remove('');

/// Inserts [word] into the line holding the cursor: replaces the token being
/// typed, otherwise appends it to the line with a space. The cursor ends at
/// the end of that line.
TextEditingValue insertSuggestion(TextEditingValue value, String word) {
  final text = value.text;
  final cursor = value.selection.isValid
      ? value.selection.extentOffset
      : text.length;
  final vt = VerseText(text);
  final li = vt.lineAt(cursor);
  final start = vt.starts[li];
  final end = vt.lineEnd(li);
  final line = vt.lines[li];
  final prefix = vt.typingPrefix(cursor);
  String newLine;
  if (prefix.isNotEmpty) {
    newLine = line.substring(0, line.length - prefix.length) + word;
  } else if (line.trim().isEmpty) {
    newLine = word;
  } else {
    newLine = line.endsWith(' ') ? '$line$word' : '$line $word';
  }
  final newText = text.replaceRange(start, end, newLine);
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: start + newLine.length),
  );
}
