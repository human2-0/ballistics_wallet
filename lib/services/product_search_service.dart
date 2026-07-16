import 'dart:math' as math;

import 'package:ballistics_wallet_flutter/models/product_info.dart';

/// Returns products that plausibly match [query], ordered by relevance.
///
/// Literal matches always win. When no literal match exists for a product,
/// individual words and the name without spaces are compared with a bounded
/// Damerau-Levenshtein distance so minor typos and swapped letters still match.
List<ProductInfo> searchProducts(
  Iterable<ProductInfo> products,
  String query, {
  Comparator<ProductInfo>? tieBreaker,
  int? limit,
}) {
  final normalizedQuery = _normalize(query);
  final matches = <_ProductMatch>[];

  for (final product in products) {
    final score = _scoreProductName(product.productName, normalizedQuery);
    if (score != null) {
      matches.add(_ProductMatch(product, score));
    }
  }

  matches.sort((left, right) {
    final relevanceComparison = left.score.compareTo(right.score);
    if (relevanceComparison != 0) return relevanceComparison;

    final productComparison = tieBreaker?.call(left.product, right.product);
    if (productComparison != null && productComparison != 0) {
      return productComparison;
    }

    return left.product.productName.toLowerCase().compareTo(
      right.product.productName.toLowerCase(),
    );
  });

  final result = matches.map((match) => match.product);
  if (limit == null) return result.toList(growable: false);
  return result.take(math.max(0, limit)).toList(growable: false);
}

int? _scoreProductName(String productName, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return 0;

  final normalizedName = _normalize(productName);
  if (normalizedName.isEmpty) return null;
  if (normalizedName == normalizedQuery) return 0;
  if (normalizedName.startsWith(normalizedQuery)) return 10;

  final literalIndex = normalizedName.indexOf(normalizedQuery);
  if (literalIndex >= 0) {
    final startsAtWord =
        literalIndex == 0 || normalizedName[literalIndex - 1] == ' ';
    final end = literalIndex + normalizedQuery.length;
    final endsAtWord =
        end == normalizedName.length || normalizedName[end] == ' ';
    return startsAtWord && endsAtWord ? 20 : 25;
  }

  final compactQuery = normalizedQuery.replaceAll(' ', '');
  final compactName = normalizedName.replaceAll(' ', '');
  if (compactName == compactQuery) return 30;

  final queryWords = normalizedQuery.split(' ');
  final nameWords = normalizedName.split(' ');
  var tokenPenalty = 0;
  for (final queryWord in queryWords) {
    final penalty = _bestWordPenalty(queryWord, nameWords);
    if (penalty == null) {
      tokenPenalty = -1;
      break;
    }
    tokenPenalty += penalty;
  }
  if (tokenPenalty >= 0) return 40 + tokenPenalty;

  if (compactQuery.length < 3) return null;
  final allowedEdits = _allowedEdits(compactQuery.length);
  if ((compactName.length - compactQuery.length).abs() > allowedEdits) {
    return null;
  }
  final compactDistance = _damerauLevenshtein(compactQuery, compactName);
  if (compactDistance <= allowedEdits) return 60 + compactDistance * 4;

  return null;
}

int? _bestWordPenalty(String queryWord, List<String> nameWords) {
  var bestPenalty = 1 << 30;

  for (final nameWord in nameWords) {
    if (queryWord == nameWord) return 0;
    if (queryWord.length >= 2 && nameWord.startsWith(queryWord)) {
      bestPenalty = math.min(bestPenalty, 1);
      continue;
    }
    if (queryWord.length >= 3 && nameWord.contains(queryWord)) {
      bestPenalty = math.min(bestPenalty, 2);
      continue;
    }

    final allowedEdits = _allowedEdits(queryWord.length);
    if (allowedEdits == 0 ||
        (nameWord.length - queryWord.length).abs() > allowedEdits) {
      continue;
    }

    final distance = _damerauLevenshtein(queryWord, nameWord);
    if (distance <= allowedEdits) {
      bestPenalty = math.min(bestPenalty, distance * 4);
    }
  }

  return bestPenalty == 1 << 30 ? null : bestPenalty;
}

int _allowedEdits(int queryLength) {
  if (queryLength <= 2) return 0;
  if (queryLength <= 4) return 1;
  if (queryLength <= 8) return 2;
  return math.min(3, queryLength ~/ 4);
}

String _normalize(String input) {
  var value = input.toLowerCase().replaceAll('&', ' and ');
  value =
      value
          .replaceAll(RegExp('[àáâãäå]'), 'a')
          .replaceAll(RegExp('[çćč]'), 'c')
          .replaceAll(RegExp('[ďð]'), 'd')
          .replaceAll(RegExp('[èéêëě]'), 'e')
          .replaceAll(RegExp('[ìíîï]'), 'i')
          .replaceAll(RegExp('[ľĺł]'), 'l')
          .replaceAll(RegExp('[ñň]'), 'n')
          .replaceAll(RegExp('[òóôõöø]'), 'o')
          .replaceAll(RegExp('[ř]'), 'r')
          .replaceAll(RegExp('[šś]'), 's')
          .replaceAll(RegExp('[ť]'), 't')
          .replaceAll(RegExp('[ùúûüů]'), 'u')
          .replaceAll(RegExp('[ýÿ]'), 'y')
          .replaceAll(RegExp('[žźż]'), 'z')
          .replaceAll('æ', 'ae')
          .replaceAll('œ', 'oe')
          .replaceAll('ß', 'ss')
          .replaceAll(RegExp("['’]"), '')
          .replaceAll(RegExp('[^a-z0-9]+'), ' ')
          .trim();
  return value.replaceAll(RegExp(' +'), ' ');
}

int _damerauLevenshtein(String left, String right) {
  if (left == right) return 0;
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;

  final distances = List.generate(
    left.length + 1,
    (_) => List<int>.filled(right.length + 1, 0),
  );
  for (var leftIndex = 0; leftIndex <= left.length; leftIndex++) {
    distances[leftIndex][0] = leftIndex;
  }
  for (var rightIndex = 0; rightIndex <= right.length; rightIndex++) {
    distances[0][rightIndex] = rightIndex;
  }

  for (var leftIndex = 1; leftIndex <= left.length; leftIndex++) {
    for (var rightIndex = 1; rightIndex <= right.length; rightIndex++) {
      final substitutionCost =
          left[leftIndex - 1] == right[rightIndex - 1] ? 0 : 1;
      var distance = math.min(
        distances[leftIndex - 1][rightIndex] + 1,
        math.min(
          distances[leftIndex][rightIndex - 1] + 1,
          distances[leftIndex - 1][rightIndex - 1] + substitutionCost,
        ),
      );

      if (leftIndex > 1 &&
          rightIndex > 1 &&
          left[leftIndex - 1] == right[rightIndex - 2] &&
          left[leftIndex - 2] == right[rightIndex - 1]) {
        distance = math.min(
          distance,
          distances[leftIndex - 2][rightIndex - 2] + 1,
        );
      }
      distances[leftIndex][rightIndex] = distance;
    }
  }

  return distances[left.length][right.length];
}

class _ProductMatch {
  const _ProductMatch(this.product, this.score);

  final ProductInfo product;
  final int score;
}
