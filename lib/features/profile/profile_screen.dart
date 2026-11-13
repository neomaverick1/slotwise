import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../payments/payments.dart';
import '../../widgets/common.dart';

const backendName = String.fromEnvironment('BACKEND', defaultValue: 'demo');

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(roleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Readable(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: brand,
                      child: Text(
                        user.name.split(' ').map((p) => p[0]).take(2).join(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Pill(role.name[0].toUpperCase() + role.name.substring(1), color: brand),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Demo: switch role'),
            SegmentedButton<Role>(
              key: const Key('roleSwitch'),
              segments: const [
                ButtonSegment(value: Role.customer, label: Text('Customer'), icon: Icon(Icons.person_rounded)),
                ButtonSegment(value: Role.provider, label: Text('Provider'), icon: Icon(Icons.storefront_rounded)),
                ButtonSegment(value: Role.admin, label: Text('Admin'), icon: Icon(Icons.admin_panel_settings_rounded)),
              ],
              selected: {role},
              onSelectionChanged: (s) => ref.read(roleProvider.notifier).set(s.first),
            ),
            const SizedBox(height: 8),
            const Text(
              'One app, three roles: customers book and pay, providers run their day, admins run the marketplace.',
              style: TextStyle(color: Colors.black54),
            ),
            const SectionTitle('Setup'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Backend'),
                    subtitle: Text(
                      backendName == 'firebase' ? 'Cloud Firestore (real-time sync)' : 'Demo mode (in-memory, works offline). Build with --dart-define=BACKEND=firebase for Firestore.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.credit_card_rounded),
                    title: const Text('Payments'),
                    subtitle: Text(
                      StripePaymentLink.configured
                          ? 'Stripe test mode: card form + Stripe Checkout link'
                          : 'Stripe test cards, validated and processed in test mode',
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
