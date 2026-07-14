import 'package:flutter/material.dart';

const double minTouchTarget = 44.0;
const double minInteractiveSpacing = 8.0;
const Duration reducedAnimationDuration = Duration(milliseconds: 1);
const double defaultTooltipFontSize = 14.0;

BoxConstraints get touchTargetConstraints =>
    const BoxConstraints(minWidth: minTouchTarget, minHeight: minTouchTarget);

EdgeInsets get touchTargetPadding =>
    const EdgeInsets.all((minTouchTarget - kMinInteractiveDimension) / 2);
