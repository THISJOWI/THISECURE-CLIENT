import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlass {
  static Widget wrap(Widget child, BuildContext context, {
    double borderRadius = 16,
    double blurSigma = 20,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? boxShadow,
    bool excludeSemantics = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget result = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
    if (excludeSemantics) {
      result = ExcludeSemantics(child: result);
    }
    return result;
  }
}
