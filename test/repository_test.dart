import 'package:flutter_test/flutter_test.dart';
import 'package:slotwise/data/models.dart';
import 'package:slotwise/data/repository.dart';
import 'package:slotwise/data/seed.dart';

void main() {
  final now = DateTime(2026, 11, 13, 9);
  final shop = seedBusinesses.first;
  final cut = shop.services.first;
  final customer = demoUsers[Role.customer]!;
  final slot = DateTime(2026, 11, 18, 10); // Wednesday 10:00

  test('creates a booking, then refuses a second one at the same time', () async {
    final repo = InMemoryRepository(clock: () => now, autoReply: false);
    final b = await repo.createBooking(business: shop, service: cut, customer: customer, start: slot, totalCents: 4000);
    expect(b.status, BookingStatus.pendingPayment);
    expect(
      () => repo.createBooking(
        business: shop,
        service: cut,
        customer: customer,
        start: slot.add(const Duration(minutes: 15)),
        totalCents: 4000,
      ),
      throwsA(isA<SlotTakenException>()),
    );
  });

  test('a cancelled booking frees the slot', () async {
    final repo = InMemoryRepository(clock: () => now, autoReply: false);
    final b = await repo.createBooking(business: shop, service: cut, customer: customer, start: slot, totalCents: 4000);
    await repo.setBookingStatus(b.id, BookingStatus.cancelled);
    final again = await repo.createBooking(
      business: shop,
      service: cut,
      customer: customer,
      start: slot,
      totalCents: 4000,
    );
    expect(again.id, isNot(b.id));
  });

  test('status updates and reschedules stream to listeners', () async {
    final repo = InMemoryRepository(clock: () => now, autoReply: false);
    final b = await repo.createBooking(business: shop, service: cut, customer: customer, start: slot, totalCents: 4000);
    await repo.setBookingStatus(b.id, BookingStatus.confirmed, paymentRef: 'pi_test_1');
    final later = slot.add(const Duration(hours: 3));
    await repo.reschedule(b.id, later);
    final list = await repo.watchBookings().first;
    final saved = list.firstWhere((x) => x.id == b.id);
    expect(saved.status, BookingStatus.confirmed);
    expect(saved.paymentRef, 'pi_test_1');
    expect(saved.start, later);
  });

  test('provider auto-reply arrives in the thread', () async {
    final repo = InMemoryRepository(clock: () => now);
    await repo.sendMessage(threadId: 'b1|u_customer', fromId: 'u_customer', text: 'Where do I park?');
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final msgs = await repo.watchMessages().first;
    expect(msgs.last.fromId, shop.ownerId);
    expect(msgs.last.text, contains('parking'));
  });

  test('booking json round trip', () {
    final b = Booking(
      id: 'a',
      businessId: 'b1',
      serviceId: 's1',
      customerId: 'c',
      customerName: 'C',
      start: slot,
      minutes: 30,
      totalCents: 1234,
      status: BookingStatus.confirmed,
      paymentRef: 'pi_x',
    );
    final r = Booking.fromJson(b.toJson());
    expect(r.start, b.start);
    expect(r.status, b.status);
    expect(r.paymentRef, 'pi_x');
  });
}
