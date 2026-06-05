import 'package:flutter/material.dart';

/// Displays the acceptable finished product weight range from split data.
class ProductWeightSummary extends StatelessWidget {
  /// Creates a compact product weight badge.
  const ProductWeightSummary({
    required this.weightGrams,
    required this.hasFormula,
    this.customMinGrams,
    this.customMaxGrams,
    this.onLongPress,
    super.key,
  });

  /// Expected finished product weight in grams.
  final double weightGrams;

  /// Whether split data exists for the selected product.
  final bool hasFormula;

  /// Optional custom minimum finished product weight in grams.
  final double? customMinGrams;

  /// Optional custom maximum finished product weight in grams.
  final double? customMaxGrams;

  /// Called when the badge is long-pressed.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCustomRange = customMinGrams != null && customMaxGrams != null;
    final hasWeightData = hasFormula || hasCustomRange;
    final textColor =
        hasWeightData
            ? Colors.brown.shade900
            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65);
    final borderColor =
        hasWeightData
            ? Colors.orange.shade300
            : theme.dividerColor.withValues(alpha: 0.45);
    final backgroundColor =
        hasWeightData ? Colors.orange.shade50 : theme.colorScheme.surface;

    final badge = DecoratedBox(
      decoration: _badgeDecoration(backgroundColor, borderColor),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.scale_outlined,
                  size: 20,
                  color: hasWeightData ? Colors.orange.shade800 : textColor,
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
                  hasWeightData
                      ? _formatRange(
                        weightGrams,
                        customMinGrams,
                        customMaxGrams,
                      )
                      : 'No data',
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
          if (onLongPress != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 14,
                color: Colors.orange.shade900.withValues(alpha: 0.78),
              ),
            ),
        ],
      ),
    );

    if (onLongPress == null) return badge;

    return Tooltip(
      message: 'Hold to edit weight range',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: onLongPress,
        child: badge,
      ),
    );
  }

  BoxDecoration _badgeDecoration(Color backgroundColor, Color borderColor) =>
      BoxDecoration(
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
      );

  static String _formatRange(
    double weightGrams,
    double? customMinGrams,
    double? customMaxGrams,
  ) {
    if (customMinGrams != null && customMaxGrams != null) {
      final min = _formatWeight(customMinGrams);
      final max = _formatWeight(customMaxGrams);
      return '$min-$max g';
    }

    const offset = 5 / 100;
    final lower = weightGrams * (1 - offset);
    final upper = weightGrams * (1 + offset);
    return '${_formatWeight(lower)}-${_formatWeight(upper)} g';
  }

  static String _formatWeight(double weightGrams) =>
      weightGrams.ceil().toString();
}
