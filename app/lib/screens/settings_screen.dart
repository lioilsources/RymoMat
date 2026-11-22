import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings =
        ref.watch(settingsProvider).value ?? const WritingSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final pack = ref.watch(installedPackProvider);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListView(
        children: [
          _header(context, l.settingsPacks),
          pack.when(
            loading: () => ListTile(title: Text(l.packLoading)),
            error: (e, _) => ListTile(title: Text(l.packError('$e'))),
            data: (p) => ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l.langCs),
              subtitle: Text(
                l.packInfo(
                  p.lang,
                  '${p.version}',
                  (p.size / 1e6).toStringAsFixed(0),
                ),
              ),
            ),
          ),
          _header(context, l.settingsWriting),
          SwitchListTile(
            title: Text(l.settingsCapitalize),
            value: settings.capitalizeLines,
            onChanged: (v) => notifier.set(capitalizeLines: v),
          ),
          SwitchListTile(
            title: Text(l.settingsAutocorrect),
            value: settings.autocorrect,
            onChanged: (v) => notifier.set(autocorrect: v),
          ),
          _header(context, l.settingsAbout),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.aboutIntro),
                const SizedBox(height: 12),
                Text(l.aboutLicense),
                const SizedBox(height: 8),
                for (final s
                    in pack.value?.sources ?? const <Map<String, dynamic>>[])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s['license']}', style: t.labelLarge),
                        Text('${s['attribution']}'.trim(), style: t.bodySmall),
                        Text('${s['url']}', style: t.bodySmall),
                      ],
                    ),
                  ),
                Text(l.aboutCitations, style: t.bodySmall),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
