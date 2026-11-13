import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:slotwise/app.dart';
import 'package:slotwise/core/providers.dart';
import 'package:slotwise/data/models.dart';
import 'package:slotwise/data/repository.dart';
import 'package:slotwise/payments/payments.dart';

void main() {
  final now = DateTime(2026, 11, 17, 8); // Tuesday morning
  late InMemoryRepository repo;

  Widget app() => ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(() => now),
      paymentGatewayProvider.overrideWithValue(TestModeGateway(latency: Duration.zero)),
    ],
    child: const SlotwiseApp(),
  );

  setUp(() => repo = InMemoryRepository(clock: () => now, autoReply: false));

  Future<void> bookAHaircut(WidgetTester tester, {String card = '4242 4242 4242 4242'}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Book anything, in seconds'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('search')), 'fade');
    await tester.pumpAndSettle();
    expect(find.text('Stillwater Massage'), findsNothing);
    await tester.tap(find.text('Fade & Co. Barbers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('book_s1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('slot_17_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slot_17_0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Continue ·'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cardNumber')), card);
    await tester.ensureVisible(find.byKey(const Key('pay')));
    await tester.tap(find.byKey(const Key('pay')));
    await tester.pumpAndSettle();
  }

  testWidgets('customer books and pays with the Stripe success test card', (tester) async {
    await bookAHaircut(tester);
    expect(find.text("You're booked!"), findsOneWidget);
    final saved = (await repo.watchBookings().first).where((b) => b.customerId == 'u_customer' && b.serviceId == 's1');
    expect(saved.single.status, BookingStatus.confirmed);
    expect(saved.single.start, DateTime(2026, 11, 17, 17));
    expect(saved.single.paymentRef, startsWith('pi_test_'));
  });

  testWidgets('declined card shows the error and frees the slot', (tester) async {
    await bookAHaircut(tester, card: '4000 0000 0000 0002');
    expect(find.byKey(const Key('payError')), findsOneWidget);
    expect(find.text('Your card was declined.'), findsOneWidget);
    final saved = (await repo.watchBookings().first).where((b) => b.customerId == 'u_customer' && b.serviceId == 's1');
    expect(saved.single.status, BookingStatus.cancelled);
  });

  testWidgets('role switch shows the provider dashboard and admin console', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Earnings this week'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Console'));
    await tester.pumpAndSettle();
    expect(find.text('Provider approvals'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('approve_b6')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approve_b6')));
    await tester.pumpAndSettle();
    final biz = await repo.watchBusinesses().first;
    expect(biz.firstWhere((b) => b.id == 'b6').approved, isTrue);
    expect(find.byKey(const Key('approve_b6')), findsNothing);
    expect(find.textContaining('caught up', skipOffstage: false), findsOneWidget);
  });
}
