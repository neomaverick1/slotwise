import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/seed.dart';
import '../payments/payments.dart';

/// Overridden in main() with the in-memory or Firestore implementation.
final repositoryProvider = Provider<MarketRepository>((ref) => InMemoryRepository());

final paymentGatewayProvider = Provider<PaymentGateway>((ref) => TestModeGateway());

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class RoleNotifier extends Notifier<Role> {
  @override
  Role build() => initialRoleFromUrl() ?? Role.customer;
  void set(Role role) => state = role;
}

/// Web deep links such as `#/?role=provider` open the app in that role.
Role? initialRoleFromUrl() {
  final base = Uri.base;
  final fromFragment = Uri.tryParse(base.fragment)?.queryParameters['role'];
  return Role.values.asNameMap()[fromFragment ?? base.queryParameters['role']];
}

final roleProvider = NotifierProvider<RoleNotifier, Role>(RoleNotifier.new);

final currentUserProvider = Provider<AppUser>((ref) => demoUsers[ref.watch(roleProvider)]!);

final businessesProvider = StreamProvider<List<Business>>((ref) => ref.watch(repositoryProvider).watchBusinesses());
final bookingsProvider = StreamProvider<List<Booking>>((ref) => ref.watch(repositoryProvider).watchBookings());
final messagesProvider = StreamProvider<List<ChatMessage>>((ref) => ref.watch(repositoryProvider).watchMessages());

class Filters {
  const Filters({this.query = '', this.category});
  final String query;
  final Category? category;
}

class FiltersNotifier extends Notifier<Filters> {
  @override
  Filters build() => const Filters();
  void query(String q) => state = Filters(query: q, category: state.category);
  void category(Category? c) => state = Filters(query: state.query, category: c == state.category ? null : c);
}

final filtersProvider = NotifierProvider<FiltersNotifier, Filters>(FiltersNotifier.new);

/// Approved businesses that match the search box and category chip.
final visibleBusinessesProvider = Provider<List<Business>>((ref) {
  final all = ref.watch(businessesProvider).value ?? const <Business>[];
  final f = ref.watch(filtersProvider);
  final q = f.query.trim().toLowerCase();
  return all.where((b) {
    if (!b.approved) return false;
    if (f.category != null && b.category != f.category) return false;
    if (q.isEmpty) return true;
    return b.name.toLowerCase().contains(q) ||
        b.tagline.toLowerCase().contains(q) ||
        b.services.any((s) => s.name.toLowerCase().contains(q));
  }).toList()..sort((a, b) => b.rating.compareTo(a.rating));
});

final businessByIdProvider = Provider.family<Business?, String>((ref, id) {
  final all = ref.watch(businessesProvider).value ?? const <Business>[];
  for (final b in all) {
    if (b.id == id) return b;
  }
  return null;
});
