import 'package:flutter/material.dart';
import 'package:rymo_core/rymo_core.dart';

import 'labels.dart';
import 'rhyme_controller.dart';
import 'rhyme_source.dart';

/// Eight-color palette for rhyme targets and groups.
const rhymePalette = <Color>[
  Color(0xFFE4572E),
  Color(0xFF29335C),
  Color(0xFF17BEBB),
  Color(0xFFFFC914),
  Color(0xFF76B041),
  Color(0xFF9C51B6),
  Color(0xFFF45B69),
  Color(0xFF3E8EDE),
];

/// Multiline verse field. Capitalization and autocorrect are off by default
/// (the first user writes lowercase free verse).
class RhymeTextField extends StatelessWidget {
  final RhymeEditingController controller;
  final FocusNode? focusNode;
  final bool capitalizeLines;
  final bool autocorrect;
  final String? hintText;
  final TextStyle? style;

  /// Called for the selection action "rhymes for …".
  final void Function(String word)? onRhymesFor;
  final RhymeEditorLabels labels;

  const RhymeTextField({
    super.key,
    required this.controller,
    required this.labels,
    this.focusNode,
    this.capitalizeLines = false,
    this.autocorrect = false,
    this.hintText,
    this.style,
    this.onRhymesFor,
  });

  static final _word = RegExp(r'[\p{L}]+', unicode: true);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      textCapitalization: capitalizeLines
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      autocorrect: autocorrect,
      enableSuggestions: autocorrect,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      style: style,
      decoration: InputDecoration(hintText: hintText, border: InputBorder.none),
      contextMenuBuilder: (context, state) {
        final items = [...state.contextMenuButtonItems];
        final sel = controller.selection;
        if (onRhymesFor != null && sel.isValid && !sel.isCollapsed) {
          final m = _word.firstMatch(sel.textInside(controller.text));
          if (m != null) {
            final w = m.group(0)!;
            items.insert(
              0,
              ContextMenuButtonItem(
                label: labels.rhymesFor(w),
                onPressed: () {
                  ContextMenuController.removeAny();
                  onRhymesFor!(w);
                },
              ),
            );
          }
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }
}

/// Bar above the keyboard: syllables of the active verse, then one segment
/// per target (colored dot, target word, chips). Tap inserts, long press
/// opens the [RhymeSheet].
class RhymeBar extends StatelessWidget {
  final RhymeEditingController controller;
  final RhymeEditorLabels labels;
  final RhymeSource source;

