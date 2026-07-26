import 'package:flutter/material.dart';

/// A "Section title ... See all" row used above each home dashboard rail.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, required this.icon, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}
