import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// A rhyme pack installed on the device.
class InstalledPack {
  final String lang;
  final int version;
  final String path;
  final int size;
  final List<Map<String, dynamic>> sources;
  const InstalledPack(
    this.lang,
    this.version,
    this.path,
    this.size,
    this.sources,
  );
}

/// Extracts the bundled pack zip (`assets/packs/<lang>-v<N>.zip`) into
/// `<support>/packs/<lang>/` on first launch or when the bundled version
/// changes. The `.rpack` hash is checked against `manifest.json`.
class PackInstaller {
  final Directory root;
  final AssetBundle bundle;
  PackInstaller(this.root, {AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;

  Future<InstalledPack> ensureBundled(String asset) async {
    final lang = p.basename(asset).split('-').first;
    final dir = Directory(p.join(root.path, 'packs', lang));
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    final bundledVersion = _versionOf(asset);
    if (manifestFile.existsSync()) {
      final m = jsonDecode(manifestFile.readAsStringSync()) as Map;
      final pack = File(p.join(dir.path, '$lang.rpack'));
      if (m['version'] == bundledVersion && pack.existsSync()) {
        return _installed(lang, m, pack);
      }
    }
    final data = await bundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final dirPath = dir.path;
    await Isolate.run(() => _extract(bytes, dirPath, lang));
    final m = jsonDecode(manifestFile.readAsStringSync()) as Map;
    return _installed(lang, m, File(p.join(dir.path, '$lang.rpack')));
  }

  static int? _versionOf(String asset) =>
      int.tryParse(RegExp(r'-v(\d+)\.zip$').firstMatch(asset)?.group(1) ?? '');

  static InstalledPack _installed(String lang, Map m, File pack) =>
      InstalledPack(lang, m['version'] as int, pack.path, pack.lengthSync(), [
        for (final s in (m['sources'] as List? ?? const []))
          Map<String, dynamic>.from(s as Map),
      ]);

  static void _extract(Uint8List bytes, String dirPath, String lang) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final tmp = Directory('$dirPath.tmp');
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    tmp.createSync(recursive: true);
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final name = p.basename(f.name);
      File(p.join(tmp.path, name)).writeAsBytesSync(f.content);
    }
    final m =
        jsonDecode(File(p.join(tmp.path, 'manifest.json')).readAsStringSync())
            as Map;
    final pack = File(p.join(tmp.path, '$lang.rpack'));
    final sum = sha256.convert(pack.readAsBytesSync()).toString();
    if (sum != m['sha256']) {
      tmp.deleteSync(recursive: true);
      throw StateError('pack checksum mismatch');
    }
    final dir = Directory(dirPath);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    tmp.renameSync(dirPath);
  }
}
