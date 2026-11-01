// An end-to-end style widget test: it walks the whole app the way a user
// would - Rooms -> Booking -> Confirm -> My Bookings -> Cancel.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slot_booking_app/main.dart';
import 'package:slot_booking_app/models/booking.dart';
import 'package:slot_booking_app/screens/root_screen.dart';
import 'package:slot_booking_app/services/booking_service.dart';
import 'package:slot_booking_app/widgets/booking_card.dart';

void main() {
  late BookingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = BookingService();
    await service.load();
  });

  /// Boots the app shell (bottom nav + both tabs) with our test service.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<BookingService>.value(
        value: service,
        child: const MaterialApp(home: RootScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home screen lists every room', (tester) async {
    await pumpApp(tester);

    expect(find.text('Study Room A'), findsOneWidget);
    expect(find.text('Study Room B'), findsOneWidget);
    expect(find.text('Badminton Court'), findsOneWidget);
    expect(find.text('Seminar Hall'), findsOneWidget);
    expect(find.text('No upcoming bookings'), findsOneWidget);
  });

  testWidgets('book a slot end to end, then cancel it', (tester) async {
    await pumpApp(tester);

    // 1. Open a room from the home list.
    await tester.tap(find.text('Badminton Court'));
    await tester.pumpAndSettle();
    expect(find.text('1. PICK A DATE'), findsOneWidget);

    // 2. Move to tomorrow so no slot is in the past.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow'), findsOneWidget);

    // 3. Pick a slot and review it.
    await tester.tap(find.byKey(const ValueKey('slot-13:00')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REVIEW BOOKING'));
    await tester.pumpAndSettle();

    // 4. Confirm.
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();
    expect(service.bookings, hasLength(1));

    // 5. Go back to the room list, then to the My Bookings tab.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 upcoming booking'), findsOneWidget);

    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingCard), findsOneWidget);
    expect(find.text('Badminton Court'), findsOneWidget);
    expect(find.text('13:00 – 14:00'), findsOneWidget);

    // 6. Cancel it: bin icon -> confirm dialog -> gone.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this booking?'), findsOneWidget);

    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();

    expect(service.bookings, isEmpty);
    expect(find.byType(BookingCard), findsNothing);
    expect(find.text('No bookings yet'), findsOneWidget);
  });

  testWidgets('keeping a booking in the cancel dialog changes nothing',
      (tester) async {
    await service.book(
      roomId: 'seminar',
      dateKey: dateKeyOf(dateOnly(DateTime.now())),
      slotId: '09:00',
    );
    await pumpApp(tester);

    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();

    expect(service.bookings, hasLength(1));
    expect(find.byType(BookingCard), findsOneWidget);
  });

  testWidgets('saved bookings are shown after a restart', (tester) async {
    // Pretend a previous run left a booking on the device.
    SharedPreferences.setMockInitialValues({
      BookingService.storageKey:
          '[{"id":"1","roomId":"study_b","dateKey":"2099-01-01",'
              '"slotId":"10:00","createdAt":"2026-01-01T10:00:00.000"}]',
    });

    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The real app widget, which builds its own service and calls load().
    await tester.pumpWidget(const SlotBookingApp());
    await tester.pumpAndSettle();

    expect(find.text('1 upcoming booking'), findsOneWidget);

    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Study Room B'), findsOneWidget);
    expect(find.text('10:00 – 11:00'), findsOneWidget);
  });
}
