import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class MusicBackground extends StatelessWidget {
  final Widget child;

  const MusicBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AppAssets.electronicBackground,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.82),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}