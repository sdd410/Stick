import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/app.dart';

void main() {
  testWidgets('StickApp shows Stick on the dark background', (tester) async {
    await tester.pumpWidget(const StickApp());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final bg = scaffold.backgroundColor ??
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(bg, const Color(0xFF0B0B12));
    expect(find.text('Stick'), findsOneWidget);
  });
}
