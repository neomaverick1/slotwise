/// Checkout price breakdown. All values in cents.
class Quote {
  const Quote({required this.subtotal, required this.serviceFee, required this.tax, required this.discount});

  final int subtotal;
  final int serviceFee;
  final int tax;
  final int discount;

  int get total => subtotal + serviceFee + tax - discount;

  /// What the provider receives after the platform commission.
  int providerPayout({double commission = 0.12}) => ((subtotal - discount) * (1 - commission)).round();
}

/// Known promo codes for the demo (code -> percent off the subtotal).
const promoCodes = {'WELCOME10': 10, 'SLOT20': 20};

/// Builds a quote: 5% booking fee (min \$0.99), 8.25% tax on the discounted subtotal,
/// optional promo code.
Quote quote(int subtotalCents, {String? promo}) {
  final pct = promoCodes[promo?.trim().toUpperCase()] ?? 0;
  final discount = (subtotalCents * pct / 100).round();
  final fee = (subtotalCents * 0.05).round().clamp(99, 1 << 30);
  final tax = ((subtotalCents - discount) * 0.0825).round();
  return Quote(subtotal: subtotalCents, serviceFee: fee, tax: tax, discount: discount);
}

String money(int cents) {
  final neg = cents < 0;
  final c = cents.abs();
  final dollars = c ~/ 100;
  final rest = (c % 100).toString().padLeft(2, '0');
  final grouped = dollars.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${neg ? '-' : ''}\$$grouped.$rest';
}
