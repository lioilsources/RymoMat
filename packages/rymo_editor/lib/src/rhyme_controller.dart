import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rymo_core/rymo_core.dart';

import 'rhyme_source.dart';
import 'verse_text.dart';

/// Suggestions for one target of the active verse.
class TargetSuggestions {
  final RhymeTarget target;
  final List<Suggestion> suggestions;
  const TargetSuggestions(this.target, this.suggestions);
}

/// State shown by the rhyme bar.
class RhymeBarState {
  /// Syllables of the active verse.
  final int syllables;
  final List<TargetSuggestions> targets;

  /// Prefix used as a filter (may have been ignored, see
  /// [Suggestion.prefixIgnored]).
  final String prefix;
  const RhymeBarState({
    this.syllables = 0,
    this.targets = const [],
    this.prefix = '',
  });
}

/// Text controller for verse editing. Owns the rhyme bar state: it reacts
/// to text and cursor changes with an 80 ms debounce and drops results of
/// stale requests by sequence number.
class RhymeEditingController extends TextEditingController {
  RhymeSource? _source;
  final Duration debounce;

  /// How many targets the bar shows.
  final int maxTargets;

  /// Chips per target.
  final int chipsPerTarget;

  final ValueNotifier<RhymeBarState> bar = ValueNotifier(const RhymeBarState());

  Timer? _timer;
  int _seq = 0;
  String _lastKey = '';

  RhymeEditingController({
    super.text,
    RhymeSource? source,
    this.debounce = const Duration(milliseconds: 80),
    this.maxTargets = 3,
    this.chipsPerTarget = 12,
  }) : _source = source {
    addListener(_changed);
    _changed();
  }

  RhymeSource? get source => _source;
  set source(RhymeSource? s) {
    _source = s;
    _lastKey = '';
    _changed();
  }

  /// Sequence number of the latest request (for tests).
  int get sequence => _seq;

  void _changed() {
    final sel = selection;
    final cursor = sel.isValid ? sel.extentOffset : text.length;
    final key = '$cursor\u0000$text';
    if (key == _lastKey) return;
    _lastKey = key;
    _timer?.cancel();
    _timer = Timer(debounce, refresh);
  }

  /// Recomputes targets and suggestions now.
  Future<void> refresh() async {
    final src = _source;
    if (src == null) return;
    final seq = ++_seq;
    final t = text;
    final cursor = selection.isValid ? selection.extentOffset : t.length;
    final vt = VerseText(t);
    final active = vt.lineAt(cursor.clamp(0, t.length));
    final syl = src.lineEnd(vt.lines[active]).syl;
    final prefix = vt.typingPrefix(cursor);
    final targets = freeModeTargets(src, vt, active).take(maxTargets).toList();
    final used = lineEndWords(src, vt, except: active);
    final results = await Future.wait([
      for (final tg in targets)
        src.suggest(
          SuggestQuery(
            tg.end.line,
            prefix: prefix,
            limit: chipsPerTarget,
            usedWords: used,
          ),
        ),
    ]);
    if (seq != _seq) return; // a newer request superseded this one
    bar.value = RhymeBarState(
      syllables: syl,
      prefix: prefix,
      targets: [
        for (var i = 0; i < targets.length; i++)
          TargetSuggestions(targets[i], results[i]),
      ],
    );
  }

  /// Inserts a suggested word (see [insertSuggestion]).
  void insertWord(String word) {
    value = insertSuggestion(value, word);
  }

  @override
  void dispose() {
    _timer?.cancel();
    bar.dispose();
    super.dispose();
  }
}
