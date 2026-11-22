import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rymomat/screens/common.dart';

void main() {
  // Regression: the controller was disposed while the dialog was still
  // animating out ("TextEditingController was used after being disposed").
  testWidgets('askText returns the text and closes cleanly', (t) async {
    String? result;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await askText(
              context,
              title: 't',
              ok: 'ok',
              cancel: 'x',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Máj');
    await t.tap(find.text('ok'));
    await t.pumpAndSettle();
    expect(result, 'Máj');
    expect(t.takeException(), isNull);
  });
}
