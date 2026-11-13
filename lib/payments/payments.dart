import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

/// Result of a payment attempt.
sealed class PaymentResult {
  const PaymentResult();
}

class PaymentSucceeded extends PaymentResult {
  const PaymentSucceeded(this.reference);
  final String reference;
}

class PaymentDeclined extends PaymentResult {
  const PaymentDeclined(this.reason);
  final String reason;
}

class PaymentNeedsAction extends PaymentResult {
  const PaymentNeedsAction(this.message);
  final String message;
}

class CardDetails {
  const CardDetails({required this.number, required this.expiry, required this.cvc, required this.zip});
  final String number;
  final String expiry; // MM/YY
  final String cvc;
  final String zip;

  String get digits => number.replaceAll(RegExp(r'\D'), '');
  String get last4 => digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
}

/// Abstraction over the payment provider so the UI never talks to Stripe directly.
abstract interface class PaymentGateway {
  String get name;

  /// Charge [amountCents] for [bookingId].
  Future<PaymentResult> charge({required String bookingId, required int amountCents, required CardDetails card});
}

/// Card validation shared by the checkout form and the gateways.
class CardValidator {
  static String? number(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    if (d.length < 13 || d.length > 19) return 'Enter a full card number';
    if (!luhn(d)) return 'That card number is not valid';
    return null;
  }

  static String? expiry(String v, {DateTime? now}) {
    final m = RegExp(r'^(\d{2})\s*/\s*(\d{2})$').firstMatch(v.trim());
    if (m == null) return 'Use MM/YY';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'Invalid month';
    final n = now ?? DateTime.now();
    final lastValid = DateTime(year, month + 1);
    if (!lastValid.isAfter(DateTime(n.year, n.month))) {
      return 'Card has expired';
    }
    return null;
  }

  static String? cvc(String v) => RegExp(r'^\d{3,4}$').hasMatch(v.trim()) ? null : '3 or 4 digits';

  static bool luhn(String digits) {
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = digits.codeUnitAt(i) - 48;
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  static String brand(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(d)) return 'Amex';
    if (d.startsWith('6')) return 'Discover';
    return 'Card';
  }
}

/// Offline gateway that behaves like Stripe test mode, using Stripe's published test cards:
/// 4242 4242 4242 4242 succeeds, 4000 0000 0000 0002 is declined,
/// 4000 0000 0000 9995 has insufficient funds, 4000 0025 0000 3155 asks for 3-D Secure.
class TestModeGateway implements PaymentGateway {
  TestModeGateway({this.latency = const Duration(milliseconds: 900), Random? random}) : _random = random ?? Random();

  final Duration latency;
  final Random _random;

  @override
  String get name => 'Test mode (Stripe test cards)';

  @override
  Future<PaymentResult> charge({required String bookingId, required int amountCents, required CardDetails card}) async {
    await Future<void>.delayed(latency);
    final err = CardValidator.number(card.number) ?? CardValidator.expiry(card.expiry) ?? CardValidator.cvc(card.cvc);
    if (err != null) return PaymentDeclined(err);
    if (amountCents < 50) {
      return const PaymentDeclined('Amount must be at least \$0.50');
    }
    switch (card.digits) {
      case '4000000000000002':
        return const PaymentDeclined('Your card was declined.');
      case '4000000000009995':
        return const PaymentDeclined('Your card has insufficient funds.');
      case '4000002500003155':
        return const PaymentNeedsAction('Your bank needs to confirm this payment (3-D Secure).');
    }
    final id = List.generate(14, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[_random.nextInt(36)]).join();
    return PaymentSucceeded('pi_test_$id');
  }
}

/// Opens a Stripe Payment Link (created in the Stripe dashboard in test mode) in the browser.
/// Configure with --dart-define=STRIPE_PAYMENT_LINK=https://buy.stripe.com/test_...
class StripePaymentLink {
  static const url = String.fromEnvironment('STRIPE_PAYMENT_LINK');
  static bool get configured => url.isNotEmpty;

  static Uri build({required String bookingId, String? email}) {
    final base = Uri.parse(url);
    return base.replace(
      queryParameters: {...base.queryParameters, 'client_reference_id': bookingId, 'prefilled_email': ?email},
    );
  }

  static Future<bool> open({required String bookingId, String? email}) => launchUrl(
    build(bookingId: bookingId, email: email),
    mode: LaunchMode.externalApplication,
  );
}
