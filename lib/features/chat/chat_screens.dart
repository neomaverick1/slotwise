import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final msgs = ref.watch(messagesProvider).value ?? const <ChatMessage>[];
    final mine = msgs.where((m) {
      final parts = m.threadId.split('|');
      return user.role == Role.provider
          ? parts[0] == user.businessId
          : (user.role == Role.admin || parts[1] == user.id);
    });
    final latest = <String, ChatMessage>{};
    for (final m in mine) {
      if (latest[m.threadId] == null || m.sent.isAfter(latest[m.threadId]!.sent)) {
        latest[m.threadId] = m;
      }
    }
    final threads = latest.values.toList()..sort((a, b) => b.sent.compareTo(a.sent));
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threads.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No messages yet',
              body: 'Message a business from its page.',
            )
          : Readable(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: threads.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final m = threads[i];
                  final parts = m.threadId.split('|');
                  final b = ref.watch(businessByIdProvider(parts[0]));
                  if (b == null) return const SizedBox.shrink();
                  final title = user.role == Role.provider ? _customerName(ref, parts[1]) : b.name;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: BusinessAvatar(b, size: 46),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(m.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(_ago(m.sent), style: const TextStyle(color: Colors.black45, fontSize: 12)),
                      onTap: () => context.push('/chat/${m.threadId}'),
                    ),
                  );
                },
              ),
            ),
    );
  }

  static String _customerName(WidgetRef ref, String customerId) {
    final bookings = ref.watch(bookingsProvider).value ?? const <Booking>[];
    return bookings.where((b) => b.customerId == customerId).firstOrNull?.customerName ?? 'Customer';
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return DateFormat.MMMd().format(t);
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.threadId});
  final String threadId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final b = ref.watch(businessByIdProvider(widget.threadId.split('|').first));
    final msgs =
        (ref.watch(messagesProvider).value ?? const <ChatMessage>[])
            .where((m) => m.threadId == widget.threadId)
            .toList()
          ..sort((a, c) => c.sent.compareTo(a.sent));
    final me = user.role == Role.provider ? b?.ownerId : user.id;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (b != null) BusinessAvatar(b, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(b?.name ?? 'Chat', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
      body: Readable(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final mine = m.fromId == me;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: mine ? brand : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(m.text, style: TextStyle(color: mine ? Colors.white : ink, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.jm().format(m.sent),
                            style: TextStyle(fontSize: 10, color: mine ? Colors.white60 : Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('chatInput'),
                        controller: _text,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(me),
                        decoration: const InputDecoration(hintText: 'Message…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('send'),
                      onPressed: () => _send(me),
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(backgroundColor: brand, minimumSize: const Size(50, 50)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(String? me) {
    if (_text.text.trim().isEmpty || me == null) return;
    ref.read(repositoryProvider).sendMessage(threadId: widget.threadId, fromId: me, text: _text.text);
    _text.clear();
  }
}
