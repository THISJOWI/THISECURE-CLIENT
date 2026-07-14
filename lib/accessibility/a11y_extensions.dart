import 'package:flutter/material.dart';

extension A11yBuildContext on BuildContext {
  bool get isScreenReaderActive => MediaQuery.of(this).accessibleNavigation;

  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  bool get highContrast => MediaQuery.of(this).highContrast;

  bool get boldText => MediaQuery.of(this).boldText;

  double get textScaleFactor => MediaQuery.of(this).textScaleFactor;
}
