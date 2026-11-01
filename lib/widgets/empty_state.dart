import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown when a list has nothing in it (e.g. no bookings yet).
///
/// Empty states are easy to forget, but an app that shows a blank white
/// screen feels broken, so it is worth the few extra lines.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: AppColors.accent,
                border: Border.fromBorderSide(kInkBorderSide),
                borderRadius: BorderRadius.circular(20),
                boxShadow: inkShadow(),
              ),
              child: Icon(icon, size: 36, color: AppColors.ink),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
