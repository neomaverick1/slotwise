import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'data/models.dart';
import 'features/admin/admin_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/bookings/bookings_screen.dart';
import 'features/chat/chat_screens.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/provider_detail/business_screen.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (_, s) => HomeShell(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0),
    ),
    GoRoute(
      path: '/business/:id',
      builder: (_, s) => BusinessScreen(businessId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/book/:bid/:sid',
      builder: (_, s) => BookingScreen(businessId: s.pathParameters['bid']!, serviceId: s.pathParameters['sid']!),
    ),
    GoRoute(
      path: '/confirmed/:id',
      builder: (_, s) => ConfirmedScreen(bookingId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:thread',
      builder: (_, s) => ChatScreen(threadId: s.pathParameters['thread']!),
    ),
  ],
);

class SlotwiseApp extends ConsumerStatefulWidget {
  const SlotwiseApp({super.key, this.initialLocation = '/'});
  final String initialLocation;

  @override
  ConsumerState<SlotwiseApp> createState() => _SlotwiseAppState();
}

class _SlotwiseAppState extends ConsumerState<SlotwiseApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Slotwise',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: _router,
  );
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

List<_Tab> _tabsFor(Role role) => switch (role) {
  Role.customer => const [
    _Tab('Explore', Icons.explore_outlined, Icons.explore_rounded, ExploreScreen()),
    _Tab('Bookings', Icons.event_note_outlined, Icons.event_note_rounded, BookingsScreen()),
    _Tab('Messages', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, InboxScreen()),
    _Tab('Profile', Icons.person_outline_rounded, Icons.person_rounded, ProfileScreen()),
  ],
  Role.provider => const [
    _Tab('Dashboard', Icons.insights_outlined, Icons.insights_rounded, DashboardScreen()),
    _Tab('Schedule', Icons.calendar_month_outlined, Icons.calendar_month_rounded, BookingsScreen()),
    _Tab('Messages', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, InboxScreen()),
    _Tab('Profile', Icons.person_outline_rounded, Icons.person_rounded, ProfileScreen()),
  ],
  Role.admin => const [
    _Tab('Console', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, AdminScreen()),
    _Tab('Explore', Icons.explore_outlined, Icons.explore_rounded, ExploreScreen()),
    _Tab('Profile', Icons.person_outline_rounded, Icons.person_rounded, ProfileScreen()),
  ],
};

/// Bottom navigation on phones, navigation rail on tablets and the web.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    ref.listen(roleProvider, (_, _) => setState(() => _index = _tabsFor(ref.read(roleProvider)).length - 1));
    final tabs = _tabsFor(ref.watch(roleProvider));
    final i = _index.clamp(0, tabs.length - 1);
    final body = IndexedStack(index: i, children: [for (final t in tabs) t.page]);
    if (MediaQuery.sizeOf(context).width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: i,
              onDestinationSelected: (v) => setState(() => _index = v),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Slotwise',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: brand),
                ),
              ),
              destinations: [
                for (final t in tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: Text(t.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
        ],
      ),
    );
  }
}
