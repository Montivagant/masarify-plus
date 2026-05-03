import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/shared/widgets/backgrounds/gradient_background.dart';

void main() {
  testWidgets('GradientBackground builds in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const GradientBackground(child: SizedBox.expand()),
      ),
    );
    expect(find.byType(GradientBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GradientBackground builds in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const GradientBackground(child: SizedBox.expand()),
      ),
    );
    expect(find.byType(GradientBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
