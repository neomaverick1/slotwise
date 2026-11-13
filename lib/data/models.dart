/// Core domain models for the Slotwise marketplace.
///
/// All money is stored as integer cents to avoid floating point errors.
library;

enum Role { customer, provider, admin }

enum Category { hair, wellness, fitness, tutoring, home, pets }

extension CategoryLabel on Category {
  String get label => switch (this) {
    Category.hair => 'Hair & Beauty',
    Category.wellness => 'Wellness',
    Category.fitness => 'Fitness',
    Category.tutoring => 'Tutoring',
    Category.home => 'Home Services',
    Category.pets => 'Pet Care',
  };

  String get emoji => switch (this) {
    Category.hair => '✂️',
    Category.wellness => '💆',
    Category.fitness => '🏋️',
    Category.tutoring => '📚',
    Category.home => '🛠️',
    Category.pets => '🐾',
  };
}

/// Weekly opening hours: weekday (1 = Monday ... 7 = Sunday) -> (openMinute, closeMinute).
typedef WeeklyHours = Map<int, (int, int)>;

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.minutes,
    required this.priceCents,
    this.description = '',
    this.active = true,
  });

  final String id;
  final String name;
  final int minutes;
  final int priceCents;
  final String description;
  final bool active;

  Service copyWith({bool? active, int? priceCents}) => Service(
    id: id,
    name: name,
    minutes: minutes,
    priceCents: priceCents ?? this.priceCents,
    description: description,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minutes': minutes,
    'priceCents': priceCents,
    'description': description,
    'active': active,
  };

  factory Service.fromJson(Map<String, dynamic> j) => Service(
    id: j['id'] as String,
    name: j['name'] as String,
    minutes: j['minutes'] as int,
    priceCents: j['priceCents'] as int,
    description: (j['description'] ?? '') as String,
    active: (j['active'] ?? true) as bool,
  );
}

class Review {
  const Review({required this.author, required this.stars, required this.text, required this.date});
  final String author;
  final int stars;
  final String text;
  final DateTime date;
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.category,
    required this.tagline,
    required this.address,
    required this.lat,
    required this.lng,
    required this.hours,
    required this.services,
    this.reviews = const [],
    this.bufferMinutes = 10,
    this.colorValue = 0xFF6C5CE7,
    this.approved = true,
  });

  final String id;
  final String name;
  final String ownerId;
  final Category category;
  final String tagline;
  final String address;
  final double lat;
  final double lng;
  final WeeklyHours hours;
  final List<Service> services;
  final List<Review> reviews;
  final int bufferMinutes;
  final int colorValue;
  final bool approved;

  double get rating => reviews.isEmpty ? 0 : reviews.map((r) => r.stars).reduce((a, b) => a + b) / reviews.length;

  int get fromPriceCents =>
      services.where((s) => s.active).map((s) => s.priceCents).fold<int>(1 << 30, (a, b) => a < b ? a : b);

  Business copyWith({List<Service>? services, bool? approved, List<Review>? reviews}) => Business(
    id: id,
    name: name,
    ownerId: ownerId,
    category: category,
    tagline: tagline,
    address: address,
    lat: lat,
    lng: lng,
    hours: hours,
    services: services ?? this.services,
    reviews: reviews ?? this.reviews,
    bufferMinutes: bufferMinutes,
    colorValue: colorValue,
    approved: approved ?? this.approved,
  );
}

enum BookingStatus { pendingPayment, confirmed, completed, cancelled }

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.pendingPayment => 'Awaiting payment',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.completed => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };
}

class Booking {
  const Booking({
    required this.id,
    required this.businessId,
    required this.serviceId,
    required this.customerId,
    required this.customerName,
    required this.start,
    required this.minutes,
    required this.totalCents,
    required this.status,
    this.paymentRef,
  });

  final String id;
  final String businessId;
  final String serviceId;
  final String customerId;
  final String customerName;
  final DateTime start;
  final int minutes;
  final int totalCents;
  final BookingStatus status;
  final String? paymentRef;

  DateTime get end => start.add(Duration(minutes: minutes));

  bool get isActive => status == BookingStatus.confirmed || status == BookingStatus.pendingPayment;

  Booking copyWith({BookingStatus? status, DateTime? start, String? paymentRef}) => Booking(
    id: id,
    businessId: businessId,
    serviceId: serviceId,
    customerId: customerId,
    customerName: customerName,
    start: start ?? this.start,
    minutes: minutes,
    totalCents: totalCents,
    status: status ?? this.status,
    paymentRef: paymentRef ?? this.paymentRef,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'serviceId': serviceId,
    'customerId': customerId,
    'customerName': customerName,
    'start': start.toUtc().toIso8601String(),
    'minutes': minutes,
    'totalCents': totalCents,
    'status': status.name,
    'paymentRef': paymentRef,
  };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    businessId: j['businessId'] as String,
    serviceId: j['serviceId'] as String,
    customerId: j['customerId'] as String,
    customerName: j['customerName'] as String,
    start: DateTime.parse(j['start'] as String).toLocal(),
    minutes: j['minutes'] as int,
    totalCents: j['totalCents'] as int,
    status: BookingStatus.values.byName(j['status'] as String),
    paymentRef: j['paymentRef'] as String?,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.fromId,
    required this.text,
    required this.sent,
  });

  final String id;

  /// Thread id is `businessId|customerId`.
  final String threadId;
  final String fromId;
  final String text;
  final DateTime sent;
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.role, this.businessId});
  final String id;
  final String name;
  final Role role;
  final String? businessId;
}
