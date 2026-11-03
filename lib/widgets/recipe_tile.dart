import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme.dart';

/// Star button that is "on" for favorites.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.favorite, required this.onPressed});

  final bool favorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
      isSelected: favorite,
      icon: const Icon(Icons.star_border),
      selectedIcon: const Icon(Icons.star, color: Color(0xFFF9A825)),
      onPressed: onPressed,
    );
  }
}

/// Small rounded label, e.g. a category, a difficulty or a cook time.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.onSecondaryContainer),
            const SizedBox(width: Gap.xs),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

class RecipeTile extends StatelessWidget {
  const RecipeTile({
    super.key,
    required this.recipe,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final Recipe recipe;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, 0, Gap.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name, style: text.titleMedium),
                    const SizedBox(height: Gap.xs),
                    Wrap(
                      spacing: Gap.xs,
                      runSpacing: Gap.xs,
                      children: [
                        InfoChip(
                          label: '${recipe.cookTime} min',
                          icon: Icons.timer_outlined,
                        ),
                        InfoChip(
                          label: recipe.category,
                          icon: Icons.restaurant_outlined,
                        ),
                        InfoChip(
                          label: recipe.difficulty,
                          icon: Icons.signal_cellular_alt,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FavoriteButton(
                favorite: recipe.favorite,
                onPressed: onToggleFavorite,
              ),
              IconButton(
                tooltip: 'Open details',
                icon: const Icon(Icons.chevron_right),
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
