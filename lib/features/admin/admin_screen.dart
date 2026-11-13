import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/pricing.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/common.dart';

/// Marketplace admin console: GMV, revenue, approvals and the booking ledger.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessesProvider).value ?? const <Business>[];
    final bookings = (ref.watch(bookingsProvider).value ?? const <Booking>[]).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    final paid = bookings.where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.completed);
    final gmv = paid.fold<int>(0, (a, b) => a + b.totalCents);
    final takeRate = (gmv * 0.12).round();
    final cancelled = bookings.where((b) => b.status == BookingStatus.cancelled).length;
    final pending = businesses.where((b) => !b.approved).toList();
    final byCat = {
      for (final c in Category.values)
        c: paid.where((b) => businesses.firstWhere((x) => x.id == b.businessId).category == c).length.toDouble(),
    };
    final wide = MediaQuery.sizeOf(context).width > 900;

    final kpis = [
      KpiCard(label: 'Gross bookings (GMV)', value: money(gmv), icon: Icons.trending_up_rounded, color: mint),
      KpiCard(label: 'Platform revenue (12%)', value: money(takeRate), icon: Icons.account_balance_rounded),
      KpiCard(
        label: 'Paid bookings',
        value: '${paid.length}',
        icon: Icons.event_available_rounded,
        color: const Color(0xFF0984E3),
      ),
      KpiCard(
        label: 'Cancellation rate',
        value: bookings.isEmpty ? '0%' : '${(cancelled / bookings.length * 100).toStringAsFixed(1)}%',
        icon: Icons.event_busy_rounded,
        color: Colors.redAccent,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Admin console')),
      body: Readable(
        maxWidth: 1200,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          children: [
            GridView.count(
              crossAxisCount: wide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: wide ? 2.5 : 1.1,
              children: kpis,
            ),
            const SizedBox(height: 18),
            Builder(
              builder: (context) {
                final categories = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bookings by category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 16),
                        BarChart(
                          values: byCat.values.toList(),
                          labels: [for (final c in byCat.keys) c.emoji],
                          highlightLast: false,
                          height: 130,
                        ),
                      ],
                    ),
                  ),
                );
                final approvals = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Provider approvals',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            Pill('${pending.length} waiting', color: const Color(0xFFFF9F1C)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pending.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('All caught up ✅')),
                        for (final b in pending)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: BusinessAvatar(b, size: 42),
                            title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${b.category.label} · ${b.address}'),
                            trailing: FilledButton(
                              key: Key('approve_${b.id}'),
                              style: FilledButton.styleFrom(minimumSize: const Size(90, 40)),
                              onPressed: () => ref.read(repositoryProvider).saveBusiness(b.copyWith(approved: true)),
                              child: const Text('Approve'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: categories),
                          const SizedBox(width: 14),
                          Expanded(child: approvals),
                        ],
                      )
                    : Column(children: [categories, const SizedBox(height: 14), approvals]);
              },
            ),
            const SizedBox(height: 18),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text('Latest bookings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: ink),
                      columns: const [
                        DataColumn(label: Text('When')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Business')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Total'), numeric: true),
                        DataColumn(label: Text('Payment')),
                      ],
                      rows: [
                        for (final b in bookings.take(12))
                          DataRow(
                            cells: [
                              DataCell(Text(DateFormat('MMM d, h:mm a').format(b.start))),
                              DataCell(Text(b.customerName)),
                              DataCell(Text(businesses.firstWhere((x) => x.id == b.businessId).name)),
                              DataCell(Pill(b.status.label, color: statusColor(b.status))),
                              DataCell(Text(money(b.totalCents))),
                              DataCell(
                                Text(
                                  b.paymentRef ?? '—',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
