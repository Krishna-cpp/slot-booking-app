import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_card.dart';
import '../widgets/empty_state.dart';

/// Screen 3: everything the user has booked, newest day first, with the
/// option to cancel. Cancelling removes the booking, which immediately
/// frees that slot again on the booking screen.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  /// Asks "are you sure?" before deleting, then cancels.
  ///
  /// Static because it needs no instance data - it is just a helper.
  static Future<void> _confirmCancel(
    BuildContext context,
    Booking booking,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: kInkBorderSide,
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Cancel this booking?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${booking.roomName}\n'
          '${formatFullDate(booking.date)}\n'
          '${booking.slotLabel}\n\n'
          'The slot becomes available for everyone again.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Keep it',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cancel booking',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    // The dialog is closed now, so `context` may be gone - check first.
    if (shouldCancel != true || !context.mounted) return;

    await context.read<BookingService>().cancel(booking.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking cancelled. The slot is free.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BookingService>();
    final upcoming = service.upcomingBookings();
    final past = service.pastBookings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          // Only offer "clear all" when there is something to clear.
          if (service.bookings.isNotEmpty)
            IconButton(
              tooltip: 'Clear all bookings',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(context),
            ),
        ],
      ),
      body: service.bookings.isEmpty
          // Nothing booked yet -> friendly empty state instead of a blank page.
          ? const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No bookings yet',
              message:
                  'Go to Rooms, pick a space and grab a slot. It will show '
                  'up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'UPCOMING',
                    count: upcoming.length,
                  ),
                  const SizedBox(height: 12),
                  ...upcoming.map(
                    (booking) => BookingCard(
                      booking: booking,
                      onCancel: () => _confirmCancel(context, booking),
                    ),
                  ),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SectionHeader(title: 'PAST', count: past.length),
                  const SizedBox(height: 12),
                  ...past.map(
                    (booking) => BookingCard(
                      booking: booking,
                      isPast: true,
                      onCancel: () {}, // never shown for past bookings
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// Deletes every booking after one confirmation.
  static Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear all bookings?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('This removes every booking on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Keep them',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Clear all',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<BookingService>().clearAll();
  }
}

/// 'UPCOMING  (2)' style heading with a yellow counter chip.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent,
            border: Border.all(color: AppColors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
