import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// Lightweight animated bar chart (no chart library needed).
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, required this.labels, this.height = 150, this.highlightLast = true});
  final List<double> values;
  final List<String> labels;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: max == 0 ? 0 : values[i] / max),
                      duration: Duration(milliseconds: 500 + i * 60),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Container(
                        height: (height * v).clamp(4, height),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: highlightLast && i == values.length - 1
                                ? const [mint, Color(0xFF7CF2D4)]
                                : [brand.withValues(alpha: 0.75), brand.withValues(alpha: 0.35)],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, required this.value, this.delta, this.icon, this.color = brand});
  final String label;
  final String value;
  final String? delta;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              const Spacer(),
              if (delta != null)
                Text(
                  delta!,
                  style: const TextStyle(color: mint, fontWeight: FontWeight.w800, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
