import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rymo_core/rymo_core.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../storage/notebook_repository.dart';
import 'common.dart';
import 'editor_screen.dart';

class NotebookScreen extends ConsumerWidget {
  final String slug;
  const NotebookScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entry = ref
        .watch(notebooksProvider)
        .value
        ?.where((e) => e.slug == slug)
        .firstOrNull;
    if (entry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final nb = entry.notebook;
    final notifier = ref.read(notebooksProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(nb.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, ref, entry, v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'share', child: Text(l.exportNotebook)),
              PopupMenuItem(value: 'rename', child: Text(l.rename)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit),
        label: Text(l.newPoem),
        onPressed: () async {
          final poems = [...nb.poems, const NotebookPoem(title: '')];
          await notifier.save(slug, nb.copyWith(poems: poems));
          if (context.mounted) _edit(context, poems.length - 1);
        },
      ),
      body: ListView(
        children: [
          for (var i = 0; i < nb.poems.length; i++)
            ListTile(
              title: Text(
                nb.poems[i].title.isEmpty ? l.untitledPoem : nb.poems[i].title,
              ),
              subtitle: Text(
                nb.poems[i].text.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _edit(context, i),
              onLongPress: () async {
                final p = nb.poems[i];
                final ok = await confirm(
                  context,
                  text: l.deletePoemConfirm(
                    p.title.isEmpty ? l.untitledPoem : p.title,
                  ),
                  ok: l.delete,
                  cancel: l.cancel,
                );
                if (!ok) return;
                await notifier.save(
                  slug,
                  nb.copyWith(poems: [...nb.poems]..removeAt(i)),
                );
              },
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, int index) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EditorScreen(slug: slug, index: index),
    ),
  );

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    NotebookEntry e,
    String action,
  ) async {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(notebooksProvider.notifier);
    switch (action) {
      case 'share':
        await shareFile('${e.slug}.yaml', e.notebook.toYaml());
      case 'rename':
        final t = await askText(
          context,
          title: l.notebookTitle,
          ok: l.rename,
          cancel: l.cancel,
          initial: e.notebook.title,
        );
        if (t != null && t.trim().isNotEmpty) {
          await notifier.save(e.slug, e.notebook.copyWith(title: t.trim()));
        }
      case 'delete':
        final ok = await confirm(
          context,
          text: l.deleteNotebookConfirm(e.notebook.title),
          ok: l.delete,
          cancel: l.cancel,
        );
        if (!ok) return;
        await notifier.delete(e.slug);
        if (context.mounted) Navigator.of(context).pop();
    }
  }
}
