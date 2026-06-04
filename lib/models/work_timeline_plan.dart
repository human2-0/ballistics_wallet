// These timeline data objects are internal app infrastructure, not public API.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:ballistics_wallet_flutter/models/work_schedule.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';

class WorkTimelinePlan {
  const WorkTimelinePlan({
    required this.targetBonus,
    required this.currentBonus,
    required this.projectedBonus,
    required this.currentRatio,
    required this.projectedRatio,
    required this.requiredRatio,
    required this.targetTierBonus,
    required this.targetAboveMaxTier,
    required this.amountMade,
    required this.amountLeft,
    required this.perBatch,
    required this.batchCount,
    required this.lastBatchAmount,
    required this.productionElapsedMinutes,
    required this.productionRemainingMinutes,
    required this.actualUnitsPerMinute,
    required this.requiredUnitsPerMinute,
    required this.projectedUnitsAtPace,
    required this.projectedSurplusUnits,
    required this.projectedDeficitUnits,
    required this.estimatedMinutesToTarget,
    required this.nextBatchStarts,
    required this.segmentPlans,
  });

  factory WorkTimelinePlan.calculate({
    required DateTime now,
    required double targetBonus,
    required double currentRatio,
    required bool useAyrBonusTable,
    required int productTarget,
    required int amountMade,
    required int perBatch,
    required double workingHours,
    required double allowance,
  }) {
    final safeTargetBonus = _nonNegativeDouble(targetBonus);
    final safeCurrentRatio = _nonNegativeDouble(currentRatio);
    final safeAmountMade = _nonNegativeInt(amountMade);
    final safePerBatch = _nonNegativeInt(perBatch);
    final effectiveFactor = _effectiveBonusFactor(
      workingHours: workingHours,
      allowance: allowance,
    );
    final currentBonus = _bonusForRatio(
      ratio: safeCurrentRatio,
      effectiveFactor: effectiveFactor,
      useAyrBonusTable: useAyrBonusTable,
    );
    final targetTier = _tierForBonusTarget(
      targetBonus: safeTargetBonus,
      effectiveFactor: effectiveFactor,
      useAyrBonusTable: useAyrBonusTable,
    );
    final adjustedTarget = _adjustedProductTarget(
      productTarget: productTarget,
      workingHours: workingHours,
      allowance: allowance,
    );
    final requiredRatio = targetTier?.requiredRatio ?? _zeroDouble();
    final remainingRatio = _positiveDifference(requiredRatio, safeCurrentRatio);
    final targetReached =
        safeTargetBonus > 0 && currentBonus >= safeTargetBonus;
    final amountLeft =
        targetReached || adjustedTarget <= 0
            ? 0
            : (remainingRatio * adjustedTarget).ceil();
    final productionElapsed = _productionMinutesBetween(
      WorkSchedule.start.onDate(now),
      now,
      now,
    );
    final productionRemaining = _productionMinutesBetween(
      now,
      WorkSchedule.finish.onDate(now),
      now,
    );
    final actualPace =
        productionElapsed > 0
            ? safeAmountMade / productionElapsed
            : _zeroDouble();
    final requiredPace =
        productionRemaining > 0 && amountLeft > 0
            ? amountLeft / productionRemaining
            : _zeroDouble();
    final projectedUnits = actualPace * productionRemaining;
    final projectedRatio =
        adjustedTarget > 0
            ? safeCurrentRatio + (projectedUnits / adjustedTarget)
            : safeCurrentRatio;
    final projectedBonus = _bonusForRatio(
      ratio: projectedRatio,
      effectiveFactor: effectiveFactor,
      useAyrBonusTable: useAyrBonusTable,
    );
    final projectedSurplus = _positiveDifference(projectedUnits, amountLeft);
    final projectedDeficit = _positiveDifference(amountLeft, projectedUnits);
    final estimatedMinutes =
        actualPace > 0 && amountLeft > 0
            ? amountLeft / actualPace
            : _zeroDouble();
    final batchCount =
        safePerBatch > 0 && amountLeft > 0
            ? (amountLeft / safePerBatch).ceil()
            : 0;
    final lastBatchAmount =
        batchCount == 0 ? 0 : amountLeft - (safePerBatch * (batchCount - 1));

    return WorkTimelinePlan(
      targetBonus: safeTargetBonus,
      currentBonus: currentBonus,
      projectedBonus: projectedBonus,
      currentRatio: safeCurrentRatio,
      projectedRatio: projectedRatio,
      requiredRatio: requiredRatio,
      targetTierBonus: targetTier?.bonus ?? 0,
      targetAboveMaxTier: targetTier?.isMaxFallback ?? false,
      amountMade: safeAmountMade,
      amountLeft: amountLeft,
      perBatch: safePerBatch,
      batchCount: batchCount,
      lastBatchAmount: lastBatchAmount,
      productionElapsedMinutes: productionElapsed,
      productionRemainingMinutes: productionRemaining,
      actualUnitsPerMinute: actualPace,
      requiredUnitsPerMinute: requiredPace,
      projectedUnitsAtPace: projectedUnits,
      projectedSurplusUnits: projectedSurplus,
      projectedDeficitUnits: projectedDeficit,
      estimatedMinutesToTarget: estimatedMinutes,
      nextBatchStarts: _batchStartTimes(
        now: now,
        batchCount: batchCount,
        minutesPerBatch:
            requiredPace > 0 && safePerBatch > 0
                ? safePerBatch / requiredPace
                : 0,
      ),
      segmentPlans: _segmentPlans(
        now: now,
        amountLeft: amountLeft,
        requiredPace: requiredPace,
        perBatch: safePerBatch,
      ),
    );
  }

