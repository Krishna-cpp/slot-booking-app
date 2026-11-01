// Unit tests for the booking LOGIC (no widgets involved).
//
// These are the most valuable tests in the project: they prove that the rule
// "one room + one date + one hour = one booking" can never be broken.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slot_booking_app/models/booking.dart';
import 'package:slot_booking_app/services/booking_service.dart';

void main() {
  // A fixed date so the tests never depend on "today".
  const dateKey = '2026-12-01';
  const otherDateKey = '2026-12-02';
  const roomId = 'study_a';

  late BookingService service;

  setUp(() async {
    // shared_preferences normally talks to the real device. In tests we give
    // it a fake in-memory store instead, so nothing is written to disk.
    SharedPreferences.setMockInitialValues({});
    service = BookingService();
    await service.load();
  });

  group('booking a slot', () {
    test('a fresh service starts empty', () {
      expect(service.bookings, isEmpty);
      expect(service.isLoaded, isTrue);
    });

    test('booking a free slot succeeds', () async {
      final result = await service.book(
        roomId: roomId,
        dateKey: dateKey,
        slotId: '09:00',
      );

      expect(result, BookingResult.success);
      expect(service.bookings, hasLength(1));
      expect(service.bookings.first.roomId, roomId);
      expect(service.bookings.first.slotId, '09:00');
    });

    test('bookings are sorted by date then time', () async {
      await service.book(
        roomId: roomId,
        dateKey: otherDateKey,
        slotId: '09:00',
      );
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '14:00');
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '08:00');

      expect(
        service.bookings.map((b) => '${b.dateKey} ${b.slotId}'),
        ['2026-12-01 08:00', '2026-12-01 14:00', '2026-12-02 09:00'],
      );
    });
  });

  group('double-booking prevention', () {
    test('booking the same room + date + slot twice is rejected', () async {
      final first = await service.book(
        roomId: roomId,
        dateKey: dateKey,
        slotId: '09:00',
      );
      final second = await service.book(
        roomId: roomId,
        dateKey: dateKey,
        slotId: '09:00',
      );

      expect(first, BookingResult.success);
      expect(second, BookingResult.alreadyBooked);
      // The important part: the rejected attempt added nothing.
      expect(service.bookings, hasLength(1));
    });

    test('the SAME slot on a DIFFERENT date is still free', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      final result = await service.book(
        roomId: roomId,
        dateKey: otherDateKey,
        slotId: '09:00',
      );

      expect(result, BookingResult.success);
      expect(service.bookings, hasLength(2));
    });

    test('the SAME slot in a DIFFERENT room is still free', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      final result = await service.book(
        roomId: 'badminton',
        dateKey: dateKey,
        slotId: '09:00',
      );

      expect(result, BookingResult.success);
      expect(service.bookings, hasLength(2));
    });

    test('isSlotBooked reports taken slots only', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');

      expect(
        service.isSlotBooked(
          roomId: roomId,
          dateKey: dateKey,
          slotId: '09:00',
        ),
        isTrue,
      );
      expect(
        service.isSlotBooked(
          roomId: roomId,
          dateKey: dateKey,
          slotId: '10:00',
        ),
        isFalse,
      );
      expect(
        service.isSlotBooked(
          roomId: 'seminar',
          dateKey: dateKey,
          slotId: '09:00',
        ),
        isFalse,
      );
    });

    test('bookedSlotIds returns every taken hour for that room + day',
        () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '15:00');
      // Noise that must NOT show up in the result:
      await service.book(roomId: roomId, dateKey: otherDateKey, slotId: '11:00');
      await service.book(roomId: 'seminar', dateKey: dateKey, slotId: '12:00');

      final taken = service.bookedSlotIds(roomId: roomId, dateKey: dateKey);

      expect(taken, {'09:00', '15:00'});
    });
  });

  group('cancelling', () {
    test('cancelling frees the slot so it can be booked again', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      final bookingId = service.bookings.first.id;

      final removed = await service.cancel(bookingId);

      expect(removed, isTrue);
      expect(service.bookings, isEmpty);
      expect(
        service.isSlotBooked(
          roomId: roomId,
          dateKey: dateKey,
          slotId: '09:00',
        ),
        isFalse,
      );

      // And the slot really is bookable again.
      final rebook = await service.book(
        roomId: roomId,
        dateKey: dateKey,
        slotId: '09:00',
      );
      expect(rebook, BookingResult.success);
    });

    test('cancelling an unknown id changes nothing', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');

      final removed = await service.cancel('does-not-exist');

      expect(removed, isFalse);
      expect(service.bookings, hasLength(1));
    });

    test('cancelling removes only the one booking', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '10:00');
      final idToCancel = service.bookings.first.id;

      await service.cancel(idToCancel);

      expect(service.bookings, hasLength(1));
      expect(service.bookings.first.slotId, '10:00');
    });
  });

  group('persistence', () {
    test('bookings survive a restart (a new service reading the same store)',
        () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');

      // Simulate restarting the app: build a brand-new service and load().
      final restarted = BookingService();
      await restarted.load();

      expect(restarted.bookings, hasLength(1));
      expect(restarted.bookings.first.slotId, '09:00');
      expect(restarted.bookings.first.dateKey, dateKey);
      // The reloaded data must still block a double booking.
      expect(
        await restarted.book(
          roomId: roomId,
          dateKey: dateKey,
          slotId: '09:00',
        ),
        BookingResult.alreadyBooked,
      );
    });

    test('corrupt stored data does not crash the app', () async {
      SharedPreferences.setMockInitialValues({
        BookingService.storageKey: 'this is not json',
      });

      final broken = BookingService();
      await broken.load();

      expect(broken.bookings, isEmpty);
      expect(broken.isLoaded, isTrue);
    });

    test('clearAll empties the store', () async {
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      await service.clearAll();

      final restarted = BookingService();
      await restarted.load();

      expect(restarted.bookings, isEmpty);
    });
  });

  group('listeners (the Provider part)', () {
    test('booking and cancelling notify listeners', () async {
      var notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      expect(notifyCount, 1);

      // A rejected booking must NOT trigger a rebuild - nothing changed.
      await service.book(roomId: roomId, dateKey: dateKey, slotId: '09:00');
      expect(notifyCount, 1);

      await service.cancel(service.bookings.first.id);
      expect(notifyCount, 2);
    });
  });

  group('upcoming vs past', () {
    test('splits bookings around the given "today"', () async {
      final today = DateTime(2026, 12, 1);
      await service.book(roomId: roomId, dateKey: '2026-11-28', slotId: '09:00');
      await service.book(roomId: roomId, dateKey: '2026-12-01', slotId: '10:00');
      await service.book(roomId: roomId, dateKey: '2026-12-05', slotId: '11:00');

      expect(service.pastBookings(from: today).map((b) => b.dateKey),
          ['2026-11-28']);
      expect(
        service.upcomingBookings(from: today).map((b) => b.dateKey),
        ['2026-12-01', '2026-12-05'],
      );
      // Today counts as upcoming, so the room shows 2.
      expect(service.upcomingCountForRoom(roomId, from: today), 2);
    });
  });

  group('date helpers', () {
    test('dateKeyOf pads month and day to two digits', () {
      expect(dateKeyOf(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dateKeyOf(DateTime(2026, 11, 30)), '2026-11-30');
    });

    test('parseDateKey is the exact opposite of dateKeyOf', () {
      final date = DateTime(2026, 7, 4);
      expect(parseDateKey(dateKeyOf(date)), date);
    });

    test('formatRelativeDate names today and tomorrow', () {
      final today = DateTime(2026, 12, 1);
      expect(formatRelativeDate(today, now: today), 'Today');
      expect(
        formatRelativeDate(today.add(const Duration(days: 1)), now: today),
        'Tomorrow',
      );
      expect(
        formatRelativeDate(today.add(const Duration(days: 9)), now: today),
        '10 Dec',
      );
    });

    test('formatFullDate is readable', () {
      expect(formatFullDate(DateTime(2026, 11, 1)), 'Sun, 01 Nov 2026');
    });
  });
}
