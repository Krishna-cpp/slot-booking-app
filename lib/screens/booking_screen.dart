import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/room.dart';
import '../models/time_slot.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/slot_tile.dart';
import 'confirm_booking_dialog.dart';

/// Screen 2: pick a date, then pick a free time slot for one room.
///
/// This is a StatefulWidget because it remembers two things *while the user
/// is on the screen*: the chosen date and the chosen slot. That is "UI state"
/// and it lives here with setState. The bookings themselves are shared data,
/// so they live in BookingService instead.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.room});

  final Room room;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  /// The day currently shown in the grid. Starts at today.
  late DateTime _selectedDate;

  /// The slot the user tapped, or null if nothing is picked yet.
  String? _selectedSlotId;

  /// True while we are writing to storage, so we can disable the button and
  /// avoid a double tap creating two bookings.
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // initState runs once when the screen is created - a good place to set
    // up initial state. `dateOnly` drops the time part.
    _selectedDate = dateOnly(DateTime.now());
  }

  /// Opens the Material date picker and stores whatever the user chose.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // You cannot book in the past, and we allow 60 days ahead.
      firstDate: dateOnly(DateTime.now()),
      lastDate: dateOnly(DateTime.now()).add(const Duration(days: 60)),
      helpText: 'SELECT A DATE',
    );

    // `picked` is null if the user pressed Cancel - in that case do nothing.
    if (picked == null) return;
    _changeDate(dateOnly(picked));
  }

  /// Moves to another day and clears the selection, because a slot that was
  /// free yesterday may well be taken on the new date.
  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlotId = null;
    });
  }

  /// Jumps one day back/forward using the little arrow buttons.
  void _shiftDay(int days) {
    final target = _selectedDate.add(Duration(days: days));
    // Never go before today.
    if (target.isBefore(dateOnly(DateTime.now()))) return;
    _changeDate(target);
  }

  /// Decides how one tile should look.
  SlotState _stateFor(TimeSlot slot, Set<String> bookedIds) {
    if (bookedIds.contains(slot.id)) return SlotState.booked;
    if (_isSlotInPast(slot)) return SlotState.past;
    if (_selectedSlotId == slot.id) return SlotState.selected;
    return SlotState.available;
  }

  /// An hour that has already started today cannot be booked.
  bool _isSlotInPast(TimeSlot slot) {
    final now = DateTime.now();
    if (_selectedDate.isAfter(dateOnly(now))) return false; // future day
    return slot.startHour <= now.hour;
  }

  /// Runs the full confirm-and-save flow.
  Future<void> _reviewAndBook() async {
    final slotId = _selectedSlotId;
    if (slotId == null) return;

    final slot = TimeSlot.fromId(slotId);
    if (slot == null) return;

    // 1. Ask the user to confirm.
    final confirmed = await showConfirmBookingDialog(
      context,
      room: widget.room,
      date: _selectedDate,
      slot: slot,
    );
    // After an `await`, this screen might already be gone (the user could
    // have hit back). `mounted` tells us the widget is still on screen -
    // touching `context` without this check is a common Flutter bug.
    if (!mounted || confirmed != true) return;

    setState(() => _isSaving = true);

    // 2. Save it. `context.read` is for one-off calls inside callbacks;
    // we do not want to subscribe to changes here.
    final result = await context.read<BookingService>().book(
          roomId: widget.room.id,
          dateKey: dateKeyOf(_selectedDate),
          slotId: slotId,
        );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      // Clear the pick either way: on success it is now booked, and on
      // failure it was taken by someone else.
      _selectedSlotId = null;
    });

    // 3. Tell the user what happened.
    final messenger = ScaffoldMessenger.of(context);
    if (result == BookingResult.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Booked ${widget.room.name} - ${slot.label} '
            'on ${formatFullDate(_selectedDate)}',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Sorry, that slot was just taken. Pick another one.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the service so the grid redraws right after a booking is saved
    // or cancelled.
    final service = context.watch<BookingService>();
    final dateKey = dateKeyOf(_selectedDate);

    // The set of slot ids already taken for THIS room on THIS date.
    // This single line is what prevents double booking in the UI.
    final bookedIds = service.bookedSlotIds(
      roomId: widget.room.id,
      dateKey: dateKey,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _RoomSummary(room: widget.room),
          const SizedBox(height: 22),

          const _SectionLabel('1. PICK A DATE'),
          const SizedBox(height: 10),
          _DateSelector(
            date: _selectedDate,
            onTap: _pickDate,
            onPrevious: () => _shiftDay(-1),
            onNext: () => _shiftDay(1),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('2. PICK A TIME'),
              Text(
                '${kTimeSlots.length - bookedIds.length} of '
                '${kTimeSlots.length} free',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // GridView.builder lays the tiles out in rows of 3.
          // shrinkWrap + NeverScrollableScrollPhysics let the grid sit inside
          // the ListView instead of trying to scroll on its own.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(right: 3, bottom: 3),
            itemCount: kTimeSlots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) {
              final slot = kTimeSlots[index];
              final state = _stateFor(slot, bookedIds);

              // Only free, not-past slots get a tap handler. Passing null
              // for the others is what makes them visually disabled AND
              // untappable, so a booked slot simply cannot be selected.
              final bool selectable = state == SlotState.available ||
                  state == SlotState.selected;

              return SlotTile(
                // A ValueKey gives each tile a stable identity, which is
                // also how the widget tests find a specific slot.
                key: ValueKey('slot-${slot.id}'),
                label: slot.shortLabel,
                state: state,
                onTap: selectable
                    ? () => setState(() => _selectedSlotId = slot.id)
                    : null,
              );
            },
          ),

          const SizedBox(height: 16),
          const _Legend(),
          const SizedBox(height: 24),

          // The button stays disabled until a slot is selected.
          AppButton(
            label: _isSaving ? 'SAVING...' : 'REVIEW BOOKING',
            icon: Icons.arrow_forward,
            onPressed:
                (_selectedSlotId == null || _isSaving) ? null : _reviewAndBook,
          ),
          if (_selectedSlotId == null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Select a free time slot to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small uppercase heading used to number the steps.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: AppColors.muted,
      ),
    );
  }
}

/// The dark strip at the top showing which room is being booked.
class _RoomSummary extends StatelessWidget {
  const _RoomSummary({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(room.icon, color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${room.location}  ·  seats ${room.capacity}',
                  style: const TextStyle(
                    color: Color(0xFFB9B5AD),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The date row: back arrow, the date itself (tap to open the picker),
/// forward arrow.
class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onTap,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // Disable the back arrow when we are already on today.
    final bool canGoBack = date.isAfter(dateOnly(DateTime.now()));

    return Row(
      children: [
        _ArrowButton(
          icon: Icons.chevron_left,
          onPressed: canGoBack ? onPrevious : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.fromBorderSide(kInkBorderSide),
              borderRadius: BorderRadius.circular(14),
              boxShadow: inkShadow(offset: 3),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatRelativeDate(date),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              formatFullDate(date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ArrowButton(icon: Icons.chevron_right, onPressed: onNext),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Container(
      height: 46,
      width: 42,
      decoration: BoxDecoration(
        color: enabled ? AppColors.accent : AppColors.background,
        border: Border.all(
          color: enabled ? AppColors.ink : AppColors.muted,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.ink : AppColors.muted,
        ),
      ),
    );
  }
}

/// Explains the three tile colours to the user.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendItem(color: AppColors.surface, label: 'Free'),
        SizedBox(width: 16),
        _LegendItem(color: AppColors.ink, label: 'Selected'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFE8E4DC), label: 'Booked'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
