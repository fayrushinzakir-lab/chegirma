import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';

/// Крупный красный бейдж скидки «-30%».
class DiscountBadge extends StatelessWidget {
  final int percent;
  final bool large;
  const DiscountBadge(this.percent, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        '-$percent%',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: large ? 22 : 15,
          letterSpacing: -0.5,
          height: 1,
        ),
      ),
    );
  }
}

/// Матовая обёртка-поверхность: flat-заливка + hairline-граница (без теней).
class MatteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const MatteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Заглушка под фото товара — матовый блок с иконкой категории.
class DealImage extends StatelessWidget {
  final Deal deal;
  final double size;
  const DealImage({super.key, required this.deal, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final cat = categories.firstWhere((c) => c.id == deal.category,
        orElse: () => categories.first);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(cat.icon, color: cat.tint, size: size * 0.42),
    );
  }
}

/// Карточка скидки в ленте.
class DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return MatteCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              DealImage(deal: deal),
              Positioned(
                left: 0,
                top: 0,
                child: DiscountBadge(deal.discountPercent),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (deal.promoted) ...[
                      const _PromoTag(),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        deal.store,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatUzs(deal.newPrice),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatUzs(deal.oldPrice),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      '${deal.distanceKm.toStringAsFixed(1)} км · ${deal.city}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavorite,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              deal.favorite ? Icons.favorite : Icons.favorite_border,
              color: deal.favorite ? AppColors.accent : AppColors.textTertiary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoTag extends StatelessWidget {
  const _PromoTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Реклама',
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Чип-фильтр сортировки.
class SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SortChip(this.label, {super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.bg : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
