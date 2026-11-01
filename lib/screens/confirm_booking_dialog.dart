import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/room.dart';
import '../models/time_slot.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

/// Shows the "please confirm" dialog and waits for the user's answer.
///
/// Returns `true` if they pressed Confirm, and `false`/`null` if they
/// cancelled or dismissed it. `showDialog` returns a Future, so the caller
/// writes `final ok = await showConfirmBookingDialog(...)`.
Future<bool?> showConfirmBookingDialog(
  BuildContext context, {
  required Room room,
  required DateTime date,
  required TimeSlot slot,
}) {
  return showDialog<bool>(
    context: context,
    // Tapping outside must not accidentally confirm; it just dismisses.
    builder: (context) => _ConfirmBookingDialog(
      room: room,
      date: date,
      slot: slot,
    ),
  );
}

class _ConfirmBookingDialog extends StatelessWidget {
  const _ConfirmBookingDialog({
    required this.room,
    required this.date,
    required this.slot,
  });

  final Room room;
  final DateTime date;
  final TimeSlot slot;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.fromBorderSide(kInkBorderSide),
          borderRadius: BorderRadius.circular(22),
          boxShadow: inkShadow(offset: 6),
        ),
        // SingleChildScrollView stops the dialog overflowing on short screens.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONFIRM BOOKING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Check the details',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 18),

              // The three facts the user must verify.
              _DetailRow(
                icon: room.icon,
                label: 'Room',
                value: room.name,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: formatFullDate(date),
              ),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Time',
                value: slot.label,
                isLast: true,
              ),

              const SizedBox(height: 20),
              AppButton(
                label: 'CONFIRM',
                icon: Icons.check,
                // `Navigator.pop(context, true)` closes the dialog AND sends
                // `true` back as the Future's result.
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Go back',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One "label / value" line inside the dialog.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.fromBorderSide(kInkBorderSide),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 10),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: AppColors.muted,
              ),
            ),
            const Spacer(), // pushes the value to the right edge
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
