# Slot Booking App

A small, beginner-friendly Flutter app for booking shared spaces — study rooms,
a badminton court, a seminar hall. You pick a room, pick a date, pick a free
hour, confirm, and the booking is saved on your device. Slots that are already
taken are shown struck-through and disabled, so **double-booking is impossible**.

Built as a learning project: plain `setState` for screen-local state, `Provider`
for the one piece of shared data (the bookings), and no extra architecture on
top. Every file has short comments explaining what the widget or pattern does.

---

## Features

| # | Feature | Where it lives |
|---|---------|----------------|
| 1 | **Home screen** listing all bookable rooms, with a badge showing how many bookings each already has | `lib/screens/home_screen.dart` |
| 2 | **Booking screen**: Material date picker + prev/next day arrows, then a 3-column grid of hourly slots | `lib/screens/booking_screen.dart` |
| 3 | **Disabled slots** — anything already booked for that room *and* that date is greyed out, struck through, labelled `BOOKED` and has no tap handler. Hours that have already passed today are disabled too | `booking_screen.dart` + `lib/widgets/slot_tile.dart` |
| 4 | **Confirm dialog** repeating room / date / time, with a Confirm button | `lib/screens/confirm_booking_dialog.dart` |
| 5 | **My Bookings** screen split into Upcoming / Past, each with a cancel button; cancelling frees the slot again instantly | `lib/screens/my_bookings_screen.dart` |
| 6 | **Local persistence** with `shared_preferences` (bookings are stored as JSON, so they survive a restart) | `lib/services/booking_service.dart` |
| 7 | **Navigation**: a bottom navigation bar for the two main tabs, plus `Navigator.push` to open a room's booking screen | `lib/screens/root_screen.dart` |
| 8 | **Bold, consistent styling**: yellow `#FFD60A` accent, near-black `#0D0D0D` text and 2px borders, off-white `#F5F3EF` background, hard (non-blurred) drop shadows | `lib/theme/app_theme.dart` |

### The double-booking rule

One booking is identified by **room + date + hour**. The guard exists in two
places, which is deliberate:

1. **In the UI** — the grid asks the service for the set of taken slot ids for
   the current room and date, and gives those tiles `onTap: null`. A disabled
   tile cannot be selected, so it cannot be confirmed.
2. **In the service** — `BookingService.book()` re-checks and returns
   `BookingResult.alreadyBooked` instead of saving. So even if the UI were
   wrong (or two taps landed at once), the data stays correct.

---

## Tech stack

- **Flutter 3.47.9** / **Dart 3.13.7**
- **provider 6.1.5** — `ChangeNotifier` + `ChangeNotifierProvider` for shared state
- **shared_preferences 2.5.6** — local key/value storage (localStorage on web)
- **flutter_lints 6.0** — static analysis
- **flutter_test** — unit and widget tests
- No backend, no database, no code generation.

---

## How to run it

You need Flutter installed (`flutter --version`) and Chrome.

```bash
# 1. get the packages
flutter pub get

# 2. run it in Chrome
flutter run -d chrome
```

Other useful commands:

```bash
flutter analyze        # static analysis - should print "No issues found!"
flutter test           # runs all 33 tests
flutter build web      # production web build into build/web
```

> Only the web target is set up for day-to-day use here (no Android SDK needed).
> The code itself is platform-neutral, so `flutter run -d windows` works too.

---

## Project structure

```
lib/
├── main.dart                        app entry: Provider + MaterialApp + theme
├── theme/
│   └── app_theme.dart               colours, borders, shadows, ThemeData
├── models/                          plain data classes, no UI code
│   ├── room.dart                    Room + the hard-coded list of rooms
│   ├── time_slot.dart               TimeSlot (one hour) + opening hours
│   └── booking.dart                 Booking + JSON + date helpers
├── services/
│   └── booking_service.dart         ALL booking logic + persistence
├── screens/                         one file per full screen
│   ├── root_screen.dart             bottom navigation shell
│   ├── home_screen.dart             the room list
│   ├── booking_screen.dart          date picker + slot grid
│   ├── confirm_booking_dialog.dart  the confirm step
│   └── my_bookings_screen.dart      list + cancel
└── widgets/                         small reusable pieces
    ├── app_button.dart              the one button style
    ├── room_card.dart               a row on the home screen
    ├── slot_tile.dart               one tile in the slot grid
    ├── booking_card.dart            a row on My Bookings
    └── empty_state.dart             "nothing here yet" placeholder

test/
├── booking_service_test.dart        20 unit tests - the booking rules
├── booking_screen_test.dart          9 widget tests - the slot grid & dialog
└── app_flow_test.dart                4 widget tests - the whole user journey
```

