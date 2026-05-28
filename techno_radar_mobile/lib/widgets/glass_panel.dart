import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
