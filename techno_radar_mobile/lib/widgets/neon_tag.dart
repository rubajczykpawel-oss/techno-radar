import 'package:flutter/material.dart';

Widget neonTag({
  required String text,
  IconData? icon,
  Color color = Colors.deepPurpleAccent,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: color.withValues(alpha: 0.55),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 15, color: color),
        if (icon != null) const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}