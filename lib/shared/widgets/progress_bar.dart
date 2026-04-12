import 'package:flutter/material.dart';

class LernFuchsProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const LernFuchsProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final br = borderRadius ?? BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: br,
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
