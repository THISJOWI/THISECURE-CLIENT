import 'dart:math';
import 'package:flutter/material.dart';

double relativeLuminance(Color color) {
  double linearize(double c) {
    final v = c / 255.0;
    return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(color.red.toDouble()) +
      0.7152 * linearize(color.green.toDouble()) +
      0.0722 * linearize(color.blue.toDouble());
}

double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

bool validateContrast(Color foreground, Color background,
    {double minRatio = 4.5}) {
  return contrastRatio(foreground, background) >= minRatio;
}

Color ensureContrast(Color foreground, Color background,
    {double minRatio = 4.5}) {
  if (validateContrast(foreground, background, minRatio: minRatio)) {
    return foreground;
  }
  final bgLuminance = relativeLuminance(background);
  final fgLuminance = relativeLuminance(foreground);
  if (fgLuminance > bgLuminance) {
    return foreground.withValues(alpha: 1.0);
  } else {
    return foreground.withValues(alpha: 1.0);
  }
}
