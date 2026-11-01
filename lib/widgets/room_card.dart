import 'package:flutter/material.dart';

import '../models/room.dart';
import '../theme/app_theme.dart';

/// A tappable card on the Home screen representing one bookable room.
///
/// It receives the data it shows (`room`, `upcomingCount`) and what to do when
/// tapped (`onTap`) as constructor parameters. A widget that only receives
/// data and draws it is a StatelessWidget - it has no state of its own.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.upcomingCount,
    required this.onTap,
  });

  final Room room;

  /// How many upcoming bookings this room has (shown as a small badge).
  final int upcomingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.fromBorderSide(kInkBorderSide),
          borderRadius: BorderRadius.circular(18),
          boxShadow: inkShadow(),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Yellow icon square.
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      border: Border.fromBorderSide(kInkBorderSide),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(room.icon, color: AppColors.ink, size: 26),
                  ),
                  const SizedBox(width: 14),

                  // Expanded makes this column take all the leftover width,
                  // which pushes the arrow to the far right.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _Pill(
                              icon: Icons.person_outline,
                              text: 'Seats ${room.capacity}',
                            ),
                            // Collection-if: only add this widget when there
                            // actually are bookings.
                            if (upcomingCount > 0) ...[
                              const SizedBox(width: 8),
                              _Pill(
                                icon: Icons.event_available_outlined,
                                text: '$upcomingCount booked',
                                filled: true,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny rounded label. The leading underscore makes it private to this
/// file, because only RoomCard needs it.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.filled = false});

  final IconData icon;
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.accent : AppColors.background,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.ink),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
