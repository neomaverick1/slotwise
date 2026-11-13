import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../data/models.dart';

class BusinessAvatar extends StatelessWidget {
  const BusinessAvatar(this.business, {super.key, this.size = 56});
  final Business business;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Color(business.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(business.category.emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.count, this.size = 14});
  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.star_rounded, size: size + 2, color: const Color(0xFFFFB800)),
      const SizedBox(width: 2),
      Text(
        rating == 0 ? 'New' : rating.toStringAsFixed(1),
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: size, color: ink),
      ),
      if (count != null)
        Text(
          ' ($count)',
          style: TextStyle(fontSize: size, color: Colors.black54),
        ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.2),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = brand, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: brand.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Color statusColor(BookingStatus s) => switch (s) {
  BookingStatus.confirmed => mint,
  BookingStatus.pendingPayment => const Color(0xFFFF9F1C),
  BookingStatus.completed => brand,
  BookingStatus.cancelled => Colors.redAccent,
};

/// Constrains content to a readable width on tablets and the web.
class Readable extends StatelessWidget {
  const Readable({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
