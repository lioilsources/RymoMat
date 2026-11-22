import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_editor/rymo_editor.dart';
import 'package:rymomat/main.dart';
import 'package:rymomat/state/providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('write a poem and get rhymes from the bundled pack', (t) async {
    await t.pumpWidget(const ProviderScope(child: RymoMatApp()));
    await t.pumpAndSettle();

    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    await t.enterText(
      find.byType(TextField).last,
      'Zkouška ${Random().nextInt(1 << 20)}',
    );
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();

    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();

    // Wait for the pack to be extracted and the engine to start.
    final boot = Stopwatch()..start();
    for (
      var i = 0;
      i < 1800 &&
          find.byKey(const Key('rhyme-bar-syllables')).evaluate().isEmpty;
      i++
    ) {
      await t.pump(const Duration(milliseconds: 100));
    }
    debugPrint('PACK_READY_MS=${boot.elapsedMilliseconds}');
    expect(find.byKey(const Key('rhyme-bar-syllables')), findsOneWidget);

    final field = find.descendant(
      of: find.byType(RhymeTextField),
      matching: find.byType(TextField),
    );
    await t.enterText(
      field,
      'byl pozdní večer první máj\nkde borový zaváněl h',
    );
    await t.pump(const Duration(milliseconds: 300));
    for (
      var i = 0;
      i < 50 && find.byKey(const ValueKey('chip-háj')).evaluate().isEmpty;
      i++
    ) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('chip-háj')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('chip-háj')));
    await t.pump();
    final tf = t.widget<TextField>(field);
    expect(
      tf.controller!.text,
      'byl pozdní večer první máj\nkde borový zaváněl háj',
    );

    // Latency of suggest on this device through the engine isolate.
    final ctx = t.element(find.byType(Scaffold).last);
    final engine = await ProviderScope.containerOf(
      ctx,
    ).read(engineProvider.future);
    final words = [
      'láska',
      'voda',
      'noc',
      'srdce',
      'máj',
      'den',
      'sen',
      'hvězda',
      'cesta',
      'ticho',
    ];
    final rnd = Random(1);
    final us = <int>[];
    for (var i = 0; i < 200; i++) {
      final sw = Stopwatch()..start();
      await engine.suggest(
        SuggestQuery(words[rnd.nextInt(words.length)], limit: 12),
      );
      us.add(sw.elapsedMicroseconds);
    }
    us.sort();
    final p95 = us[(us.length * 0.95).floor()] / 1000;
    debugPrint('SUGGEST_P95_MS=$p95 P50_MS=${us[us.length ~/ 2] / 1000}');
    expect(p95, lessThan(30));
    await t.pageBack();
    await t.pumpAndSettle();
  });
}
