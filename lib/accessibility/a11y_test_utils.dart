import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void semanticsExpectButton(WidgetTester tester,
    {required String label}) {
  expect(
    find.bySemanticsLabel(RegExp(RegExp.escape(label))),
    findsOneWidget,
    reason: 'Expected button with semantics label "$label"',
  );
}

void semanticsExpectTextField(WidgetTester tester,
    {required String label}) {
  expect(
    find.bySemanticsLabel(RegExp(RegExp.escape(label))),
    findsWidgets,
    reason: 'Expected text field with semantics label "$label"',
  );
}

void semanticsExpectHeading(WidgetTester tester,
    {required String label}) {
  expect(
    find.bySemanticsLabel(RegExp(RegExp.escape(label))),
    findsWidgets,
    reason: 'Expected heading with semantics label "$label"',
  );
}

double _relativeLuminance(Color color) {
  double linearize(double c) {
    final v = c / 255.0;
    return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(color.red.toDouble()) +
      0.7152 * linearize(color.green.toDouble()) +
      0.0722 * linearize(color.blue.toDouble());
}

void expectContrastRatio(Color foreground, Color background,
    {double minRatio = 4.5}) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  final ratio = (l1 + 0.05) / (l2 + 0.05);
  final finalRatio = ratio >= 1 ? ratio : 1 / ratio;

  expect(
    finalRatio >= minRatio,
    isTrue,
    reason:
        'Contrast ratio ${finalRatio.toStringAsFixed(2)} is below minimum $minRatio for $foreground on $background',
  );
}
