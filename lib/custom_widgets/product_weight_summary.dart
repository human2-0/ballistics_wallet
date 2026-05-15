import 'package:flutter/material.dart';

/// Displays the acceptable finished product weight range from split data.
class ProductWeightSummary extends StatelessWidget {
  /// Creates a compact product weight badge.
  const ProductWeightSummary({
    required this.weightGrams,
    required this.hasFormula,
    super.key,
  });

  /// Expected finished product weight in grams.
  final double weightGrams;

  /// Whether split data exists for the selected product.
  final bool hasFormula;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        hasFormula
            ? Colors.brown.shade900
            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65);
    final borderColor =
        hasFormula
            ? Colors.orange.shade300
            : theme.dividerColor.withValues(alpha: 0.45);
    final backgroundColor =
        hasFormula ? Colors.orange.shade50 : theme.colorScheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.scale_outlined,
              size: 20,
              color: hasFormula ? Colors.orange.shade800 : textColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Weight range',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: textColor),
            ),
            Text(
              hasFormula ? _formatRange(weightGrams) : 'No data',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRange(double weightGrams) {
    final lower = weightGrams * 0.95;
    final upper = weightGrams * 1.05;
    return '${_formatWeight(lower)}-${_formatWeight(upper)} g';
  }

  static String _formatWeight(double weightGrams) =>
      weightGrams.ceil().toString();
}
