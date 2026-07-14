import 'package:flutter/material.dart';

class DecorativeWrapper extends StatelessWidget {
  const DecorativeWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: child,
    );
  }
}

class MergeSemanticsWidget extends StatelessWidget {
  const MergeSemanticsWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(child: child);
  }
}

class BlockSemanticsWidget extends StatelessWidget {
  const BlockSemanticsWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(child: child);
  }
}
