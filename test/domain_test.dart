import 'package:flutter_test/flutter_test.dart';
import 'package:slotwise/data/models.dart';
import 'package:slotwise/data/seed.dart';
import 'package:slotwise/domain/availability.dart';
import 'package:slotwise/domain/pricing.dart';

void main() {
  final shop = seedBusinesses.first; // Tue-Fri 10:00-19:00 (Fri 20:00), Sat 9-18, buffer 10
  final cut = shop.services.first; // 30 min
  final tuesday = DateTime(2026, 11, 17);
  final early = DateTime(2026, 11, 16, 8); // Monday 8 AM, so lead time does not matter for Tuesday

  Booking at(int h, int m, {int minutes = 30, BookingStatus status = BookingStatus.confirmed}) => Booking(
    id: 'x$h$m',
    businessId: shop.id,
    serviceId: cut.id,
    customerId: 'c',
    customerName: 'C',
    start: DateTime(2026, 11, 17, h, m),
    minutes: minutes,
    totalCents: 1000,
    status: status,
  );

  group('freeSlots', () {
    test('opens at opening time, steps by 15 min and ends before close minus buffer', () {
      final s = freeSlots(business: shop, service: cut, day: tuesday, bookings: const [], now: early);
      expect(s.first.start, DateTime(2026, 11, 17, 10));
      expect(s[1].start, DateTime(2026, 11, 17, 10, 15));
      // 19:00 close - 30 min service - 10 min buffer => last start 18:15
      expect(s.last.start, DateTime(2026, 11, 17, 18, 15));
    });

    test('closed day has no slots', () {
      final monday = DateTime(2026, 11, 16);
      expect(freeSlots(business: shop, service: cut, day: monday, bookings: const [], now: early), isEmpty);
    });

    test('bookings plus buffer block overlapping slots', () {
      final s = freeSlots(business: shop, service: cut, day: tuesday, bookings: [at(12, 0)], now: early);
      final starts = s.map((x) => '${x.start.hour}:${x.start.minute}').toSet();
      // 12:00-12:30 + 10 buffer => 11:45 (ends 12:15 + buffer) and 12:00, 12:15, 12:30 are blocked.
      expect(starts.contains('11:15'), isTrue); // 11:15-11:45 + 10 = 11:55 < 12:00
      expect(starts.contains('11:30'), isFalse); // 11:30-12:00 + 10 overlaps
      expect(starts.contains('12:30'), isFalse); // booking + buffer ends 12:40
      expect(starts.contains('12:45'), isTrue);
    });

    test('cancelled bookings free the time again', () {
      final s = freeSlots(
        business: shop,
        service: cut,
        day: tuesday,
        bookings: [at(12, 0, status: BookingStatus.cancelled)],
        now: early,
      );
      expect(s.any((x) => x.start == DateTime(2026, 11, 17, 12)), isTrue);
    });

    test('lead time hides slots starting within the next hour', () {
      final now = DateTime(2026, 11, 17, 13, 5);
      final s = freeSlots(business: shop, service: cut, day: tuesday, bookings: const [], now: now);
      expect(s.first.start, DateTime(2026, 11, 17, 14, 15));
    });

    test('isStillFree guards against a stale slot list', () {
      expect(
        isStillFree(business: shop, start: DateTime(2026, 11, 17, 12, 15), minutes: 30, bookings: [at(12, 0)]),
        isFalse,
      );
      expect(
        isStillFree(business: shop, start: DateTime(2026, 11, 17, 12, 45), minutes: 30, bookings: [at(12, 0)]),
        isTrue,
      );
      expect(
        isStillFree(
          business: shop,
          start: DateTime(2026, 11, 17, 12, 15),
          minutes: 30,
          bookings: [at(12, 0)],
          ignoreBookingId: 'x120',
        ),
        isTrue,
      );
    });

    test('groups by part of day', () {
      final s = freeSlots(business: shop, service: cut, day: tuesday, bookings: const [], now: early);
      expect(groupByPartOfDay(s).keys, ['Morning', 'Afternoon', 'Evening']);
    });
  });

  group('pricing', () {
    test('fee, tax and total', () {
      final q = quote(4500);
      expect(q.serviceFee, 225);
      expect(q.tax, 371);
      expect(q.total, 4500 + 225 + 371);
    });

    test('minimum booking fee is 99 cents', () => expect(quote(1000).serviceFee, 99));

    test('promo codes are case-insensitive and reduce the taxable amount', () {
      final q = quote(10000, promo: ' welcome10 ');
      expect(q.discount, 1000);
      expect(q.tax, 743);
      expect(q.total, 10000 + 500 + 743 - 1000);
    });

    test('unknown promo is ignored', () => expect(quote(10000, promo: 'FREE').discount, 0));

    test('provider payout after 12% commission', () => expect(quote(10000).providerPayout(), 8800));

    test('money formatting', () {
      expect(money(0), r'$0.00');
      expect(money(4950), r'$49.50');
      expect(money(123456789), r'$1,234,567.89');
      expect(money(-500), r'-$5.00');
    });
  });
}
