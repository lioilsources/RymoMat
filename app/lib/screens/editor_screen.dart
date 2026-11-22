import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_editor/rymo_editor.dart';

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../state/providers.dart';
import 'common.dart';

/// Poem editor: title, verse field and the rhyme bar above the keyboard.
class EditorScreen extends ConsumerStatefulWidget {
  final String slug;
  final int index;
  const EditorScreen({super.key, required this.slug, required this.index});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final TextEditingController _title;
  late final RhymeEditingController _text;
  late final NotebooksNotifier _notebooks;
  Timer? _save;
  NotebookPoem? _saved;

  @override
  void initState() {
    super.initState();
    _notebooks = ref.read(notebooksProvider.notifier);
    final poem = _poem() ?? const NotebookPoem(title: '');
    _saved = poem;
    _title = TextEditingController(text: poem.title)..addListener(_changed);
    _text = RhymeEditingController(text: poem.text)..addListener(_changed);
    ref.listenManual(rhymeSourceProvider, (_, next) {
      if (next.hasValue) _text.source = next.value;
    }, fireImmediately: true);
  }

  NotebookPoem? _poem() {
    final nb = _notebook();
    if (nb == null || widget.index >= nb.poems.length) return null;
    return nb.poems[widget.index];
  }

  Notebook? _notebook() => _notebooks.notebook(widget.slug);

  void _changed() {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 800), _persist);
  }

  Future<void> _persist() async {
    final nb = _notebook();
    if (nb == null || widget.index >= nb.poems.length) return;
    final poem = nb.poems[widget.index].copyWith(
      title: _title.text.trim(),
      text: _text.text,
    );
    if (poem == _saved) return;
    _saved = poem;
    final poems = [...nb.poems]..[widget.index] = poem;
    await _notebooks.save(widget.slug, nb.copyWith(poems: poems));
  }

  @override
  void dispose() {
    _save?.cancel();
    unawaited(_persist());
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = l.editorLabels;
    final source = ref.watch(rhymeSourceProvider);
    final settings =
        ref.watch(settingsProvider).value ?? const WritingSettings();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _title,
          decoration: InputDecoration(
            hintText: l.poemTitleHint,
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: l.exportPoem,
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              final name = _title.text.trim().isEmpty
                  ? l.untitledPoem
                  : _title.text.trim();
              shareFile('${slugify(name)}.txt', '$name\n\n${_text.text}\n');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RhymeTextField(
                  controller: _text,
                  labels: labels,
                  hintText: l.poemTextHint,
                  capitalizeLines: settings.capitalizeLines,
                  autocorrect: settings.autocorrect,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                  onRhymesFor: (w) {
                    final src = source.value;
                    if (src == null) return;
                    RhymeSheet.show(
                      context,
                      source: src,
                      target: w,
                      labels: labels,
                    );
                  },
                ),
              ),
            ),
            source.when(
              data: (src) =>
                  RhymeBar(controller: _text, labels: labels, source: src),
              loading: () => _status(context, l.packLoading),
              error: (e, _) => _status(context, l.packError('$e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(BuildContext context, String text) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: SizedBox(
      height: 48,
      child: Center(child: Text(text, overflow: TextOverflow.ellipsis)),
    ),
  );
}