  final double targetBonus;
  final double currentBonus;
  final double projectedBonus;
  final double currentRatio;
  final double projectedRatio;
  final double requiredRatio;
  final double targetTierBonus;
  final bool targetAboveMaxTier;
  final int amountMade;
  final int amountLeft;
  final int perBatch;
  final int batchCount;
  final int lastBatchAmount;
  final double productionElapsedMinutes;
  final double productionRemainingMinutes;
  final double actualUnitsPerMinute;
  final double requiredUnitsPerMinute;
  final double projectedUnitsAtPace;
  final double projectedSurplusUnits;
  final double projectedDeficitUnits;
  final double estimatedMinutesToTarget;
  final List<DateTime> nextBatchStarts;
  final List<WorkTimelineSegmentPlan> segmentPlans;

  bool get hasTarget => targetBonus > 0;
  bool get targetReached => hasTarget && currentBonus >= targetBonus;
  bool get canPlanUnits => hasTarget && requiredRatio > 0 && amountLeft > 0;
  bool get hasPaceData => productionElapsedMinutes >= 10 && amountMade > 0;
  bool get isBehindPace =>
      canPlanUnits && hasPaceData && projectedDeficitUnits >= 1;
  bool get isAheadPace =>
      canPlanUnits && hasPaceData && projectedSurplusUnits >= 1;
  bool get hasProjection => hasPaceData && productionRemainingMinutes > 0;

  String get headline {
    if (!hasTarget) {
      return 'Set a target to plan the shift.';
    }
    if (targetReached) {
      return 'Target reached.';
    }
    if (targetAboveMaxTier) {
      return 'Target is above the current bonus table.';
    }
    if (!canPlanUnits) {
      return 'Pick a product to calculate units left.';
    }
    return '$amountLeft left for £${targetBonus.toStringAsFixed(2)}.';
  }

  String get advice {
    if (!hasTarget) {
      return 'Choose a £ target and the timeline will split it across the '
          'remaining work blocks.';
    }
    if (targetReached) {
      final extra = math.max(0, currentBonus - targetBonus);
      return extra > 0
          ? 'You are £${extra.toStringAsFixed(2)} over target.'
          : 'You have enough recorded for this target.';
    }
    if (targetAboveMaxTier) {
      return 'The highest mapped tier is '
          '£${targetTierBonus.toStringAsFixed(2)}. Use that as the realistic '
          'ceiling unless the bonus table changes.';
    }
    if (!canPlanUnits) {
      return 'Select a product with a valid target before planning batches.';
    }
    if (productionRemainingMinutes <= 0) {
      return 'No production time is left today.';
    }
    if (!hasPaceData) {
      return 'Use the work blocks below as the unit plan for the rest of the '
          'shift.';
    }
    if (isBehindPace) {
      final percent =
          actualUnitsPerMinute > 0
              ? ((requiredUnitsPerMinute / actualUnitsPerMinute) - 1) * 100
              : 100.0;
      return 'Current pace misses by about ${projectedDeficitUnits.ceil()} '
          'units. Speed up about ${percent.clamp(0, 999).round()}% or lower '
          'the target.';
    }
    if (isAheadPace) {
      final spareMinutes =
          productionRemainingMinutes > estimatedMinutesToTarget
              ? productionRemainingMinutes - estimatedMinutesToTarget
              : 0;
      return 'At current pace you have about ${spareMinutes.round()} min '
          'spare, enough for ${projectedSurplusUnits.floor()} extra units.';
    }
    return 'Pace is close. Follow the remaining block plan.';
  }

