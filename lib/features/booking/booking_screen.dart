import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../domain/pricing.dart';
import '../../payments/payments.dart';
import '../../widgets/common.dart';
import 'slot_picker.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.businessId, required this.serviceId});
  final String businessId;
  final String serviceId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _picked;

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(businessByIdProvider(widget.businessId));
    if (b == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = b.services.firstWhere((x) => x.id == widget.serviceId);
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a time')),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Card(
                child: ListTile(
                  leading: BusinessAvatar(b, size: 44),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${b.name} · ${s.minutes} min'),
                  trailing: Text(
                    money(s.priceCents),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ),
            SlotPicker(business: b, service: s, selected: _picked, onPicked: (t) => setState(() => _picked = t)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            key: const Key('continue'),
            onPressed: _picked == null ? null : () => _checkout(b, s, _picked!),
            child: Text(
              _picked == null ? 'Select a time' : 'Continue · ${DateFormat('EEE, MMM d · h:mm a').format(_picked!)}',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkout(Business b, Service s, DateTime start) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (_) => CheckoutSheet(business: b, service: s, start: start),
    );
    if (id != null && mounted) context.go('/confirmed/$id');
  }
}

/// Price breakdown, promo code and card entry. Returns the confirmed booking id.
class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({super.key, required this.business, required this.service, required this.start});
  final Business business;
  final Service service;
  final DateTime start;

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  final _form = GlobalKey<FormState>();
  final _promo = TextEditingController();
  final _card = TextEditingController(text: '4242 4242 4242 4242');
  final _exp = TextEditingController(text: '12/30');
  final _cvc = TextEditingController(text: '123');
  final _zip = TextEditingController(text: '78701');
  String? _applied;
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final q = quote(widget.service.priceCents, promo: _applied);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Checkout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                '${widget.service.name} at ${widget.business.name}\n${DateFormat('EEEE, MMMM d · h:mm a').format(widget.start)}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Service', money(q.subtotal)),
                      if (q.discount > 0) _row('Promo $_applied', money(-q.discount), color: mint),
                      _row('Booking fee', money(q.serviceFee)),
                      _row('Tax (8.25%)', money(q.tax)),
                      const Divider(height: 22),
                      _row('Total', money(q.total), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('promo'),
                      controller: _promo,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Promo code',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final code = _promo.text.trim().toUpperCase();
                      setState(() => _applied = promoCodes.containsKey(code) ? code : null);
                      if (!promoCodes.containsKey(code)) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('That code is not valid')));
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text('Card', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Pill('TEST MODE', color: const Color(0xFFFF9F1C), icon: Icons.science_outlined),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('cardNumber'),
                controller: _card,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(23),
                ],
                validator: (v) => CardValidator.number(v ?? ''),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Card number',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  suffixText: CardValidator.brand(_card.text),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _exp,
                      validator: (v) => CardValidator.expiry(v ?? ''),
                      decoration: const InputDecoration(labelText: 'MM/YY'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cvc,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: (v) => CardValidator.cvc(v ?? ''),
                      decoration: const InputDecoration(labelText: 'CVC'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _zip,
                      decoration: const InputDecoration(labelText: 'ZIP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Try 4000 0000 0000 0002 to see a decline, or 4000 0025 0000 3155 for 3-D Secure.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    key: const Key('payError'),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('pay'),
                onPressed: _busy ? null : () => _pay(q),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Pay ${money(q.total)}'),
              ),
              if (StripePaymentLink.configured) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _payWithStripe(q),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Pay with Stripe Checkout (test)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          a,
          style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, fontSize: bold ? 17 : 14),
        ),
        const Spacer(),
        Text(
          b,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontSize: bold ? 17 : 14,
            color: color,
          ),
        ),
      ],
    ),
  );

  Future<Booking?> _reserve(Quote q) async {
    final repo = ref.read(repositoryProvider);
    try {
      return await repo.createBooking(
        business: widget.business,
        service: widget.service,
        customer: ref.read(currentUserProvider),
        start: widget.start,
        totalCents: q.total,
      );
    } on SlotTakenException catch (e) {
      setState(() => _error = e.toString());
      return null;
    }
  }

  Future<void> _pay(Quote q) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(repositoryProvider);
    final booking = await _reserve(q);
    if (booking == null) {
      setState(() => _busy = false);
      return;
    }
    final result = await ref
        .read(paymentGatewayProvider)
        .charge(
          bookingId: booking.id,
          amountCents: q.total,
          card: CardDetails(number: _card.text, expiry: _exp.text, cvc: _cvc.text, zip: _zip.text),
        );
    if (!mounted) return;
    switch (result) {
      case PaymentSucceeded(:final reference):
        await repo.setBookingStatus(booking.id, BookingStatus.confirmed, paymentRef: reference);
        if (mounted) Navigator.of(context).pop(booking.id);
      case PaymentDeclined(:final reason):
        await repo.setBookingStatus(booking.id, BookingStatus.cancelled);
        setState(() => _error = reason);
      case PaymentNeedsAction(:final message):
        final ok = await _confirm3ds(message);
        if (ok) {
          await repo.setBookingStatus(
            booking.id,
            BookingStatus.confirmed,
            paymentRef: 'pi_test_3ds_${booking.id.substring(0, 8)}',
          );
          if (mounted) Navigator.of(context).pop(booking.id);
        } else {
          await repo.setBookingStatus(booking.id, BookingStatus.cancelled);
          setState(() => _error = 'Authentication failed. You were not charged.');
        }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _payWithStripe(Quote q) async {
    final booking = await _reserve(q);
    if (booking == null) return;
    await StripePaymentLink.open(bookingId: booking.id);
    if (mounted) Navigator.of(context).pop(booking.id);
  }

  Future<bool> _confirm3ds(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.verified_user_outlined),
          title: const Text('Confirm with your bank'),
          content: Text('$message\n\nThis is the test-mode 3-D Secure screen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Fail')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Complete')),
          ],
        ),
      ) ??
      false;
}
