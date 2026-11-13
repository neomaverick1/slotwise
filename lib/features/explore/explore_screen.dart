import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/availability.dart';
import '../../domain/pricing.dart';
import '../../widgets/common.dart';

/// First free slot in the next week, for the "Next: Tue 2:30 PM" badge.
final nextSlotProvider = Provider.family<DateTime?, String>((ref, businessId) {
  final b = ref.watch(businessByIdProvider(businessId));
  final bookings = ref.watch(bookingsProvider).value ?? const <Booking>[];
  if (b == null) return null;
  final now = ref.watch(clockProvider)();
  final service = b.services.firstWhere((s) => s.active, orElse: () => b.services.first);
  for (var d = 0; d < 7; d++) {
    final slots = freeSlots(
      business: b,
      service: service,
      day: now.add(Duration(days: d)),
      bookings: bookings,
      now: now,
    );
    if (slots.isNotEmpty) return slots.first.start;
  }
  return null;
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _map = false;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(visibleBusinessesProvider);
    final filters = ref.watch(filtersProvider);
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: Readable(
          maxWidth: 900,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi ${user.name.split(' ').first} 👋',
                              style: const TextStyle(color: Colors.black54, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Book anything, in seconds',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: ink,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        key: const Key('mapToggle'),
                        onPressed: () => setState(() => _map = !_map),
                        icon: Icon(_map ? Icons.view_list_rounded : Icons.map_rounded),
                        tooltip: _map ? 'List' : 'Map',
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: TextField(
                    key: const Key('search'),
                    onChanged: ref.read(filtersProvider.notifier).query,
                    decoration: const InputDecoration(
                      hintText: 'Search haircut, massage, tutor…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      for (final c in Category.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            avatar: Text(c.emoji),
                            label: Text(c.label),
                            selected: filters.category == c,
                            showCheckmark: false,
                            onSelected: (_) => ref.read(filtersProvider.notifier).category(c),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_map)
                SliverToBoxAdapter(child: _MapView(list))
              else ...[
                const SliverToBoxAdapter(child: _PromoBanner()),
                SliverToBoxAdapter(child: SectionTitle('Top rated near you', trailing: Text('${list.length} places'))),
                if (list.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      body: 'Try another search or category.',
                    ),
                  ),
                SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: BusinessCard(list[i])),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(colors: [brand, brandDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '10% off your first booking',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
              SizedBox(height: 4),
              Text('Use code WELCOME10 at checkout', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        Text('🎉', style: TextStyle(fontSize: 34)),
      ],
    ),
  );
}

class BusinessCard extends ConsumerWidget {
  const BusinessCard(this.business, {super.key});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextSlotProvider(business.id));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/business/${business.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              BusinessAvatar(business, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Stars(business.rating, count: business.reviews.length, size: 13),
                        Text(
                          'from ${money(business.fromPriceCents)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                        ),
                        if (next != null) Pill('Next ${_when(next)}', color: mint, icon: Icons.bolt_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _when(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day).difference(today).inDays;
    final time = DateFormat.jm().format(t);
    if (d == 0) return 'today $time';
    if (d == 1) return 'tmrw $time';
    return '${DateFormat.E().format(t)} $time';
  }
}

class _MapView extends StatelessWidget {
  const _MapView(this.list);
  final List<Business> list;

  @override
  Widget build(BuildContext context) => Container(
    height: 520,
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
    child: FlutterMap(
      options: const MapOptions(initialCenter: LatLng(30.272, -97.745), initialZoom: 12.9),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.neomaverick.slotwise',
        ),
        MarkerLayer(
          markers: [
            for (final b in list)
              Marker(
                point: LatLng(b.lat, b.lng),
                width: 150,
                height: 44,
                child: GestureDetector(
                  onTap: () => context.push('/business/${b.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(b.category.emoji),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            b.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
      ],
    ),
  );
}