  String get batchSummary {
    if (!canPlanUnits) return 'No batch plan yet';
    if (perBatch <= 0) return 'Add units per batch';
    if (batchCount == 1) return '1 batch of $lastBatchAmount';
    return '$batchCount batches, last $lastBatchAmount';
  }

  String get paceSummary {
    if (!hasProjection) return 'Projection starts after work begins';
    return 'At this pace: £${projectedBonus.toStringAsFixed(2)}';
  }

  static double _effectiveBonusFactor({
    required double workingHours,
    required double allowance,
  }) {
    final effectiveHours = workingHours - allowance;
    if (effectiveHours <= 0) return 0;
    return effectiveHours / 7.0;
  }

  static double _zeroDouble() => 0;

  static double _nonNegativeDouble(double value) =>
      value < 0 ? _zeroDouble() : value;

  static int _nonNegativeInt(int value) => value < 0 ? 0 : value;

  static double _positiveDifference(num left, num right) =>
      left > right ? (left - right).toDouble() : _zeroDouble();

  static int _adjustedProductTarget({
    required int productTarget,
    required double workingHours,
    required double allowance,
  }) {
    if (productTarget <= 0) return 0;
    if (workingHours <= 0) return productTarget;
    final effectiveHours = workingHours - allowance;
    if (effectiveHours <= 0) return 0;
    return (productTarget * (effectiveHours / workingHours)).ceil();
  }

  static double _bonusForRatio({
    required double ratio,
    required double effectiveFactor,
    required bool useAyrBonusTable,
  }) {
    if (ratio <= 0 || effectiveFactor <= 0) return 0;
    final bonusMap =
        useAyrBonusTable ? ayrBonusPercentageMap : seasonalBonusPercentageMap;
    final keys = bonusMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final percentage = ratio * 100;
    for (final key in keys) {
      final required = bonusMap[key] ?? 0;
      if (percentage >= required) {
        return key * effectiveFactor;
      }
    }
    return 0;
  }

  static _BonusTierTarget? _tierForBonusTarget({
    required double targetBonus,
    required double effectiveFactor,
    required bool useAyrBonusTable,
  }) {
    if (targetBonus <= 0 || effectiveFactor <= 0) return null;
    final bonusMap =
        useAyrBonusTable ? ayrBonusPercentageMap : seasonalBonusPercentageMap;
    final keys = bonusMap.keys.toList()..sort();
    _BonusTierTarget? maxTier;
    for (final key in keys) {
      final actualBonus = key * effectiveFactor;
      final tier = _BonusTierTarget(
        bonus: actualBonus,
        requiredRatio: (bonusMap[key] ?? 0) / 100,
        isMaxFallback: false,
      );
      maxTier = tier;
      if (actualBonus >= targetBonus) return tier;
    }
    if (maxTier == null) return null;
    return _BonusTierTarget(
      bonus: maxTier.bonus,
      requiredRatio: maxTier.requiredRatio,
      isMaxFallback: true,
    );
  }

  static List<WorkTimelineSegmentPlan> _segmentPlans({
    required DateTime now,
    required int amountLeft,
    required double requiredPace,
    required int perBatch,
  }) {
    var remainingAmount = amountLeft;
    return WorkSchedule.segments.map((segment) {
      final remainingMinutes = _segmentRemainingProductionMinutes(segment, now);
      var plannedUnits = 0;
      if (segment.type == WorkScheduleSegmentType.work &&
          requiredPace > 0 &&
          remainingAmount > 0) {
        plannedUnits = math.min(
          remainingAmount,
          (remainingMinutes * requiredPace).ceil(),
        );
        remainingAmount -= plannedUnits;
      }
      return WorkTimelineSegmentPlan(
        segment: segment,
        remainingMinutes: remainingMinutes,
        plannedUnits: plannedUnits,
        perBatch: perBatch,
      );
    }).toList();
  }

