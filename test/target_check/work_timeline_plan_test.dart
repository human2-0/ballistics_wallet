import 'package:ballistics_wallet_flutter/models/work_timeline_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projects spare time and extra units from current pace', () {
    final plan = WorkTimelinePlan.calculate(
      now: DateTime(2026, 1, 1, 21),
      targetBonus: 1,
      currentRatio: 0.935,
      useAyrBonusTable: true,
      productTarget: 1000,
      amountMade: 1080,
      perBatch: 90,
      workingHours: 7,
      allowance: 0,
    );

    expect(plan.amountLeft, 90);
    expect(plan.productionRemainingMinutes, 45);
    expect(plan.estimatedMinutesToTarget, 30);
    expect(plan.projectedSurplusUnits.floor(), 45);
    expect(plan.batchCount, 1);
    expect(plan.advice, contains('45 extra units'));
  });

  test('handles targets above the configured bonus table', () {
    final plan = WorkTimelinePlan.calculate(
      now: DateTime(2026, 1, 1, 14),
      targetBonus: 1000,
      currentRatio: 0,
      useAyrBonusTable: true,
      productTarget: 100,
      amountMade: 0,
      perBatch: 25,
      workingHours: 7,
      allowance: 0,
    );

    expect(plan.targetAboveMaxTier, isTrue);
    expect(plan.headline, contains('above the current bonus table'));
  });

  test('does not divide by zero after production time ends', () {
    final plan = WorkTimelinePlan.calculate(
      now: DateTime(2026, 1, 1, 22, 5),
      targetBonus: 1,
      currentRatio: 0,
      useAyrBonusTable: true,
      productTarget: 100,
      amountMade: 0,
      perBatch: 25,
      workingHours: 7,
      allowance: 0,
    );

    expect(plan.productionRemainingMinutes, 0);
    expect(plan.requiredUnitsPerMinute, 0);
    expect(plan.advice, contains('No production time is left'));
  });
}
