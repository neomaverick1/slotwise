import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../domain/pricing.dart';
import '../../widgets/common.dart';
import '../booking/slot_picker.dart';

/// Customer bookings (or the provider's schedule when signed in as a provider).
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider)();
    final all = (ref.watch(bookingsProvider).value ?? const <Booking>[]).where(
      (b) => user.role == Role.provider ? b.businessId == user.businessId : b.customerId == user.id,
    );
    final upcoming = all.where((b) => b.isActive && b.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final past = all.where((b) => !(b.isActive && b.end.isAfter(now))).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(user.role == Role.provider ? 'Schedule' : 'Bookings'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming (${upcoming.length})'),
              Tab(text: 'Past (${past.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(upcoming, empty: 'No upcoming bookings', showActions: true),
            _BookingList(past, empty: 'Nothing here yet', showActions: false),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList(this.items, {required this.empty, required this.showActions});
  final List<Booking> items;
  final String empty;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_rounded,
        title: empty,
        body: 'Book a service from Explore to see it here.',
      );
    }
    return Readable(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => BookingCard(items[i], showActions: showActions),
      ),
    );
  }
}

final _compact = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  minimumSize: const Size(0, 42),
);

class BookingCard extends ConsumerWidget {
  const BookingCard(this.booking, {super.key, this.showActions = true});
  final Booking booking;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(businessByIdProvider(booking.businessId));
    final user = ref.watch(currentUserProvider);
    if (b == null) return const SizedBox.shrink();
    final s = b.services.firstWhere((x) => x.id == booking.serviceId, orElse: () => b.services.first);
    final isProvider = user.role == Role.provider;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BusinessAvatar(b, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProvider ? booking.customerName : b.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text('${s.name} · ${booking.minutes} min', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Pill(booking.status.label, color: statusColor(booking.status)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18, color: brand),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(booking.start),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(money(booking.totalCents), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            if (showActions && booking.isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/chat/${b.id}|${booking.customerId}'),
                      style: _compact,
                      child: const FittedBox(child: Text('Message')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reschedule(context, ref, b, s),
                      style: _compact,
                      child: const FittedBox(child: Text('Reschedule')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      onPressed: () => _cancel(context, ref),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('Free cancellation up to 12 hours before. In test mode the refund is instant.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cancel booking')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).setBookingStatus(booking.id, BookingStatus.cancelled);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Cancelled · ${money(booking.totalCents)} refunded')));
      }
    }
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref, Business b, Service s) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (c) => SizedBox(
        height: MediaQuery.sizeOf(c).height * 0.7,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Pick a new time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            SlotPicker(business: b, service: s, ignoreBookingId: booking.id, onPicked: (t) => Navigator.pop(c, t)),
          ],
        ),
      ),
    );
    if (picked == null) return;
    try {
      await ref.read(repositoryProvider).reschedule(booking.id, picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Moved to ${DateFormat('EEE, MMM d · h:mm a').format(picked)}')));
      }
    } on SlotTakenException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class ConfirmedScreen extends ConsumerWidget {
  const ConfirmedScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(bookingsProvider).value ?? const <Booking>[];
    final booking = list.where((b) => b.id == bookingId).firstOrNull;
    final b = booking == null ? null : ref.watch(businessByIdProvider(booking.businessId));
    return Scaffold(
      body: SafeArea(
        child: Readable(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                ),
                const SizedBox(height: 20),
                Text(
                  booking?.status == BookingStatus.pendingPayment ? 'Finish paying in Stripe' : "You're booked!",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (booking != null && b != null)
                  Text(
                    '${b.name}\n${DateFormat('EEEE, MMMM d · h:mm a').format(booking.start)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                if (booking?.paymentRef != null) ...[
                  const SizedBox(height: 14),
                  Pill(
                    'Paid ${money(booking!.totalCents)} · ${booking.paymentRef}',
                    color: brand,
                    icon: Icons.receipt_long_rounded,
                  ),
                ],
                const Spacer(),
                FilledButton(
                  key: const Key('viewBookings'),
                  onPressed: () => context.go('/?tab=1'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: const Text('View my bookings'),
                ),
                TextButton(onPressed: () => context.go('/'), child: const Text('Back to Explore')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
