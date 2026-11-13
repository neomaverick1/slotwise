import 'models.dart';

const _weekdays9to6 = {1: (540, 1080), 2: (540, 1080), 3: (540, 1080), 4: (540, 1080), 5: (540, 1080)};
const _long = {
  1: (480, 1200),
  2: (480, 1200),
  3: (480, 1200),
  4: (480, 1200),
  5: (480, 1200),
  6: (540, 1020),
  7: (600, 960),
};
const _sat = {2: (600, 1140), 3: (600, 1140), 4: (600, 1140), 5: (600, 1200), 6: (540, 1080)};

final _d = DateTime(2026, 10, 1);

/// Demo businesses around downtown Austin, TX.
final seedBusinesses = <Business>[
  Business(
    id: 'b1',
    name: 'Fade & Co. Barbers',
    ownerId: 'u_provider',
    category: Category.hair,
    tagline: 'Sharp fades, hot towel shaves, zero wait.',
    address: '412 Congress Ave',
    lat: 30.2669,
    lng: -97.7428,
    hours: _sat,
    colorValue: 0xFF6C5CE7,
    services: const [
      Service(
        id: 's1',
        name: 'Classic cut',
        minutes: 30,
        priceCents: 3500,
        description: 'Clipper + scissor cut, styled.',
      ),
      Service(id: 's2', name: 'Skin fade', minutes: 45, priceCents: 4500, description: 'Bald fade with line-up.'),
      Service(id: 's3', name: 'Cut + beard', minutes: 60, priceCents: 6000, description: 'Full cut with beard sculpt.'),
      Service(id: 's4', name: 'Hot towel shave', minutes: 40, priceCents: 4000),
    ],
    reviews: [
      Review(author: 'Marcus T.', stars: 5, text: 'Best fade in Austin, booked in 20 seconds.', date: _d),
      Review(author: 'Jordan P.', stars: 5, text: 'On time, clean shop, great conversation.', date: _d),
      Review(author: 'Devin R.', stars: 4, text: 'Great cut. Parking is tricky.', date: _d),
    ],
  ),
  Business(
    id: 'b2',
    name: 'Stillwater Massage',
    ownerId: 'u_p2',
    category: Category.wellness,
    tagline: 'Deep tissue and sports massage by licensed therapists.',
    address: '1100 S Lamar Blvd',
    lat: 30.2560,
    lng: -97.7640,
    hours: _long,
    colorValue: 0xFF00B894,
    services: const [
      Service(id: 's5', name: 'Swedish 60', minutes: 60, priceCents: 9000),
      Service(id: 's6', name: 'Deep tissue 90', minutes: 90, priceCents: 13500),
      Service(id: 's7', name: 'Sports recovery 45', minutes: 45, priceCents: 7500),
    ],
    reviews: [
      Review(author: 'Alicia M.', stars: 5, text: 'Melted my stress away.', date: _d),
      Review(author: 'Sam K.', stars: 5, text: 'Easy booking and a great therapist.', date: _d),
    ],
  ),
  Business(
    id: 'b3',
    name: 'Peak Personal Training',
    ownerId: 'u_p3',
    category: Category.fitness,
    tagline: '1:1 strength coaching that fits your calendar.',
    address: '2200 E 6th St',
    lat: 30.2615,
    lng: -97.7210,
    hours: _long,
    colorValue: 0xFFE17055,
    services: const [
      Service(id: 's8', name: 'Intro session', minutes: 30, priceCents: 2500),
      Service(id: 's9', name: 'Strength 60', minutes: 60, priceCents: 7000),
      Service(id: 's10', name: 'Partner session', minutes: 60, priceCents: 9500),
    ],
    reviews: [Review(author: 'Chris L.', stars: 5, text: 'Down 15 lb and stronger than ever.', date: _d)],
  ),
  Business(
    id: 'b4',
    name: 'BrightPath Tutoring',
    ownerId: 'u_p4',
    category: Category.tutoring,
    tagline: 'SAT, math and coding tutors, in person or online.',
    address: '500 W 2nd St',
    lat: 30.2650,
    lng: -97.7490,
    hours: _weekdays9to6,
    colorValue: 0xFF0984E3,
    services: const [
      Service(id: 's11', name: 'Math 60', minutes: 60, priceCents: 6000),
      Service(id: 's12', name: 'SAT prep 90', minutes: 90, priceCents: 9000),
      Service(id: 's13', name: 'Intro to coding', minutes: 60, priceCents: 6500),
    ],
    reviews: [
      Review(author: 'Priya S.', stars: 5, text: 'My son went from a C to an A.', date: _d),
      Review(author: 'Ben W.', stars: 4, text: 'Patient and organized.', date: _d),
    ],
  ),
  Business(
    id: 'b5',
    name: 'HandyPro Repairs',
    ownerId: 'u_p5',
    category: Category.home,
    tagline: 'Same-week fixes for the small jobs.',
    address: '3300 N Lamar Blvd',
    lat: 30.3030,
    lng: -97.7450,
    hours: _weekdays9to6,
    colorValue: 0xFFFDCB6E,
    services: const [
      Service(id: 's14', name: 'Handyman hour', minutes: 60, priceCents: 8500),
      Service(id: 's15', name: 'TV mounting', minutes: 90, priceCents: 12000),
    ],
    reviews: [Review(author: 'Rosa G.', stars: 4, text: 'Fast and tidy.', date: _d)],
  ),
  Business(
    id: 'b6',
    name: 'Happy Tails Grooming',
    ownerId: 'u_p6',
    category: Category.pets,
    tagline: 'Gentle grooming for dogs and cats.',
    address: '1801 S 1st St',
    lat: 30.2470,
    lng: -97.7550,
    hours: _sat,
    colorValue: 0xFFE84393,
    services: const [
      Service(id: 's16', name: 'Bath & brush', minutes: 45, priceCents: 4500),
      Service(id: 's17', name: 'Full groom', minutes: 90, priceCents: 8500),
      Service(id: 's18', name: 'Nail trim', minutes: 15, priceCents: 1500),
    ],
    reviews: [
      Review(author: 'Kelly D.', stars: 5, text: 'Our doodle came back looking amazing.', date: _d),
      Review(author: 'Tom H.', stars: 5, text: 'They text you photos!', date: _d),
    ],
    approved: false,
  ),
];