  const RhymeBar({
    super.key,
    required this.controller,
    required this.labels,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: SizedBox(
        height: 48,
        child: ValueListenableBuilder<RhymeBarState>(
          valueListenable: controller.bar,
          builder: (context, st, _) {
            final children = <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    labels.syllables(st.syllables),
                    key: const Key('rhyme-bar-syllables'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ];
            if (st.targets.isEmpty) {
              children.add(
                Center(
                  child: Text(
                    labels.newRhyme,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            for (var i = 0; i < st.targets.length; i++) {
              final t = st.targets[i];
              final color = rhymePalette[i % rhymePalette.length];
              children.add(_TargetLabel(word: t.target.end.word, color: color));
              if (t.suggestions.isEmpty) {
                children.add(
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        labels.noSuggestions,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                );
              }
              for (final s in t.suggestions) {
                children.add(
                  _Chip(
                    suggestion: s,
                    color: color,
                    onTap: () => controller.insertWord(s.word),
                    onLongPress: () => RhymeSheet.show(
                      context,
                      source: source,
                      target: t.target.end.line,
                      labels: labels,
                      usedWords: {
                        for (final x in t.suggestions)
                          if (x.used) x.word,
                      },
                      onInsert: controller.insertWord,
                    ),
                  ),
                );
              }
            }
            return ListView(
              scrollDirection: Axis.horizontal,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

class _TargetLabel extends StatelessWidget {
  final String word;
  final Color color;
  const _TargetLabel({required this.word, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            word,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Suggestion suggestion;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Chip({
    required this.suggestion,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final strong = s.level.atLeast(RhymeLevel.weak);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: InkWell(
        key: ValueKey('chip-${s.word}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: strong ? 0.9 : 0.4),
              width: s.attested > 0 ? 2 : 1,
            ),
          ),
          child: Text(
            s.word,
            style: TextStyle(
              decoration: s.used ? TextDecoration.lineThrough : null,
              fontWeight: s.attested > 0 ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// All suggestions for a target, grouped by level, with citations of
/// attested pairs.
class RhymeSheet extends StatefulWidget {
  final RhymeSource source;
  final String target;
  final RhymeEditorLabels labels;
  final Set<String> usedWords;
  final void Function(String word)? onInsert;

  const RhymeSheet({
    super.key,
    required this.source,
    required this.target,
    required this.labels,
    this.usedWords = const {},
    this.onInsert,
  });

  static Future<void> show(
    BuildContext context, {
    required RhymeSource source,
    required String target,
    required RhymeEditorLabels labels,
    Set<String> usedWords = const {},
    void Function(String word)? onInsert,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => RhymeSheet(
        source: source,
        target: target,
        labels: labels,
        usedWords: usedWords,
        onInsert: onInsert == null
            ? null
            : (w) {
                Navigator.of(context).pop();
                onInsert(w);
              },
      )._withScroll(scroll),
    ),
  );

  Widget _withScroll(ScrollController c) =>
      PrimaryScrollController(controller: c, child: this);

  @override
  State<RhymeSheet> createState() => _RhymeSheetState();
}

class _RhymeSheetState extends State<RhymeSheet> {
  late final Future<List<Suggestion>> _future;
  String? _open;

  @override
  void initState() {
    super.initState();
    _future = widget.source.suggest(
      SuggestQuery(widget.target, limit: 300, usedWords: widget.usedWords),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    final end = widget.source.lineEnd(widget.target);
    return FutureBuilder<List<Suggestion>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        final byLevel = <RhymeLevel, List<Suggestion>>{};
        for (final s in items) {
          byLevel.putIfAbsent(s.level, () => []).add(s);
        }
        return ListView(
          primary: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              l.rhymesFor(end.word),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(l.noSuggestions),
              ),
            for (final level in RhymeLevel.values)
              if (byLevel[level] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 4),
                  child: Text(
                    l.level(level),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final s in byLevel[level]!) _row(context, end.word, s),
              ],
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, String targetWord, Suggestion s) {
    final l = widget.labels;
    final sub = [
      if (s.attested > 0) l.attested(s.attested),
      if (s.grammatical) l.grammatical,
      if (s.used) l.used,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(s.word),
          subtitle: sub.isEmpty ? null : Text(sub),
          onTap: widget.onInsert == null
              ? null
              : () => widget.onInsert!(s.word),
          trailing: s.attested > 0
              ? IconButton(
                  tooltip: l.citations,
                  icon: Icon(
                    _open == s.word ? Icons.expand_less : Icons.format_quote,
                  ),
                  onPressed: () =>
                      setState(() => _open = _open == s.word ? null : s.word),
                )
              : null,
        ),
        if (_open == s.word)
          CitationList(
            source: widget.source,
            a: targetWord,
            b: s.word,
            labels: l,
          ),
      ],
    );
  }
}

/// Citations of an attested pair.
class CitationList extends StatelessWidget {
  final RhymeSource source;
  final String a, b;
  final RhymeEditorLabels labels;
  const CitationList({
    super.key,
    required this.source,
    required this.a,
    required this.b,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FutureBuilder<List<Citation>>(
      future: source.citations(a, b),
      builder: (context, snap) {
        final list = snap.data;
        if (list == null) return const LinearProgressIndicator();
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(labels.noCitations, style: t.bodySmall),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in list)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.lineA, style: t.bodyMedium),
                    Text(c.lineB, style: t.bodyMedium),
                    Text(
                      '${c.author}, ${c.work}${c.year != null ? ' (${c.year})' : ''}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
