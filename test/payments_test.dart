import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:slotwise/payments/payments.dart';

void main() {
  CardDetails card(String n, {String exp = '12/30', String cvc = '123'}) =>
      CardDetails(number: n, expiry: exp, cvc: cvc, zip: '78701');

  group('CardValidator', () {
    test('Luhn', () {
      expect(CardValidator.luhn('4242424242424242'), isTrue);
      expect(CardValidator.luhn('4242424242424241'), isFalse);
    });
    test('number', () {
      expect(CardValidator.number('4242 4242 4242 4242'), isNull);
      expect(CardValidator.number('4242'), isNotNull);
    });
    test('expiry', () {
      final now = DateTime(2026, 11, 13);
      expect(CardValidator.expiry('11/26', now: now), isNull);
      expect(CardValidator.expiry('10/26', now: now), 'Card has expired');
      expect(CardValidator.expiry('13/27', now: now), 'Invalid month');
      expect(CardValidator.expiry('1227', now: now), 'Use MM/YY');
    });
    test('brand', () {
      expect(CardValidator.brand('4242'), 'Visa');
      expect(CardValidator.brand('5555 5555'), 'Mastercard');
      expect(CardValidator.brand('3782'), 'Amex');
    });
  });

  group('TestModeGateway mirrors Stripe test cards', () {
    final gw = TestModeGateway(latency: Duration.zero, random: Random(1));

    test('4242 succeeds with a pi_test reference', () async {
      final r = await gw.charge(bookingId: 'b', amountCents: 5000, card: card('4242424242424242'));
      expect(r, isA<PaymentSucceeded>());
      expect((r as PaymentSucceeded).reference, startsWith('pi_test_'));
    });
    test('0002 is declined', () async {
      final r = await gw.charge(bookingId: 'b', amountCents: 5000, card: card('4000000000000002'));
      expect((r as PaymentDeclined).reason, contains('declined'));
    });
    test('9995 insufficient funds', () async {
      final r = await gw.charge(bookingId: 'b', amountCents: 5000, card: card('4000000000009995'));
      expect((r as PaymentDeclined).reason, contains('insufficient'));
    });
    test('3155 needs 3-D Secure', () async {
      final r = await gw.charge(bookingId: 'b', amountCents: 5000, card: card('4000002500003155'));
      expect(r, isA<PaymentNeedsAction>());
    });
    test('bad CVC and tiny amounts are rejected', () async {
      expect(
        await gw.charge(
          bookingId: 'b',
          amountCents: 5000,
          card: card('4242424242424242', cvc: '1'),
        ),
        isA<PaymentDeclined>(),
      );
      expect(await gw.charge(bookingId: 'b', amountCents: 10, card: card('4242424242424242')), isA<PaymentDeclined>());
    });
  });
}
