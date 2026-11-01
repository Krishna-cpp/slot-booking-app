// Widget tests: these build real widgets in a fake screen and tap them,
// so they check that the UI actually honours the booking rules.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slot_booking_app/models/booking.dart';
import 'package:slot_booking_app/models/room.dart';
import 'package:slot_booking_app/screens/booking_screen.dart';
import 'package:slot_booking_app/services/booking_service.dart';
import 'package:slot_booking_app/widgets/app_button.dart';
import 'package:slot_booking_app/widgets/slot_tile.dart';

void main() {
  /// The room we book in every test.
  final room = kRooms.first;

  /// Tomorrow, so no slot is "in the past" no matter what time the tests run.
  final tomorrow = dateOnly(DateTime.now()).add(const Duration(days: 1));
  final tomorrowKey = dateKeyOf(tomorrow);

  late BookingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = BookingService();
    await service.load();
  });

  /// Builds the BookingScreen inside the two things it needs: a MaterialApp
  /// (for navigation, theming and dialogs) and the Provider that supplies
  /// the BookingService.
  Future<void> pumpBookingScreen(WidgetTester tester) async {
    // Give the test a tall window so nothing overflows.
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<BookingService>.value(
        value: service,
        child: MaterialApp(home: BookingScreen(room: room)),
      ),
    );
    await tester.pumpAndSettle();

    // Move to tomorrow using the forward arrow.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
  }

  /// Reads the current state of one slot tile out of the widget tree.
  SlotTile slotTile(WidgetTester tester, String slotId) =>
      tester.widget<SlotTile>(find.byKey(ValueKey('slot-$slotId')));

  /// The "REVIEW BOOKING" button at the bottom of the screen.
  AppButton reviewButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton));

  testWidgets('shows a tile for every opening hour', (tester) async {
    await pumpBookingScreen(tester);

    expect(find.byType(SlotTile), findsNWidgets(12)); // 08:00 - 19:00
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
  });

  testWidgets('an already-booked slot is disabled and cannot be selected',
      (tester) async {
    // Pre-book 09:00 for this room tomorrow.
    await service.book(
      roomId: room.id,
      dateKey: tomorrowKey,
      slotId: '09:00',
    );

    await pumpBookingScreen(tester);

    // The tile reports itself as booked, and has no tap handler at all -
    // that null onTap is what makes double-booking impossible in the UI.
    final booked = slotTile(tester, '09:00');
    expect(booked.state, SlotState.booked);
    expect(booked.onTap, isNull);
    expect(find.text('BOOKED'), findsOneWidget);

    // Tapping it does nothing, so the Review button stays disabled.
    await tester.tap(find.byKey(const ValueKey('slot-09:00')));
    await tester.pumpAndSettle();
    expect(reviewButton(tester).onPressed, isNull);
  });

  testWidgets('a free slot can be selected and the button turns on',
      (tester) async {
    await pumpBookingScreen(tester);

    // Before selecting anything the button is disabled.
    expect(reviewButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('slot-10:00')));
    await tester.pumpAndSettle();

    expect(slotTile(tester, '10:00').state, SlotState.selected);
    expect(reviewButton(tester).onPressed, isNotNull);
  });

  testWidgets('confirming the dialog saves the booking and disables the slot',
      (tester) async {
    await pumpBookingScreen(tester);

    await tester.tap(find.byKey(const ValueKey('slot-11:00')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REVIEW BOOKING'));
    await tester.pumpAndSettle();

    // The confirm dialog repeats the three facts back to the user.
    expect(find.text('Check the details'), findsOneWidget);
    expect(find.text(room.name), findsWidgets);
    expect(find.text(formatFullDate(tomorrow)), findsWidgets);
    expect(find.text('11:00 – 12:00'), findsOneWidget);

    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();

    // The booking was stored...
    expect(service.bookings, hasLength(1));
    expect(service.bookings.first.slotId, '11:00');
    expect(service.bookings.first.dateKey, tomorrowKey);

    // ...and the grid redrew that slot as unavailable.
    expect(slotTile(tester, '11:00').state, SlotState.booked);
    expect(slotTile(tester, '11:00').onTap, isNull);
  });

  testWidgets('dismissing the dialog saves nothing', (tester) async {
    await pumpBookingScreen(tester);

    await tester.tap(find.byKey(const ValueKey('slot-12:00')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REVIEW BOOKING'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();

    expect(service.bookings, isEmpty);
    // The slot is still selected, so the user can carry on.
    expect(slotTile(tester, '12:00').state, SlotState.selected);
  });

  testWidgets('slots booked for ANOTHER room stay free here', (tester) async {
    await service.book(
      roomId: kRooms[1].id, // a different room
      dateKey: tomorrowKey,
      slotId: '09:00',
    );

    await pumpBookingScreen(tester);

    expect(slotTile(tester, '09:00').state, SlotState.available);
    expect(slotTile(tester, '09:00').onTap, isNotNull);
  });

  testWidgets('changing the date clears the selection and re-checks slots',
      (tester) async {
    // 14:00 is taken tomorrow, but free the day after.
    await service.book(
      roomId: room.id,
      dateKey: tomorrowKey,
      slotId: '14:00',
    );

    await pumpBookingScreen(tester);
    expect(slotTile(tester, '14:00').state, SlotState.booked);

    // Pick a free slot, then move one day forward.
    await tester.tap(find.byKey(const ValueKey('slot-15:00')));
    await tester.pumpAndSettle();
    expect(slotTile(tester, '15:00').state, SlotState.selected);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    // Selection was cleared (so you cannot book a slot you picked on
    // another day by accident) and 14:00 is free again.
    expect(slotTile(tester, '15:00').state, SlotState.available);
    expect(slotTile(tester, '14:00').state, SlotState.available);
    expect(reviewButton(tester).onPressed, isNull);
  });

  testWidgets('tapping the date card opens the date picker', (tester) async {
    await pumpBookingScreen(tester);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Cancel it again - the date must not change.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('cancelling a booking frees the slot in the grid',
      (tester) async {
    await service.book(
      roomId: room.id,
      dateKey: tomorrowKey,
      slotId: '16:00',
    );

    await pumpBookingScreen(tester);
    expect(slotTile(tester, '16:00').state, SlotState.booked);

    // Cancel through the service, exactly like My Bookings does.
    await service.cancel(service.bookings.first.id);
    await tester.pumpAndSettle();

    expect(slotTile(tester, '16:00').state, SlotState.available);
    expect(slotTile(tester, '16:00').onTap, isNotNull);
  });
}
