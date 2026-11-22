import 'package:rymo_core/rymo_core.dart';

/// User-facing texts of the editor widgets; the app fills them from its ARB
/// localizations.
class RhymeEditorLabels {
  final String Function(int n) syllables;
  final String newRhyme;
  final String noSuggestions;
  final String Function(String word) rhymesFor;
  final String Function(RhymeLevel level) level;
  final String Function(int n) attested;
  final String grammatical;
  final String used;
  final String prefixIgnored;
  final String citations;
  final String noCitations;
  final String insert;

  const RhymeEditorLabels({
    required this.syllables,
    required this.newRhyme,
    required this.noSuggestions,
    required this.rhymesFor,
    required this.level,
    required this.attested,
    required this.grammatical,
    required this.used,
    required this.prefixIgnored,
    required this.citations,
    required this.noCitations,
    required this.insert,
  });
}
