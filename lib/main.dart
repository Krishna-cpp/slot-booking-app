import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_screen.dart';
import 'services/booking_service.dart';
import 'theme/app_theme.dart';

/// Entry point. Every Dart program starts at `main`.
void main() {
  runApp(const SlotBookingApp());
}

/// The root widget of the whole app.
class SlotBookingApp extends StatelessWidget {
  const SlotBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider creates ONE BookingService and puts it above
    // the whole widget tree. Any screen below can then reach it with
    // `context.watch<BookingService>()` (to rebuild on changes) or
    // `context.read<BookingService>()` (to just call a method).
    return ChangeNotifierProvider(
      // `..load()` is Dart's cascade operator: it calls load() on the new
      // service and still returns the service itself. load() reads the saved
      // bookings off the device, which is why they survive a restart.
      create: (context) => BookingService()..load(),
      child: MaterialApp(
        title: 'Slot Booking',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AppStartup(),
      ),
    );
  }
}

/// Waits for the saved bookings to load, then shows the app.
///
/// Without this you would briefly see an empty "No bookings yet" screen
/// before the stored data arrived.
class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    final isLoaded = context.watch<BookingService>().isLoaded;

    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.ink),
        ),
      );
    }
    return const RootScreen();
  }
}
