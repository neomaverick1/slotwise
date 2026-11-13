import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/availability.dart';
import 'models.dart';
import 'repository.dart';
import 'seed.dart';

/// Real-time backend on Cloud Firestore.
///
/// Collections: `bookings`, `messages`, `businesses` and `dayLocks/{businessId}_{yyyy-MM-dd}`.
/// Double booking is prevented with a transaction on the day-lock document: it holds the
/// taken intervals for that business and day, and every new booking re-checks it atomically.
class FirestoreRepository implements MarketRepository {
  FirestoreRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookingsCol => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _messagesCol => _db.collection('messages');

  @override
  Stream<List<Business>> watchBusinesses() async* {
    // The catalog is static demo content; approvals and service toggles live in Firestore.
    yield* _db.collection('businesses').snapshots().map((snap) {
      final overrides = {for (final d in snap.docs) d.id: d.data()};
      return [
        for (final b in seedBusinesses)
          overrides[b.id] == null
              ? b
              : b.copyWith(
                  approved: overrides[b.id]!['approved'] as bool? ?? b.approved,
                  services:
                      (overrides[b.id]!['services'] as List?)
                          ?.map((e) => Service.fromJson(Map<String, dynamic>.from(e as Map)))
                          .toList() ??
                      b.services,
                ),
      ];
    });
  }

  @override
  Stream<List<Booking>> watchBookings() =>
      _bookingsCol.snapshots().map((s) => s.docs.map((d) => Booking.fromJson(d.data())).toList());

  @override
  Stream<List<ChatMessage>> watchMessages() => _messagesCol
      .orderBy('sent')
      .snapshots()
      .map(
        (s) => s.docs
            .map(
              (d) => ChatMessage(
                id: d.id,
                threadId: d['threadId'] as String,
                fromId: d['fromId'] as String,
                text: d['text'] as String,
                sent: (d['sent'] as Timestamp).toDate(),
              ),
            )
            .toList(),
      );

  String _lockId(String businessId, DateTime day) =>
      '${businessId}_${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Future<Booking> createBooking({
    required Business business,
    required Service service,
    required AppUser customer,
    required DateTime start,
    required int totalCents,
  }) {
    final ref = _bookingsCol.doc();
    final lockRef = _db.collection('dayLocks').doc(_lockId(business.id, start));
    return _db.runTransaction((tx) async {
      final lock = await tx.get(lockRef);
      final taken = ((lock.data()?['taken'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map(
            (m) => Booking(
              id: m['id'] as String,
              businessId: business.id,
              serviceId: '',
              customerId: '',
              customerName: '',
              start: DateTime.parse(m['start'] as String).toLocal(),
              minutes: m['minutes'] as int,
              totalCents: 0,
              status: BookingStatus.confirmed,
            ),
          )
          .toList();
      if (!isStillFree(business: business, start: start, minutes: service.minutes, bookings: taken)) {
        throw const SlotTakenException();
      }
      final booking = Booking(
        id: ref.id,
        businessId: business.id,
        serviceId: service.id,
        customerId: customer.id,
        customerName: customer.name,
        start: start,
        minutes: service.minutes,
        totalCents: totalCents,
        status: BookingStatus.pendingPayment,
      );
      tx.set(lockRef, {
        'taken': FieldValue.arrayUnion([
          {'id': ref.id, 'start': start.toUtc().toIso8601String(), 'minutes': service.minutes},
        ]),
      }, SetOptions(merge: true));
      tx.set(ref, booking.toJson());
      return booking;
    });
  }

  @override
  Future<void> setBookingStatus(String bookingId, BookingStatus status, {String? paymentRef}) =>
      _bookingsCol.doc(bookingId).update({'status': status.name, 'paymentRef': ?paymentRef});

  @override
  Future<void> reschedule(String bookingId, DateTime start) =>
      _bookingsCol.doc(bookingId).update({'start': start.toUtc().toIso8601String()});

  @override
  Future<void> saveBusiness(Business business) => _db.collection('businesses').doc(business.id).set({
    'approved': business.approved,
    'services': business.services.map((s) => s.toJson()).toList(),
  }, SetOptions(merge: true));

  @override
  Future<void> sendMessage({required String threadId, required String fromId, required String text}) => _messagesCol
      .add({'threadId': threadId, 'fromId': fromId, 'text': text.trim(), 'sent': FieldValue.serverTimestamp()});
}
