import 'package:flutter/material.dart';

import 'room.dart';
import 'time_slot.dart';

/// One saved reservation: "this room, on this date, for this hour".
@immutable
class Booking {
  const Booking({
    required this.id,
    required this.roomId,
    required this.dateKey,
    required this.slotId,
    required this.createdAt,
  });

  /// Unique id for this booking, used when cancelling.
  final String id;

  /// Which [Room] this belongs to (see [Room.id]).
  final String roomId;

  /// The day, stored as 'yyyy-MM-dd' text so it is easy to compare and to
  /// save as JSON. Storing a plain date (no time) avoids timezone headaches.
  final String dateKey;

  /// Which hour, stored as [TimeSlot.id] (e.g. '09:00').
  final String slotId;

  /// When the user made the booking (only used for sorting/debugging).
  final DateTime createdAt;

  /// The room object, or `null` if that room no longer exists.
  Room? get room => findRoomById(roomId);

  /// Human-readable room name for the UI.
  String get roomName => room?.name ?? 'Unknown room';

  /// The stored dateKey turned back into a DateTime.
  DateTime get date => parseDateKey(dateKey);

  /// '09:00 – 10:00'
  String get slotLabel => TimeSlot.labelForId(slotId);

  /// Converts this object into a Map that `jsonEncode` understands.
  /// shared_preferences can only store simple types, so we go
  /// Booking -> Map -> JSON string.
  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'dateKey': dateKey,
        'slotId': slotId,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Builds a Booking back from the Map we decoded from JSON.
  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        dateKey: json['dateKey'] as String,
        slotId: json['slotId'] as String,
        // `tryParse` + `??` means a corrupted date can't crash the app.
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// Small date helpers. Kept here (next to dateKey) so there is one obvious
// place that decides how dates are written and read.
// ---------------------------------------------------------------------------

/// Turns a DateTime into our storage key: 2026-11-01.
String dateKeyOf(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Turns '2026-11-01' back into a DateTime at midnight.
/// Falls back to today if the text is unreadable.
DateTime parseDateKey(String key) {
  final parsed = DateTime.tryParse(key);
  if (parsed == null) return dateOnly(DateTime.now());
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Strips the time part, keeping only year/month/day.
/// Two DateTimes for "today" are only equal if we do this first.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// 'Sun, 01 Nov 2026' — used on the booking and confirm screens.
String formatFullDate(DateTime date) {
  // DateTime.weekday is 1 for Monday ... 7 for Sunday, so we subtract 1
  // to index our zero-based list.
  final weekday = _weekdays[date.weekday - 1];
  final month = _months[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  return '$weekday, $day $month ${date.year}';
}

/// 'Today' / 'Tomorrow' / '01 Nov' — a friendlier short label.
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final target = dateOnly(date);
  final difference = target.difference(today).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  if (difference == -1) return 'Yesterday';
  return '${target.day.toString().padLeft(2, '0')} ${_months[target.month - 1]}';
}
