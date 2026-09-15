import 'package:flutter/material.dart';

/// An icon, title and message shown in place of an empty list/section —
/// e.g. "no pinned projects yet".
class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style:
                Theme.of(context).textTheme.bodySmall!.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
