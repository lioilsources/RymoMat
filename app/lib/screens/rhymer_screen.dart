import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_editor/rymo_editor.dart';

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../state/providers.dart';

/// Stand-alone rhyme dictionary (plan §9.1, screen 2).
class RhymerScreen extends ConsumerStatefulWidget {
  const RhymerScreen({super.key});

  @override
  ConsumerState<RhymerScreen> createState() => _RhymerScreenState();
}

class _RhymerScreenState extends ConsumerState<RhymerScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _seq = 0;
  int? _syllables;
  bool _onlyAttested = false, _noGrammatical = false;
  List<Suggestion> _results = const [];
  String _target = '';
  String? _open;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _search() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () async {
      final src = ref.read(rhymeSourceProvider).value;
      final q = _query.text.trim();
      if (src == null) return;
      final seq = ++_seq;
      final res = q.isEmpty
          ? const <Suggestion>[]
          : await src.suggest(
              SuggestQuery(q, limit: 400, syllables: _syllables),
            );
      if (seq != _seq || !mounted) return;
      setState(() {
        _results = res;
        _target = q.isEmpty ? '' : src.lineEnd(q).word;
        _open = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final source = ref.watch(rhymeSourceProvider);
    final shown = _results
        .where((s) => !_onlyAttested || s.attested > 0)
        .where((s) => !_noGrammatical || !s.grammatical)
        .toList();
    final byLevel = <RhymeLevel, List<Suggestion>>{};
    for (final s in shown) {
      byLevel.putIfAbsent(s.level, () => []).add(s);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.tabRhymer)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _query,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: l.rhymerHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _search(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<int?>(
                  value: _syllables,
                  hint: Text(l.filterSyllables),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.filterAny)),
                    for (var n = 1; n <= 6; n++)
                      DropdownMenuItem(
                        value: n,
                        child: Text(l.editorSyllables(n)),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _syllables = v);
                    _search();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l.onlyAttested),
                  selected: _onlyAttested,
                  onSelected: (v) => setState(() => _onlyAttested = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l.noGrammatical),
                  selected: _noGrammatical,
                  onSelected: (v) => setState(() => _noGrammatical = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: source.when(
              loading: () => Center(child: Text(l.packLoading)),
              error: (e, _) => Center(child: Text(l.packError('$e'))),
              data: (src) => _query.text.trim().isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(l.rhymerEmpty, textAlign: TextAlign.center),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(l.editorNoSuggestions),
                          ),
                        for (final level in RhymeLevel.values)
                          if (byLevel[level] != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 4,
                              ),
                              child: Text(
                                '${l.levelName(level)} · ${byLevel[level]!.length}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            for (final s in byLevel[level]!) _row(src, l, s),
                          ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(RhymeSource src, AppLocalizations l, Suggestion s) {
    final sub = [
      if (s.attested > 0) l.editorAttested(s.attested),
      if (s.grammatical) l.editorGrammatical,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(s.word),
          subtitle: sub.isEmpty ? null : Text(sub),
          trailing: s.attested > 0
              ? Icon(_open == s.word ? Icons.expand_less : Icons.format_quote)
              : null,
          onTap: s.attested > 0
              ? () => setState(() => _open = _open == s.word ? null : s.word)
              : null,
        ),
        if (_open == s.word)
          CitationList(
            source: src,
            a: _target,
            b: s.word,
            labels: l.editorLabels,
          ),
      ],
    );
  }
}
