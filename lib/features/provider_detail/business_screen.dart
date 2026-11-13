import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/pricing.dart';
import '../../widgets/common.dart';

class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(businessByIdProvider(businessId));
    final user = ref.watch(currentUserProvider);
    if (b == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final color = Color(b.colorValue);
    final open = b.hours.entries.toList()..sort((a, c) => a.key.compareTo(c.key));
    return Scaffold(
      body: Readable(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: color,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, Color.lerp(color, Colors.black, 0.35)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(b.category.emoji, style: const TextStyle(fontSize: 54)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.tagline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Pill(
                      '${b.rating.toStringAsFixed(1)} ★  ${b.reviews.length} reviews',
                      color: const Color(0xFFE09B00),
                    ),
                    Pill(b.address, color: ink, icon: Icons.place_rounded),
                    Pill(b.category.label, color: color),
                  ],
                ),
              ),
            ),
            if (user.role == Role.customer)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/chat/${b.id}|${user.id}'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message the business'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SectionTitle('Services')),
            SliverList.separated(
              itemCount: b.services.where((s) => s.active).length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = b.services.where((s) => s.active).elementAt(i);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${s.minutes} min${s.description.isEmpty ? '' : ' · ${s.description}'}'),
                      trailing: FilledButton(
                        key: Key('book_${s.id}'),
                        style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                        onPressed: () => context.push('/book/${b.id}/${s.id}'),
                        child: Text(money(s.priceCents)),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SectionTitle('Opening hours')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var d = 1; d <= 7; d++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(width: 110, child: Text(DateFormat.EEEE().format(DateTime(2026, 11, 8 + d)))),
                                Text(
                                  open.any((e) => e.key == d) ? _range(b.hours[d]!) : 'Closed',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionTitle('Reviews')),
            SliverList.list(
              children: [
                for (final r in b.reviews)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Text(r.author[0])),
                        title: Row(
                          children: [
                            Text(r.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text('★' * r.stars, style: const TextStyle(color: Color(0xFFFFB800))),
                          ],
                        ),
                        subtitle: Text(r.text),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _range((int, int) h) {
    String f(int m) => DateFormat.jm().format(DateTime(2026, 1, 1, m ~/ 60, m % 60));
    return '${f(h.$1)} – ${f(h.$2)}';
  }
}
