import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../state/providers.dart';

Future<String?> askText(
  BuildContext context, {
  required String title,
  required String ok,
  required String cancel,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _TextDialog(title: title, ok: ok, cancel: cancel, initial: initial),
);

/// Owns its controller so it is disposed only after the closing animation.
class _TextDialog extends StatefulWidget {
  final String title, ok, cancel, initial;
  const _TextDialog({
    required this.title,
    required this.ok,
    required this.cancel,
    required this.initial,
  });

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _c,
      autofocus: true,
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _c.text),
        child: Text(widget.ok),
      ),
    ],
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String text,
  required String ok,
  required String cancel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ok),
          ),
        ],
      ),
    ) ??
    false;

/// Shares a text file through the system sheet.
Future<void> shareFile(String name, String content) async {
  final f = File('${(await exportDir()).path}/$name');
  await f.writeAsString(content);
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
}
