import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../theme/app_theme.dart';

/// A row on the "My Bookings" screen: one saved reservation plus a
/// cancel button.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
    this.isPast = false,
  });

  final Booking booking;

  /// Called when the user taps the bin icon. The parent screen decides what
  /// cancelling actually does - this widget just reports the tap.
  final VoidCallback onCancel;

  /// Past bookings are drawn faded and cannot be cancelled.
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final room = booking.room;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isPast ? AppColors.background : AppColors.surface,
          border: Border.all(
            color: isPast ? AppColors.muted : AppColors.ink,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isPast ? null : inkShadow(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left block: the time, on a yellow background.
              Container(
                width: 74,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isPast ? AppColors.surface : AppColors.accent,
                  border: Border.all(
                    color: isPast ? AppColors.muted : AppColors.ink,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      booking.slotId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isPast ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                    Text(
                      formatRelativeDate(booking.date),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPast ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (room != null) ...[
                          Icon(
                            room.icon,
                            size: 16,
                            color: isPast ? AppColors.muted : AppColors.ink,
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Flexible lets long room names wrap instead of
                        // overflowing off the side of the card.
                        Flexible(
                          child: Text(
                            booking.roomName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isPast ? AppColors.muted : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatFullDate(booking.date),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      booking.slotLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              // Cancel button - hidden for bookings that already happened.
              if (!isPast)
                IconButton(
                  onPressed: onCancel,
                  tooltip: 'Cancel booking',
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
