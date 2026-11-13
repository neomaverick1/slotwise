import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/pricing.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/common.dart';

/// Provider (business owner) home: today, earnings, service menu.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final b = ref.watch(businessByIdProvider(user.businessId ?? ''));
    final now = ref.watch(clockProvider)();
    if (b == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mine = (ref.watch(bookingsProvider).value ?? const <Booking>[])
        .where((x) => x.businessId == b.id && x.status != BookingStatus.cancelled)
        .toList();
    final today = DateTime(now.year, now.month, now.day);
    final todays = mine.where((x) => _sameDay(x.start, today)).toList()..sort((a, c) => a.start.compareTo(c.start));
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final perDay = [
      for (final d in days)
        mine.where((x) => _sameDay(x.start, d)).fold<int>(0, (a, x) => a + quote(_price(b, x)).providerPayout()) / 100,
    ];
    final week = perDay.fold<double>(0, (a, v) => a + v);
    final prevWeek =
        mine
            .where((x) => x.start.isBefore(days.first) && x.start.isAfter(days.first.subtract(const Duration(days: 7))))
            .fold<int>(0, (a, x) => a + quote(_price(b, x)).providerPayout()) /
        100;
    final pct = prevWeek == 0 ? 0 : ((week - prevWeek) / prevWeek * 100).round();
    final delta = pct == 0 ? null : '${pct > 0 ? '+' : ''}$pct% vs last wk';

    return Scaffold(
      appBar: AppBar(title: Text(b.name)),
      body: Readable(
        maxWidth: 900,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${DateFormat('EEEE, MMMM d').format(now)} · ${todays.length} appointments today',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      label: 'Earned · 7d',
                      value: '\$${week.toStringAsFixed(0)}',
                      delta: delta,
                      icon: Icons.payments_rounded,
                      color: mint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KpiCard(
                      label: 'Bookings · 7d',
                      value:
                          '${mine.where((x) => !x.start.isBefore(days.first) && x.start.isBefore(today.add(const Duration(days: 1)))).length}',
                      icon: Icons.event_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KpiCard(
                      label: 'Rating',
                      value: b.rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: const Color(0xFFE09B00),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Earnings this week'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                  child: BarChart(
                    values: perDay,
                    labels: [for (final d in days) DateFormat.E().format(d).substring(0, 2)],
                  ),
                ),
              ),
            ),
            const SectionTitle('Today'),
            if (todays.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('No appointments today.')),
            for (final x in todays)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Card(
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('h:mm').format(x.start),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        Text(
                          DateFormat('a').format(x.start),
                          style: const TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                    title: Text(x.customerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${b.services.firstWhere((s) => s.id == x.serviceId).name} · ${x.minutes} min'),
                    trailing: Pill(
                      x.end.isBefore(now) ? 'Done' : (x.start.isBefore(now) ? 'In chair' : 'Upcoming'),
                      color: x.end.isBefore(now) ? Colors.black45 : (x.start.isBefore(now) ? mint : brand),
                    ),
                  ),
                ),
              ),
            const SectionTitle('Service menu'),
            for (final s in b.services)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Card(
                  child: SwitchListTile(
                    value: s.active,
                    activeThumbColor: brand,
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${s.minutes} min · ${money(s.priceCents)}'),
                    onChanged: (v) => ref
                        .read(repositoryProvider)
                        .saveBusiness(
                          b.copyWith(
                            services: [
                              for (final x in b.services)
                                if (x.id == s.id) x.copyWith(active: v) else x,
                            ],
                          ),
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _price(Business b, Booking x) =>
      b.services.firstWhere((s) => s.id == x.serviceId, orElse: () => b.services.first).priceCents;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
