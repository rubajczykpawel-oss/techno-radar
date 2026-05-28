import 'package:flutter/material.dart';
import 'glass_panel.dart';

Widget emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  Widget? action,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: GlassPanel(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                height: 1.35,
              ),
            ),
            if (action != null) const SizedBox(height: 18),
            if (action != null) action,
          ],
        ),
      ),
    ),
  );
}
