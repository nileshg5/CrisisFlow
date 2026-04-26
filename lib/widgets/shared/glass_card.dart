import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double bgOpacity;
  final double borderOpacity;
  final bool hover;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.bgOpacity = 0.03,
    this.borderOpacity = 0.12,
    this.hover = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: borderOpacity)),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 0)]
            : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
