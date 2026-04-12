import 'package:flutter/material.dart';
import 'star_rating.dart';
import 'progress_bar.dart';

/// Karte für ein Thema in der Themen-Übersicht
class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int stars; // 0–3
  final double progress; // 0.0–1.0
  final Color? color;
  final VoidCallback? onTap;
  final bool locked;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.stars = 0,
    this.progress = 0,
    this.color,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: cardColor, width: 6),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locked)
                    Icon(
                      Icons.lock_rounded,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    )
                  else
                    StarRating(stars: stars, size: 24),
                ],
              ),
              if (!locked && progress > 0) ...[
                const SizedBox(height: 12),
                LernFuchsProgressBar(
                  value: progress,
                  height: 8,
                  color: cardColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
