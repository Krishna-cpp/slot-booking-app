/// One bookable hour, e.g. 09:00 -> 10:00.
///
/// We identify a slot by its start hour only. That means slots can never
/// half-overlap, which makes the "is this taken?" check very simple.
class TimeSlot {
  const TimeSlot(this.startHour);

  /// 24-hour clock start, so 9 means 09:00 and 14 means 14:00.
  final int startHour;

  /// The value we persist inside a booking, e.g. '09:00'.
  String get id => _twoDigits(startHour);

  /// What the user reads, e.g. '09:00 – 10:00'.
  String get label => '${_twoDigits(startHour)} – ${_twoDigits(startHour + 1)}';

  /// Short version used in the compact grid tiles, e.g. '09:00'.
  String get shortLabel => _twoDigits(startHour);

  static String _twoDigits(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  /// Rebuilds a slot from a stored id like '09:00'.
  /// Returns `null` for anything we can't parse.
  static TimeSlot? fromId(String id) {
    final hour = int.tryParse(id.split(':').first);
    if (hour == null) return null;
    return TimeSlot(hour);
  }

  /// Turns an id back into a readable label, falling back to the raw id.
  static String labelForId(String id) => fromId(id)?.label ?? id;

  // Two TimeSlots with the same hour should count as equal. Dart compares
  // objects by identity unless we override `==` and `hashCode` like this.
  @override
  bool operator ==(Object other) =>
      other is TimeSlot && other.startHour == startHour;

  @override
  int get hashCode => startHour.hashCode;
}

/// The opening hours of our venue: 08:00 up to (not including) 20:00.
const int kOpeningHour = 8;
const int kClosingHour = 20;

/// Every slot we show in the booking grid.
/// `List.generate` builds a list by calling a function for each index.
final List<TimeSlot> kTimeSlots = List.generate(
  kClosingHour - kOpeningHour,
  (index) => TimeSlot(kOpeningHour + index),
);
