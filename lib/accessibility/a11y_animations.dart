import 'package:flutter/material.dart';

class AnimatableBuilder extends StatelessWidget {
  const AnimatableBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.instantIfReducedMotion = true,
  });

  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final bool instantIfReducedMotion;

  @override
  Widget build(BuildContext context) {
    if (instantIfReducedMotion &&
        MediaQuery.of(context).disableAnimations) {
      return AnimatedBuilder(
        animation: kAlwaysCompleteAnimation,
        builder: builder,
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: builder,
    );
  }
}

class SkippableAnimationController {
  SkippableAnimationController(this.controller, this.context);

  final AnimationController controller;
  final BuildContext context;

  bool get isReducedMotion => MediaQuery.of(context).disableAnimations;

  void forward() {
    if (isReducedMotion) {
      controller.value = 1.0;
    } else {
      controller.forward();
    }
  }

  void reverse() {
    if (isReducedMotion) {
      controller.value = 0.0;
    } else {
      controller.reverse();
    }
  }

  void repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
  }) {
    if (isReducedMotion) {
      controller.value = max ?? 1.0;
    } else {
      controller.repeat(min: min, max: max, reverse: reverse, period: period);
    }
  }

  void reset() => controller.reset();

  void dispose() => controller.dispose();
}
