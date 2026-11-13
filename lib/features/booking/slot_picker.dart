import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/availability.dart';

/// Horizontal 14-day date strip plus the free slots for the selected day.
class SlotPicker extends ConsumerStatefulWidget {
  const SlotPicker({
    super.key,
    required this.business,
    required this.service,
    required this.onPicked,
    this.selected,
    this.ignoreBookingId,
  });

  final Business business;
  final Service service;
  final DateTime? selected;
  final String? ignoreBookingId;
  final ValueChanged<DateTime> onPicked;

  @override
  ConsumerState<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends ConsumerState<SlotPicker> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _day = DateTime(now.year, now.month, now.day);
    // Jump to the first day that has availability.
    final bookings = ref.read(bookingsProvider).value ?? const <Booking>[];
    for (var i = 0; i < 14; i++) {
      final d = _day.add(Duration(days: i));
      if (freeSlots(
        business: widget.business,
        service: widget.service,
        day: d,
        bookings: bookings,
        now: now,
      ).isNotEmpty) {
        _day = d;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final bookings = (ref.watch(bookingsProvider).value ?? const <Booking>[]).where(
      (b) => b.id != widget.ignoreBookingId,
    );
    final today = DateTime(now.year, now.month, now.day);
    final slots = freeSlots(
      business: widget.business,
      service: widget.service,
      day: _day,
      bookings: bookings,
      now: now,
    );
    final groups = groupByPartOfDay(slots);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 14,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = today.add(Duration(days: i));
              final sel = d == _day;
              final closed = widget.business.hours[d.weekday] == null;
              return InkWell(
                key: Key('day_$i'),
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _day = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 62,
                  decoration: BoxDecoration(
                    color: sel ? brand : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: sel ? brand : const Color(0xFFE2E2EE)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i == 0 ? 'Today' : DateFormat.E().format(d),
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: sel ? Colors.white : (closed ? Colors.black26 : ink),
                        ),
                      ),
                      Text(
                        DateFormat.MMM().format(d),
                        style: TextStyle(fontSize: 11, color: sel ? Colors.white70 : Colors.black38),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.business.hours[_day.weekday] == null ? 'Closed on this day.' : 'Fully booked. Try another day.',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        for (final g in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              g.key,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in g.value)
                  ChoiceChip(
                    key: Key('slot_${s.start.hour}_${s.start.minute}'),
                    label: Text(DateFormat.jm().format(s.start)),
                    selected: widget.selected == s.start,
                    showCheckmark: false,
                    selectedColor: brand,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: widget.selected == s.start ? Colors.white : ink,
                    ),
                    onSelected: (_) => widget.onPicked(s.start),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
