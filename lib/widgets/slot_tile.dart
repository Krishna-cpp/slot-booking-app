import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The four possible looks of a time-slot tile.
/// Using an enum keeps the styling logic readable (one `switch` below)
/// instead of a tangle of booleans.
enum SlotState {
  /// Free - the user can tap it.
  available,

  /// Free and currently picked by the user.
  selected,

  /// Already booked by someone, so it must not be tappable.
  booked,

  /// The hour is in the past today, so booking it makes no sense.
  past,
}

/// One tile in the time-slot grid.
class SlotTile extends StatelessWidget {
  const SlotTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final SlotState state;

  /// Null when the slot cannot be chosen (booked or past).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // A `switch` expression (Dart 3) returns a value per case. The compiler
    // checks that we handled every enum value, so adding a new SlotState
    // later would give us an error here instead of a silent bug.
    final (Color background, Color foreground, bool showShadow) =
        switch (state) {
      SlotState.selected => (AppColors.ink, AppColors.accent, true),
      SlotState.available => (AppColors.surface, AppColors.ink, true),
      SlotState.booked => (const Color(0xFFE8E4DC), AppColors.muted, false),
      SlotState.past => (AppColors.background, AppColors.muted, false),
    };

    final bool enabled = onTap != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: enabled ? AppColors.ink : AppColors.muted,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: showShadow ? inkShadow(offset: 3) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                    // A line through the text is an instant visual cue that
                    // the slot is unavailable.
                    decoration: state == SlotState.booked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.muted,
                  ),
                ),
                if (state == SlotState.booked)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'BOOKED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
