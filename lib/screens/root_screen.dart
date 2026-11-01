import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';

/// The shell that holds the bottom navigation bar.
///
/// It owns one piece of state: which tab is open. Everything else lives in
/// the two screens it shows.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  /// 0 = Rooms, 1 = My Bookings.
  int _tabIndex = 0;

  /// The two pages, built once and kept alive by the IndexedStack below.
  static const List<Widget> _pages = [
    HomeScreen(),
    MyBookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps BOTH pages in memory and just shows one. That way
      // switching tabs does not reset scroll position or lose state.
      body: IndexedStack(
        index: _tabIndex,
        children: _pages,
      ),

      // A plain Container gives us the thick top border that a stock
      // BottomNavigationBar does not have.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: kInkBorderSide),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          // setState tells Flutter "my state changed, rebuild me" - which
          // swaps the visible page.
          onTap: (index) => setState(() => _tabIndex = index),
          backgroundColor: AppColors.background,
          elevation: 0,
          selectedItemColor: AppColors.ink,
          unselectedItemColor: AppColors.muted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room_outlined),
              activeIcon: Icon(Icons.meeting_room),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'My Bookings',
            ),
          ],
        ),
      ),
    );
  }
}