### How the pieces connect

```
main.dart
  └─ ChangeNotifierProvider(BookingService()..load())   <- one shared instance
       └─ RootScreen (bottom nav)
            ├─ HomeScreen ──tap a room──> BookingScreen
            │                                └─ ConfirmBookingDialog
            │                                     └─ service.book(...)
            └─ MyBookingsScreen ──cancel──> service.cancel(...)
```

`BookingService` is the single source of truth. Screens never keep a copy of
the bookings; they ask the service every time they build:

- `context.watch<BookingService>()` — subscribe, rebuild when it changes
- `context.read<BookingService>()` — just call a method (used inside callbacks)

So when the confirm dialog saves a booking, the service calls
`notifyListeners()`, and the slot grid, the home screen badges and the My
Bookings list all redraw themselves. No callbacks passed between screens.

---

## Tests

```
flutter test
00:08 +33: All tests passed!
```

The important ones:

- booking the **same room + date + slot twice** is rejected and adds nothing
- the **same slot on another date** or **in another room** is still free
- **cancelling frees the slot** and it can be re-booked
- bookings **survive a restart** (a second service reading the same store), and
  the reloaded data still blocks a double booking
- **corrupt stored JSON** doesn't crash the app
- in the UI: a booked tile reports `SlotState.booked`, has `onTap == null`, and
  tapping it leaves the Review button disabled
- changing the date **clears the selection** and re-checks which slots are taken
- the full journey: room → tomorrow → slot → review → confirm → My Bookings →
  cancel → empty state

---

## What I learned

- **Where state belongs.** The date and slot the user is currently choosing are
  temporary UI state, so they live in `BookingScreen`'s `State` with `setState`.
  The bookings are shared by three screens, so they live in one
  `ChangeNotifier` above the whole tree. Getting that split right removed the
  need to pass callbacks around.
- **`onPressed: null` / `onTap: null` is the real "disabled".** Flutter uses a
  null handler as the disabled signal, so making a booked slot un-tappable and
  making it *look* un-tappable are the same decision — which is why the bug
  can't drift apart.
- **Validate in the service, not only in the widget.** The grid hides taken
  slots, but `book()` checks again. The UI prevents the mistake; the service
  guarantees it.
- **Store dates as plain `yyyy-MM-dd` text.** Comparing `DateTime` objects that
  still carry hours/minutes silently fails. One `dateKey` format everywhere
  made the "is this slot taken?" check a single string comparison.
- **`shared_preferences` only stores simple types**, so the list of bookings
  goes `Booking → Map → JSON string` on the way out and back on the way in.
- **Widget tests are cheap and worth it.** Each one builds the real widget,
  taps it and reads the result — they caught the "selection survives a date
  change" bug before it ever ran in a browser.
- **`mounted` after `await`.** If the user leaves the screen while a dialog or
  a save is in flight, touching `context` afterwards crashes. Every `await` in
  this app is followed by a `mounted` check.

## Future work

- **Node.js + MySQL backend** — replace `shared_preferences` with a REST API
  (`Express` + `mysql2`) and tables `rooms`, `slots`, `bookings`. A
  `UNIQUE(room_id, date, slot)` constraint would move the double-booking rule
  into the database, which is where it really belongs once more than one person
  is booking at the same time.
- **User accounts** so bookings belong to someone, with login and "only cancel
  your own booking".
- **Recurring / multi-hour bookings** (book 14:00–17:00 in one go).
- **Admin screen** to add rooms and change opening hours instead of the
  hard-coded `kRooms` list.
- **Push/email reminders** before a slot starts.
- **Optimistic locking** — right now the last writer wins; with a server, two
  people tapping Confirm at the same second need the server to reject one.
