import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';
import 'notebook_screen.dart';

const importTypes = [
  XTypeGroup(
    label: 'YAML / TXT',
    extensions: ['yaml', 'yml', 'txt'],
    uniformTypeIdentifiers: ['public.text', 'public.data'],
    mimeTypes: ['text/*', 'application/yaml', 'application/x-yaml'],
  ),
];

class NotebooksScreen extends ConsumerWidget {
  const NotebooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final notebooks = ref.watch(notebooksProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabNotebooks),
        actions: [
          IconButton(
            tooltip: l.importFile,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => _import(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.newNotebook),
        onPressed: () async {
          final title = await askText(
            context,
            title: l.notebookTitle,
            ok: l.create,
            cancel: l.cancel,
          );
          if (title == null || title.trim().isEmpty || !context.mounted) return;
          final e = await ref
              .read(notebooksProvider.notifier)
              .create(title.trim());
          if (context.mounted) _open(context, e.slug);
        },
      ),
      body: notebooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.notebooksEmpty, textAlign: TextAlign.center),
                ),
              )
            : ListView(
                children: [
                  for (final e in list)
                    ListTile(
                      title: Text(e.notebook.title),
                      subtitle: Text(l.poemsCount(e.notebook.poems.length)),
                      onTap: () => _open(context, e.slug),
                    ),
                ],
              ),
      ),
    );
  }

  void _open(BuildContext context, String slug) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => NotebookScreen(slug: slug)));

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final file = await openFile(acceptedTypeGroups: importTypes);
    if (file == null) return;
    try {
      final e = await ref
          .read(notebooksProvider.notifier)
          .import(file.name, await file.readAsString());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.importDone(e.notebook.poems.length))),
      );
    } on Exception catch (err) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.importFailed('$err'))));
    }
  }
}
