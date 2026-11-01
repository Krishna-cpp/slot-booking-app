import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';

/// What happened when we tried to save a booking.
/// Returning an enum (instead of just `true`/`false`) means the UI can show
/// a different message for each case.
enum BookingResult {
  success,

  /// Someone already holds this room + date + slot. This is the guard that
  /// makes double-booking impossible.
  alreadyBooked,
}

/// The single source of truth for all bookings.
///
/// It extends [ChangeNotifier], which is the Provider pattern:
///  1. we change some data,
///  2. we call `notifyListeners()`,
///  3. every widget that is `watch`ing this object rebuilds automatically.
///
/// That is why the Home, Booking and My Bookings screens all stay in sync
/// without us passing callbacks around.
class BookingService extends ChangeNotifier {
  /// The key we store our JSON under inside shared_preferences.
  static const String storageKey = 'bookings_v1';

  /// Private list. The outside world only gets a read-only view (below),
  /// so nobody can add a booking without going through [book].
  final List<Booking> _bookings = [];

  bool _isLoaded = false;

  /// True once we have finished reading from disk, so the UI can show
  /// a loading spinner before that.
  bool get isLoaded => _isLoaded;

  /// All bookings, sorted soonest-first.
  /// `List.unmodifiable` protects the internal list from outside edits.
  List<Booking> get bookings => List.unmodifiable(_bookings);

  /// Reads saved bookings from the device. Call this once at app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    _bookings.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        // The JSON is a list of maps; decode it and rebuild each Booking.
        final decoded = jsonDecode(raw) as List<dynamic>;
        _bookings.addAll(
          decoded.map(
            (item) => Booking.fromJson(item as Map<String, dynamic>),
          ),
        );
      } catch (error) {
        // If the stored data is corrupt we start fresh instead of crashing.
        debugPrint('Could not read saved bookings: $error');
        _bookings.clear();
      }
    }

    _sort();
    _isLoaded = true;
    notifyListeners();
  }

  /// Writes the current list back to the device as a JSON string.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_bookings.map((b) => b.toJson()).toList());
    await prefs.setString(storageKey, raw);
  }

  /// THE double-booking check: is this exact room + day + hour already taken?
  bool isSlotBooked({
    required String roomId,
    required String dateKey,
    required String slotId,
  }) {
    // `any` returns true as soon as one element matches.
    return _bookings.any(
      (b) => b.roomId == roomId && b.dateKey == dateKey && b.slotId == slotId,
    );
  }

  /// All taken slot ids for one room on one day, e.g. {'09:00', '14:00'}.
  /// The booking grid uses this to decide which tiles to disable.
  Set<String> bookedSlotIds({
    required String roomId,
    required String dateKey,
  }) {
    return _bookings
        .where((b) => b.roomId == roomId && b.dateKey == dateKey)
        .map((b) => b.slotId)
        .toSet();
  }

  /// Every booking for one room on one day.
  List<Booking> bookingsFor({
    required String roomId,
    required String dateKey,
  }) {
    return _bookings
        .where((b) => b.roomId == roomId && b.dateKey == dateKey)
        .toList();
  }

  /// How many bookings exist for a room from [from] onwards.
  /// Used for the "2 upcoming" badge on the home screen cards.
  int upcomingCountForRoom(String roomId, {DateTime? from}) {
    final today = dateOnly(from ?? DateTime.now());
    return _bookings
        .where((b) => b.roomId == roomId && !b.date.isBefore(today))
        .length;
  }

  /// Bookings for today or later, soonest first.
  List<Booking> upcomingBookings({DateTime? from}) {
    final today = dateOnly(from ?? DateTime.now());
    return _bookings.where((b) => !b.date.isBefore(today)).toList();
  }

  /// Bookings whose day has already passed.
  List<Booking> pastBookings({DateTime? from}) {
    final today = dateOnly(from ?? DateTime.now());
    return _bookings.where((b) => b.date.isBefore(today)).toList();
  }

  /// Tries to save a new booking.
  ///
  /// Returns [BookingResult.alreadyBooked] and changes nothing if the slot
  /// is taken, so calling this twice can never create a double booking.
  Future<BookingResult> book({
    required String roomId,
    required String dateKey,
    required String slotId,
  }) async {
    if (isSlotBooked(roomId: roomId, dateKey: dateKey, slotId: slotId)) {
      return BookingResult.alreadyBooked;
    }

    _bookings.add(
      Booking(
        id: _newId(),
        roomId: roomId,
        dateKey: dateKey,
        slotId: slotId,
        createdAt: DateTime.now(),
      ),
    );

    _sort();
    notifyListeners(); // tell the UI to rebuild
    await _save(); // then persist to disk
    return BookingResult.success;
  }

  /// Removes a booking, which frees its slot again.
  /// Returns true if something was actually removed.
  Future<bool> cancel(String bookingId) async {
    final before = _bookings.length;
    _bookings.removeWhere((b) => b.id == bookingId);
    final removed = _bookings.length < before;

    if (removed) {
      notifyListeners();
      await _save();
    }
    return removed;
  }

  /// Deletes everything (handy while developing, and used by the tests).
  Future<void> clearAll() async {
    _bookings.clear();
    notifyListeners();
    await _save();
  }

  /// Keeps the list in date order, then time order.
  void _sort() {
    _bookings.sort((a, b) {
      final byDate = a.dateKey.compareTo(b.dateKey);
      if (byDate != 0) return byDate;
      return a.slotId.compareTo(b.slotId);
    });
  }

  /// A good-enough unique id: microseconds since 1970 plus the slot details.
  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_bookings.length}';
}