  static List<DateTime> _batchStartTimes({
    required DateTime now,
    required int batchCount,
    required double minutesPerBatch,
  }) {
    if (batchCount <= 0 || minutesPerBatch <= 0) return const [];
    final starts = <DateTime>[];
    var cursor = _nextProductionMinute(now);
    final spacingMinutes = math.max(5, minutesPerBatch.round());

    while (starts.length < batchCount && starts.length < 12) {
      final next = _nextProductionMinute(cursor);
      if (next.isAfter(WorkSchedule.finish.onDate(now))) break;
      starts.add(next);
      cursor = _addProductionMinutes(next, spacingMinutes, now);
    }

    return starts;
  }

  static DateTime _nextProductionMinute(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    for (final segment in WorkSchedule.segments) {
      if (segment.type != WorkScheduleSegmentType.work) continue;
      final start = segment.start.onDate(time);
      if (minute < segment.startMinute) return start;
      if (minute >= segment.startMinute && minute < segment.endMinute) {
        return time;
      }
    }
    return WorkSchedule.finish.onDate(time).add(const Duration(minutes: 1));
  }

  static DateTime _addProductionMinutes(
    DateTime start,
    int minutes,
    DateTime scheduleDate,
  ) {
    var remaining = minutes;
    var cursor = start;
    while (remaining > 0) {
      final segment = WorkSchedule.currentSegment(cursor);
      if (segment == null || segment.type != WorkScheduleSegmentType.work) {
        cursor = _nextProductionMinute(cursor);
        if (cursor.isAfter(WorkSchedule.finish.onDate(scheduleDate))) {
          return cursor;
        }
        continue;
      }
      final segmentEnd = segment.end.onDate(cursor);
      final available = math.max(0, segmentEnd.difference(cursor).inMinutes);
      if (available >= remaining) {
        return cursor.add(Duration(minutes: remaining));
      }
      remaining -= available;
      cursor = segmentEnd.add(const Duration(minutes: 1));
    }
    return cursor;
  }

  static double _productionMinutesBetween(
    DateTime from,
    DateTime to,
    DateTime scheduleDate,
  ) {
    if (!to.isAfter(from)) return 0;
    var total = 0.0;
    for (final segment in WorkSchedule.segments) {
      if (segment.type != WorkScheduleSegmentType.work) continue;
      final start = segment.start.onDate(scheduleDate);
      final end = segment.end.onDate(scheduleDate);
      final overlapStart = from.isAfter(start) ? from : start;
      final overlapEnd = to.isBefore(end) ? to : end;
      if (overlapEnd.isAfter(overlapStart)) {
        total += overlapEnd.difference(overlapStart).inSeconds / 60.0;
      }
    }
    return total;
  }

  static double _segmentRemainingProductionMinutes(
    WorkScheduleSegment segment,
    DateTime now,
  ) {
    if (segment.type != WorkScheduleSegmentType.work) return 0;
    final start = segment.start.onDate(now);
    final end = segment.end.onDate(now);
    final from = now.isAfter(start) ? now : start;
    if (!end.isAfter(from)) return 0;
    return end.difference(from).inSeconds / 60.0;
  }
}

class WorkTimelineSegmentPlan {
  const WorkTimelineSegmentPlan({
    required this.segment,
    required this.remainingMinutes,
    required this.plannedUnits,
    required this.perBatch,
  });

  final WorkScheduleSegment segment;
  final double remainingMinutes;
  final int plannedUnits;
  final int perBatch;

  bool get hasFutureProduction =>
      segment.type == WorkScheduleSegmentType.work && remainingMinutes > 0;

  int get fullBatches =>
      plannedUnits > 0 && perBatch > 0 ? plannedUnits ~/ perBatch : 0;

  int get extraBatchUnits =>
      plannedUnits > 0 && perBatch > 0 ? plannedUnits % perBatch : 0;

  String get batchLabel {
    if (plannedUnits <= 0) return '';
    if (perBatch <= 0) return 'add batch size';
    if (fullBatches == 0) return '$extraBatchUnits small batch';
    if (extraBatchUnits == 0) {
      return fullBatches == 1 ? '1 batch' : '$fullBatches batches';
    }
    return '$fullBatches batches + $extraBatchUnits';
  }
}

class _BonusTierTarget {
  const _BonusTierTarget({
    required this.bonus,
    required this.requiredRatio,
    required this.isMaxFallback,
  });

  final double bonus;
  final double requiredRatio;
  final bool isMaxFallback;
}
