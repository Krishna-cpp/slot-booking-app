import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The one and only button style in this app: a bold block with a hard shadow.
///
/// Instead of styling an ElevatedButton over and over, we wrap the look in a
/// small reusable widget. Passing `onPressed: null` automatically renders the
/// disabled (grey, flat) version - that is the standard Flutter convention.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.accent,
    this.foreground = AppColors.ink,
    this.expand = true,
  });

  final String label;

  /// `null` means the button is disabled.
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color foreground;

  /// Whether the button stretches to the full available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? color : AppColors.background,
        border: Border.fromBorderSide(
          enabled
              ? kInkBorderSide
              : const BorderSide(color: AppColors.muted, width: 2),
        ),
        borderRadius: BorderRadius.circular(14),
        // Disabled buttons lose the shadow so they visibly sink into the page.
        boxShadow: enabled ? inkShadow() : null,
      ),
      child: Material(
        // Material + InkWell give us the ripple animation on tap.
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: enabled ? foreground : AppColors.muted,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: enabled ? foreground : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // The hard shadow is drawn outside the box, so we reserve room for it.
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: button,
    );
  }
}
