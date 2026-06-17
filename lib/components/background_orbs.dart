import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundOrbs extends StatelessWidget {
  final Widget child;

  const BackgroundOrbs({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
      children: [
        // Ambient Background Gradients
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), // Blueish
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), // Yellowish/Gold
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15), // Purple
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Blur effect ensuring content is readable but background is ambient
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),

        // Main Content
        Positioned.fill(child: child),
      ],
    ),
    );
  }
}
