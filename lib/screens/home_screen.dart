import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/room_card.dart';
import 'booking_screen.dart';

/// Screen 1: the list of bookable rooms.
///
/// Tapping a card pushes the [BookingScreen] for that room.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `context.watch` subscribes this widget to the BookingService.
    // Whenever the service calls notifyListeners(), build() runs again, so
    // the "2 booked" badges update the moment a booking is made elsewhere.
    final service = context.watch<BookingService>();

    return Scaffold(
      body: SafeArea(
        // SafeArea keeps content away from notches and system bars.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const _HomeHeader(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CHOOSE A SPACE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '${kRooms.length} available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Build one RoomCard per room. `.map(...).toList()` plus the
            // spread operator `...` drops the resulting widgets straight
            // into this children list.
            ...kRooms.map(
              (room) => RoomCard(
                room: room,
                upcomingCount: service.upcomingCountForRoom(room.id),
                onTap: () {
                  // Navigator.push adds a new screen on top of the stack;
                  // the back button pops it off again.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(room: room),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The big yellow banner at the top of the Home screen.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final upcoming = context.watch<BookingService>().upcomingBookings();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        border: Border.fromBorderSide(kInkBorderSide),
        borderRadius: BorderRadius.circular(22),
        boxShadow: inkShadow(offset: 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SLOT BOOKING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book a room\nin seconds.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              upcoming.isEmpty
                  ? 'No upcoming bookings'
                  : '${upcoming.length} upcoming booking'
                      // A tiny plural helper, inline.
                      '${upcoming.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