const demoUsers = {
  Role.customer: AppUser(id: 'u_customer', name: 'Taylor Brooks', role: Role.customer),
  Role.provider: AppUser(id: 'u_provider', name: 'Andre Diaz', role: Role.provider, businessId: 'b1'),
  Role.admin: AppUser(id: 'u_admin', name: 'Ops Admin', role: Role.admin),
};

/// Bookings relative to [now] so the demo always looks alive.
List<Booking> seedBookings(DateTime now) {
  DateTime at(int dayOffset, int hour, [int minute = 0]) {
    final d = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  const names = ['Jamie L.', 'Chris P.', 'Morgan S.', 'Riley K.', 'Avery J.', 'Quinn M.', 'Drew H.'];
  final out = <Booking>[
    Booking(
      id: 'bk1',
      businessId: 'b1',
      serviceId: 's2',
      customerId: 'u_customer',
      customerName: 'Taylor Brooks',
      start: at(1, 17),
      minutes: 45,
      totalCents: 4950,
      status: BookingStatus.confirmed,
      paymentRef: 'pi_test_seed1',
    ),
    Booking(
      id: 'bk2',
      businessId: 'b2',
      serviceId: 's5',
      customerId: 'u_customer',
      customerName: 'Taylor Brooks',
      start: at(4, 15),
      minutes: 60,
      totalCents: 9900,
      status: BookingStatus.confirmed,
      paymentRef: 'pi_test_seed2',
    ),
    Booking(
      id: 'bk3',
      businessId: 'b3',
      serviceId: 's9',
      customerId: 'u_customer',
      customerName: 'Taylor Brooks',
      start: at(-6, 18),
      minutes: 60,
      totalCents: 7700,
      status: BookingStatus.completed,
      paymentRef: 'pi_test_seed3',
    ),
  ];
  // A busy shop for the provider dashboard: today + past 13 days.
  var n = 0;
  for (var d = -13; d <= 2; d++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: d));
    if (seedBusinesses[0].hours[day.weekday] == null) continue;
    final slots = d == 0 ? [10, 12, 14] : [10 + d.abs() % 2, 13, 15];
    for (final h in slots) {
      final svc = seedBusinesses[0].services[n % 3];
      out.add(
        Booking(
          id: 'bkp$n',
          businessId: 'b1',
          serviceId: svc.id,
          customerId: 'u_c$n',
          customerName: names[n % names.length],
          start: at(d, h, n.isEven ? 0 : 30),
          minutes: svc.minutes,
          totalCents: (svc.priceCents * 1.1325).round(),
          status: d < 0 ? BookingStatus.completed : BookingStatus.confirmed,
          paymentRef: 'pi_test_p$n',
        ),
      );
      n++;
    }
  }
  // Other shops: a few weeks of history so the admin console has a realistic mix.
  const counts = {'b2': 9, 'b3': 7, 'b4': 6, 'b5': 4};
  var k = 0;
  for (final e in counts.entries) {
    final biz = seedBusinesses.firstWhere((b) => b.id == e.key);
    for (var i = 0; i < e.value; i++) {
      final svc = biz.services[i % biz.services.length];
      out.add(
        Booking(
          id: 'bko$k',
          businessId: biz.id,
          serviceId: svc.id,
          customerId: 'u_o$k',
          customerName: names[(k + 3) % names.length],
          start: at(-1 - (i * 2) % 13, 10 + i % 7),
          minutes: svc.minutes,
          totalCents: (svc.priceCents * 1.1325).round(),
          status: i == 2 ? BookingStatus.cancelled : BookingStatus.completed,
          paymentRef: 'pi_test_o$k',
        ),
      );
      k++;
    }
  }
  return out;
}
