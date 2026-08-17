import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/cameroon_colors.dart';

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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CameroonColors.sunsetOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: CameroonColors.sunsetOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(foregroundColor: CameroonColors.sunsetOrange),
              child: Text(AppLocalizations.of(context)!.seeAll),
            ),
        ],
      ),
    );
  }
}
