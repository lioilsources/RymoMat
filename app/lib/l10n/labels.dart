import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_editor/rymo_editor.dart';

import 'app_localizations.dart';

extension RhymeLabels on AppLocalizations {
  String levelName(RhymeLevel l) => switch (l) {
    RhymeLevel.identical => levelIdentical,
    RhymeLevel.full => levelFull,
    RhymeLevel.masc => levelMasc,
    RhymeLevel.weak => levelWeak,
    RhymeLevel.looseFull => levelLooseFull,
    RhymeLevel.loose => levelLoose,
    RhymeLevel.assonance => levelAssonance,
    RhymeLevel.none => levelNone,
  };

  RhymeEditorLabels get editorLabels => RhymeEditorLabels(
    syllables: editorSyllables,
    newRhyme: editorNewRhyme,
    noSuggestions: editorNoSuggestions,
    rhymesFor: editorRhymesFor,
    level: levelName,
    attested: editorAttested,
    grammatical: editorGrammatical,
    used: editorUsed,
    prefixIgnored: editorPrefixIgnored,
    citations: editorCitations,
    noCitations: editorNoCitations,
    insert: editorInsert,
  );
}
