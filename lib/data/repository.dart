import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/availability.dart';
import 'models.dart';
import 'seed.dart';

class SlotTakenException implements Exception {
  const SlotTakenException();
  @override
  String toString() => 'That time was just booked by someone else. Please pick another slot.';
}

/// Everything the UI needs from the backend. Two implementations:
/// [InMemoryRepository] (demo mode, works offline) and FirestoreRepository (real-time cloud).
abstract interface class MarketRepository {
  Stream<List<Business>> watchBusinesses();
  Stream<List<Booking>> watchBookings();
  Stream<List<ChatMessage>> watchMessages();

  /// Creates a booking atomically. Throws [SlotTakenException] when the time is no longer free.
  Future<Booking> createBooking({
    required Business business,
    required Service service,
    required AppUser customer,
    required DateTime start,
    required int totalCents,
  });

  Future<void> setBookingStatus(String bookingId, BookingStatus status, {String? paymentRef});
  Future<void> reschedule(String bookingId, DateTime start);
  Future<void> saveBusiness(Business business);
  Future<void> sendMessage({required String threadId, required String fromId, required String text});
}

/// A tiny replaying broadcast stream (like a BehaviorSubject).
class _Store<T> {
  _Store(this._value);
  T _value;
  final _ctrl = StreamController<T>.broadcast();

  T get value => _value;
  set value(T v) {
    _value = v;
    _ctrl.add(v);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _ctrl.stream;
  }
}

class InMemoryRepository implements MarketRepository {
  InMemoryRepository({DateTime Function()? clock, this.autoReply = true}) : _clock = clock ?? DateTime.now {
    _bookings = _Store(seedBookings(_clock()));
    _messages = _Store(_seedMessages(_clock()));
  }

  final DateTime Function() _clock;
  final bool autoReply;
  final _uuid = const Uuid();
  final _businesses = _Store<List<Business>>(List.of(seedBusinesses));
  late final _Store<List<Booking>> _bookings;
  late final _Store<List<ChatMessage>> _messages;

  @override
  Stream<List<Business>> watchBusinesses() => _businesses.stream;
  @override
  Stream<List<Booking>> watchBookings() => _bookings.stream;
  @override
  Stream<List<ChatMessage>> watchMessages() => _messages.stream;

  @override
  Future<Booking> createBooking({
    required Business business,
    required Service service,
    required AppUser customer,
    required DateTime start,
    required int totalCents,
  }) async {
    if (!isStillFree(business: business, start: start, minutes: service.minutes, bookings: _bookings.value)) {
      throw const SlotTakenException();
    }
    final b = Booking(
      id: _uuid.v4(),
      businessId: business.id,
      serviceId: service.id,
      customerId: customer.id,
      customerName: customer.name,
      start: start,
      minutes: service.minutes,
      totalCents: totalCents,
      status: BookingStatus.pendingPayment,
    );
    _bookings.value = [..._bookings.value, b];
    return b;
  }

  @override
  Future<void> setBookingStatus(String bookingId, BookingStatus status, {String? paymentRef}) async {
    _bookings.value = [
      for (final b in _bookings.value)
        if (b.id == bookingId) b.copyWith(status: status, paymentRef: paymentRef) else b,
    ];
  }

  @override
  Future<void> reschedule(String bookingId, DateTime start) async {
    final b = _bookings.value.firstWhere((b) => b.id == bookingId);
    final biz = _businesses.value.firstWhere((x) => x.id == b.businessId);
    if (!isStillFree(
      business: biz,
      start: start,
      minutes: b.minutes,
      bookings: _bookings.value,
      ignoreBookingId: b.id,
    )) {
      throw const SlotTakenException();
    }
    _bookings.value = [
      for (final x in _bookings.value)
        if (x.id == bookingId) x.copyWith(start: start) else x,
    ];
  }

  @override
  Future<void> saveBusiness(Business business) async {
    _businesses.value = [
      for (final b in _businesses.value)
        if (b.id == business.id) business else b,
    ];
  }

  @override
  Future<void> sendMessage({required String threadId, required String fromId, required String text}) async {
    final m = ChatMessage(id: _uuid.v4(), threadId: threadId, fromId: fromId, text: text.trim(), sent: _clock());
    _messages.value = [..._messages.value, m];
    final businessId = threadId.split('|').first;
    final owner = _businesses.value.firstWhere((b) => b.id == businessId).ownerId;
    if (autoReply && fromId != owner) {
      Timer(const Duration(milliseconds: 1400), () {
        _messages.value = [
          ..._messages.value,
          ChatMessage(id: _uuid.v4(), threadId: threadId, fromId: owner, text: _reply(text), sent: _clock()),
        ];
      });
    }
  }

  static String _reply(String text) {
    final t = text.toLowerCase();
    if (t.contains('park')) {
      return 'Free parking behind the building, enter from the alley 🚗';
    }
    if (t.contains('late') || t.contains('running')) {
      return 'No problem, we will hold your spot for 10 minutes.';
    }
    if (t.contains('cancel') || t.contains('reschedule')) {
      return 'You can reschedule or cancel free of charge up to 12 hours before, right from Bookings.';
    }
    if (t.contains('price') || t.contains('cost')) {
      return 'Prices on the menu are all-in except tax and the booking fee.';
    }
    return 'Thanks for the message! We will see you soon 👋';
  }

  static List<ChatMessage> _seedMessages(DateTime now) => [
    ChatMessage(
      id: 'm1',
      threadId: 'b1|u_customer',
      fromId: 'u_customer',
      text: 'Hi! Can I bring a reference photo for the fade?',
      sent: now.subtract(const Duration(hours: 3)),
    ),
    ChatMessage(
      id: 'm2',
      threadId: 'b1|u_customer',
      fromId: 'u_provider',
      text: 'Absolutely, send it here or bring it in 👍',
      sent: now.subtract(const Duration(hours: 3, minutes: -4)),
    ),
    ChatMessage(
      id: 'm3',
      threadId: 'b2|u_customer',
      fromId: 'u_p2',
      text: 'Reminder: please arrive 10 minutes early for your intake form.',
      sent: now.subtract(const Duration(days: 1)),
    ),
    ChatMessage(
      id: 'm4',
      threadId: 'b1|u_c3',
      fromId: 'u_c3',
      text: 'Running 5 min late, sorry!',
      sent: now.subtract(const Duration(minutes: 25)),
    ),
  ];
}
