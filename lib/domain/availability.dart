import '../data/models.dart';

/// A bookable time window.
class Slot {
  const Slot(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool overlaps(DateTime s, DateTime e) => start.isBefore(e) && s.isBefore(end);

  @override
  bool operator ==(Object other) => other is Slot && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Slot($start - $end)';
}

/// Generates the free slots for [service] at [business] on [day].
///
/// Rules:
/// * slots start every [stepMinutes] inside the opening hours for that weekday;
/// * a slot must finish (including the business buffer) before closing time;
/// * slots that overlap an active booking (plus buffer) are removed;
/// * slots that start before [now] + [leadMinutes] are removed.
List<Slot> freeSlots({
  required Business business,
  required Service service,
  required DateTime day,
  required Iterable<Booking> bookings,
  required DateTime now,
  int stepMinutes = 15,
  int leadMinutes = 60,
}) {
  final hours = business.hours[day.weekday];
  if (hours == null || !service.active) return const [];
  final (open, close) = hours;
  final base = DateTime(day.year, day.month, day.day);
  final buffer = business.bufferMinutes;
  final earliest = now.add(Duration(minutes: leadMinutes));

  final taken = bookings
      .where((b) => b.businessId == business.id && b.isActive && _sameDay(b.start, base))
      .map((b) => Slot(b.start, b.end.add(Duration(minutes: buffer))))
      .toList();

  final result = <Slot>[];
  for (var m = open; m + service.minutes + buffer <= close; m += stepMinutes) {
    final start = base.add(Duration(minutes: m));
    final end = start.add(Duration(minutes: service.minutes));
    if (start.isBefore(earliest)) continue;
    final withBuffer = end.add(Duration(minutes: buffer));
    if (taken.any((t) => t.overlaps(start, withBuffer))) continue;
    result.add(Slot(start, end));
  }
  return result;
}

/// True when [start] for [minutes] can still be booked (used to guard against double booking
/// at checkout time, after the slot list may have gone stale).
bool isStillFree({
  required Business business,
  required DateTime start,
  required int minutes,
  required Iterable<Booking> bookings,
  String? ignoreBookingId,
}) {
  final end = start.add(Duration(minutes: minutes + business.bufferMinutes));
  return !bookings.any(
    (b) =>
        b.id != ignoreBookingId &&
        b.businessId == business.id &&
        b.isActive &&
        b.start.isBefore(end) &&
        start.isBefore(b.end.add(Duration(minutes: business.bufferMinutes))),
  );
}

/// Groups slots into morning / afternoon / evening for the slot picker.
Map<String, List<Slot>> groupByPartOfDay(List<Slot> slots) {
  final out = <String, List<Slot>>{'Morning': [], 'Afternoon': [], 'Evening': []};
  for (final s in slots) {
    final h = s.start.hour;
    out[h < 12 ? 'Morning' : (h < 17 ? 'Afternoon' : 'Evening')]!.add(s);
  }
  out.removeWhere((_, v) => v.isEmpty);
  return out;
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
