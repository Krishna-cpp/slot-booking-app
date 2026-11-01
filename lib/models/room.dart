import 'package:flutter/material.dart';

/// A bookable resource (a study room, a court, a hall...).
///
/// This is a plain "model" class: it only holds data, it has no UI code.
/// Keeping data and UI separate is one of the first good habits in Flutter.
@immutable
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.icon,
  });

  /// Short unique key we store inside bookings (e.g. 'study_a').
  /// We save the *id*, not the name, so renaming a room later won't
  /// break existing bookings.
  final String id;

  final String name;
  final String location;
  final int capacity;

  /// Which Material icon to draw on the card.
  final IconData icon;
}

/// The rooms this app offers.
///
/// In a real app these would come from a server. For now a hard-coded
/// `const` list is perfect and keeps everything offline.
const List<Room> kRooms = [
  Room(
    id: 'study_a',
    name: 'Study Room A',
    location: 'Library · 1st floor',
    capacity: 6,
    icon: Icons.menu_book_outlined,
  ),
  Room(
    id: 'study_b',
    name: 'Study Room B',
    location: 'Library · 2nd floor',
    capacity: 4,
    icon: Icons.lightbulb_outline,
  ),
  Room(
    id: 'badminton',
    name: 'Badminton Court',
    location: 'Sports complex',
    capacity: 4,
    icon: Icons.sports_tennis_outlined,
  ),
  Room(
    id: 'seminar',
    name: 'Seminar Hall',
    location: 'Block C · Ground floor',
    capacity: 80,
    icon: Icons.groups_outlined,
  ),
];

/// Finds a room by its id. Returns `null` if there is no such room
/// (which can happen if a saved booking points at a room we removed).
Room? findRoomById(String id) {
  for (final room in kRooms) {
    if (room.id == id) return room;
  }
  return null;
}
