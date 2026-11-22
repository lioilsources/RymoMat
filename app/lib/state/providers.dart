import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_editor/rymo_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../packs/pack_installer.dart';
import '../storage/notebook_repository.dart';

/// Bundled packs; `run/rymo release cs` produces the zip.
const bundledPacks = ['assets/packs/cs-v1.zip'];

final installedPackProvider = FutureProvider<InstalledPack>((ref) async {
  final support = await getApplicationSupportDirectory();
  return PackInstaller(support).ensureBundled(bundledPacks.first);
});

/// The rhyme engine on its long-lived isolate.
final engineProvider = FutureProvider<RhymeEngine>((ref) async {
  final pack = await ref.watch(installedPackProvider.future);
  final engine = await RhymeEngine.open(pack.path);
  ref.onDispose(engine.close);
  return engine;
});

final rhymeSourceProvider = FutureProvider<RhymeSource>(
  (ref) async => EngineRhymeSource(await ref.watch(engineProvider.future)),
);

final repositoryProvider = FutureProvider<NotebookRepository>(
  (ref) async => NotebookRepository(await getApplicationDocumentsDirectory()),
);

class NotebooksNotifier extends AsyncNotifier<List<NotebookEntry>> {
  Future<NotebookRepository> get _repo => ref.read(repositoryProvider.future);

  @override
  Future<List<NotebookEntry>> build() async =>
      (await ref.watch(repositoryProvider.future)).list();

  /// Current notebook by slug (usable without a widget ref).
  Notebook? notebook(String slug) =>
      state.value?.where((e) => e.slug == slug).firstOrNull?.notebook;

  Future<NotebookEntry> create(String title) async {
    final e = await (await _repo).create(Notebook(title: title));
    ref.invalidateSelf();
    return e;
  }

  Future<void> save(String slug, Notebook nb) async {
    await (await _repo).save(slug, nb);
    final list = state.value;
    if (list != null) {
      state = AsyncData([
        for (final e in list) e.slug == slug ? NotebookEntry(slug, nb) : e,
      ]);
    }
  }

  Future<void> delete(String slug) async {
    await (await _repo).delete(slug);
    ref.invalidateSelf();
  }

  Future<NotebookEntry> import(String fileName, String content) async {
    final e = await (await _repo).import(fileName, content);
    ref.invalidateSelf();
    return e;
  }
}

final notebooksProvider =
    AsyncNotifierProvider<NotebooksNotifier, List<NotebookEntry>>(
      NotebooksNotifier.new,
    );

/// Writing preferences (plan §9.1): both off by default.
class WritingSettings {
  final bool capitalizeLines;
  final bool autocorrect;
  const WritingSettings({
    this.capitalizeLines = false,
    this.autocorrect = false,
  });
}

class SettingsNotifier extends AsyncNotifier<WritingSettings> {
  static const _cap = 'capitalizeLines', _auto = 'autocorrect';

  @override
  Future<WritingSettings> build() async {
    final p = await SharedPreferences.getInstance();
    return WritingSettings(
      capitalizeLines: p.getBool(_cap) ?? false,
      autocorrect: p.getBool(_auto) ?? false,
    );
  }

  Future<void> set({bool? capitalizeLines, bool? autocorrect}) async {
    final p = await SharedPreferences.getInstance();
    final cur = state.value ?? const WritingSettings();
    final next = WritingSettings(
      capitalizeLines: capitalizeLines ?? cur.capitalizeLines,
      autocorrect: autocorrect ?? cur.autocorrect,
    );
    await p.setBool(_cap, next.capitalizeLines);
    await p.setBool(_auto, next.autocorrect);
    state = AsyncData(next);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, WritingSettings>(
      SettingsNotifier.new,
    );

/// Temporary directory for shared exports.
Future<Directory> exportDir() async {
  final d = Directory('${(await getTemporaryDirectory()).path}/export');
  d.createSync(recursive: true);
  return d;
}
