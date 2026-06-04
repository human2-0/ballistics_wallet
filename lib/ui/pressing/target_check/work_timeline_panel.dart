// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;

import 'package:ballistics_wallet_flutter/models/work_schedule.dart';
import 'package:ballistics_wallet_flutter/models/work_timeline_plan.dart';
import 'package:ballistics_wallet_flutter/providers/split_provider.dart';
import 'package:ballistics_wallet_flutter/providers/work_timeline_provider.dart';
import 'package:ballistics_wallet_flutter/services/work_timeline_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkTimelinePanel extends ConsumerStatefulWidget {
  const WorkTimelinePanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  ConsumerState<WorkTimelinePanel> createState() => _WorkTimelinePanelState();
}

class _WorkTimelinePanelState extends ConsumerState<WorkTimelinePanel> {
  late DateTime _now;
  late final TextEditingController _targetController;
  late final TextEditingController _batchController;
  late final FocusNode _targetFocusNode;
  late final FocusNode _batchFocusNode;
  Timer? _timer;
  TimeOfDay? _debugTimeOverride;
  String? _lastReminderSignature;

  static const double _minSegmentTileHeight = 68;
  static const double _markerSize = 34;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _targetController = TextEditingController();
    _batchController = TextEditingController();
    _targetFocusNode = FocusNode();
    _batchFocusNode = FocusNode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = _currentAppTime());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _targetController.dispose();
    _batchController.dispose();
    _targetFocusNode.dispose();
    _batchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(workTimelineSettingsProvider);
    final plan = ref.watch(workTimelinePlanProvider(_now));
    final currentSegment = WorkSchedule.currentSegment(_now);
    final progress = WorkSchedule.progressFor(_now);
    final colorScheme = Theme.of(context).colorScheme;

    _syncTextControllers(settings, plan);
    _syncReminderSchedule(settings, plan);

    return Material(
      elevation: 18,
      color: Colors.transparent,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[50]!, Colors.white, Colors.orange[100]!],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final timelineHeightBasis =
                  math.max(360, constraints.maxHeight - 250).toDouble();
              final segmentHeights = _segmentHeights(timelineHeightBasis);
              final timelineHeight = segmentHeights.fold<double>(
                0,
                (total, height) => total + height,
              );

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 10, 6),
                        child: Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 42,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[200],
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Work timeline',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${WorkSchedule.start.label} - '
                                    '${WorkSchedule.finish.label}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close timeline',
                              icon: const Icon(Icons.close),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),
                      if (kDebugMode)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                          child: _DebugTimeControls(
                            now: _now,
                            isOverridden: _debugTimeOverride != null,
                            onPick: _pickDebugTime,
                            onReset: _clearDebugTime,
                            onShift: _shiftDebugTime,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _TimelineStatusCard(
                          plan: plan,
                          currentSegment: currentSegment,
                          now: _now,
                          targetController: _targetController,
                          batchController: _batchController,
                          targetFocusNode: _targetFocusNode,
                          batchFocusNode: _batchFocusNode,
                          onTargetChanged: _handleTargetChanged,
                          onBatchChanged: _handleBatchChanged,
                          onAutoPlanBatchSize: _handleAutoPlanBatchSize,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: SizedBox(
                          height: timelineHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                left: 39,
                                right: null,
                                child: _TimelineRail(progress: progress),
                              ),
                              ..._buildSegmentTiles(
                                segmentHeights,
                                currentSegment,
                                plan,
                              ),
                              ...WorkSchedule.markers.map(
                                (marker) => _TimelineMarker(
                                  marker: marker,
                                  top: _markerTop(marker, segmentHeights),
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Positioned(
                                top: _progressTop(_now, segmentHeights, 22),
                                left: 30,
                                child: const _NowMarker(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<double> _segmentHeights(double availableHeight) {
    final baseHeight = availableHeight < 560 ? 560.0 : availableHeight;
    final minuteHeight = baseHeight / WorkSchedule.totalMinutes;

    return WorkSchedule.segments
        .map(
          (segment) => (segment.durationMinutes * minuteHeight).clamp(
            _minSegmentTileHeight,
            double.infinity,
          ),
        )
        .toList();
  }

  List<Widget> _buildSegmentTiles(
    List<double> segmentHeights,
    WorkScheduleSegment? currentSegment,
    WorkTimelinePlan plan,
  ) {
    var top = 0.0;
    final tiles = <Widget>[];

    for (var i = 0; i < WorkSchedule.segments.length; i++) {
      final segment = WorkSchedule.segments[i];
      final height = segmentHeights[i];
      tiles.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: _TimelineSegmentTile(
            plan: plan.segmentPlans[i],
            isCurrent: currentSegment == segment,
            totalPlannedUnits: plan.amountLeft,
          ),
        ),
      );
      top += height;
    }

    return tiles;
  }

  double _markerTop(WorkScheduleMarker marker, List<double> segmentHeights) {
    final rawTop = _timeTop(marker.time.minutesAfterMidnight, segmentHeights);
    final maxTop = _totalTimelineHeight(segmentHeights);
    return (rawTop - (_markerSize / 2)).clamp(0.0, maxTop - _markerSize);
  }

  double _progressTop(
    DateTime time,
    List<double> segmentHeights,
    double markerHeight,
  ) {
    final minute = time.hour * 60 + time.minute;
    final maxTop = _totalTimelineHeight(segmentHeights);
    return (_timeTop(minute, segmentHeights) - (markerHeight / 2)).clamp(
      0.0,
      maxTop - markerHeight,
    );
  }

  double _timeTop(int minute, List<double> segmentHeights) {
    if (minute <= WorkSchedule.start.minutesAfterMidnight) return 0;
    if (minute >= WorkSchedule.finish.minutesAfterMidnight) {
      return _totalTimelineHeight(segmentHeights);
    }

    var top = 0.0;
    for (var i = 0; i < WorkSchedule.segments.length; i++) {
      final segment = WorkSchedule.segments[i];
      final height = segmentHeights[i];
      if (minute >= segment.startMinute && minute <= segment.endMinute) {
        final segmentProgress =
            (minute - segment.startMinute) / segment.durationMinutes;
        return top + (height * segmentProgress.clamp(0.0, 1.0));
      }
      top += height;
    }

    return top;
  }

  double _totalTimelineHeight(List<double> segmentHeights) =>
      segmentHeights.fold<double>(0, (sum, height) => sum + height);

  void _syncTextControllers(
    WorkTimelineSettings settings,
    WorkTimelinePlan plan,
  ) {
    if (!_targetFocusNode.hasFocus) {
      final targetText =
          settings.targetBonus > 0
              ? settings.targetBonus.floor().toString()
              : '';
      if (_targetController.text != targetText) {
        _targetController.text = targetText;
      }
    }

    if (!_batchFocusNode.hasFocus) {
      final batchText = plan.perBatch > 0 ? plan.perBatch.toString() : '';
      if (_batchController.text != batchText) {
        _batchController.text = batchText;
      }
    }
  }

  void _handleTargetChanged(String value) {
    final target = int.tryParse(value.trim()) ?? 0;
    unawaited(
      ref
          .read(workTimelineSettingsProvider.notifier)
          .setTargetBonus(target.toDouble()),
    );
  }

  void _handleBatchChanged(String value) {
    final perBatch = int.tryParse(value.trim()) ?? 0;
    ref.read(amountPerBatchProvider.notifier).state = perBatch;
  }

  void _handleAutoPlanBatchSize(int batchSize) {
    if (batchSize <= 0) return;
    _batchFocusNode.unfocus();
    _batchController.text = batchSize.toString();
    ref.read(amountPerBatchProvider.notifier).state = batchSize;
  }

  DateTime _currentAppTime() {
    final realNow = DateTime.now();
    final debugOverride = _debugTimeOverride;
    if (!kDebugMode || debugOverride == null) return realNow;
    return DateTime(
      realNow.year,
      realNow.month,
      realNow.day,
      debugOverride.hour,
      debugOverride.minute,
    );
  }

  Future<void> _pickDebugTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_now),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _debugTimeOverride = picked;
      _now = _currentAppTime();
    });
  }

  void _shiftDebugTime(int minutes) {
    final shifted = _now.add(Duration(minutes: minutes));
    setState(() {
      _debugTimeOverride = TimeOfDay.fromDateTime(shifted);
      _now = _currentAppTime();
    });
  }

  void _clearDebugTime() {
    setState(() {
      _debugTimeOverride = null;
      _now = DateTime.now();
    });
  }

  void _syncReminderSchedule(
    WorkTimelineSettings settings,
    WorkTimelinePlan plan,
  ) {
    final minuteKey =
        DateTime(
          _now.year,
          _now.month,
          _now.day,
          _now.hour,
          _now.minute,
        ).toIso8601String();
    final signature = [
      minuteKey,
      settings.breakReminderEnabled,
      settings.batchReminderEnabled,
      plan.amountLeft,
      plan.perBatch,
      plan.nextBatchStarts.map((time) => time.toIso8601String()).join(','),
    ].join('|');

    if (_lastReminderSignature == signature) return;
    _lastReminderSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        WorkTimelineNotificationService.instance.syncPlan(
          plan: plan,
          breakReminderEnabled: settings.breakReminderEnabled,
          batchReminderEnabled: settings.batchReminderEnabled,
          now: _now,
        ),
      );
    });
  }
}

class _DebugTimeControls extends StatelessWidget {
  const _DebugTimeControls({
    required this.now,
    required this.isOverridden,
    required this.onPick,
    required this.onReset,
    required this.onShift,
  });

  final DateTime now;
  final bool isOverridden;
  final VoidCallback onPick;
  final VoidCallback onReset;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.orange[100]!),
    ),
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          Icons.bug_report_outlined,
          size: 17,
          color: isOverridden ? Colors.deepOrange : Colors.grey[700],
        ),
        Text(
          'Debug time ${_clockLabel(now)}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: 'Back 15 minutes',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline, size: 18),
          onPressed: () => onShift(-15),
        ),
        IconButton(
          tooltip: 'Forward 15 minutes',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          onPressed: () => onShift(15),
        ),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.schedule_outlined, size: 17),
          label: const Text('Pick'),
        ),
        if (isOverridden)
          IconButton(
            tooltip: 'Use real time',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: onReset,
          ),
      ],
    ),
  );
}

class _TimelineStatusCard extends StatelessWidget {
  const _TimelineStatusCard({
    required this.plan,
    required this.currentSegment,
    required this.now,
    required this.targetController,
    required this.batchController,
    required this.targetFocusNode,
    required this.batchFocusNode,
    required this.onTargetChanged,
    required this.onBatchChanged,
    required this.onAutoPlanBatchSize,
  });

  final WorkTimelinePlan plan;
  final WorkScheduleSegment? currentSegment;
  final DateTime now;
  final TextEditingController targetController;
  final TextEditingController batchController;
  final FocusNode targetFocusNode;
  final FocusNode batchFocusNode;
  final ValueChanged<String> onTargetChanged;
  final ValueChanged<String> onBatchChanged;
  final ValueChanged<int> onAutoPlanBatchSize;

  @override
  Widget build(BuildContext context) {
    final title = currentSegment?.title ?? _offShiftTitle(now);
    final progress =
        plan.requiredRatio > 0
            ? (plan.currentRatio / plan.requiredRatio).clamp(0.0, 1.0)
            : 0.0;
    final autoBatchSize = _suggestEvenBatchSize(plan);
    final canAutoPlan =
        autoBatchSize > 0 &&
        autoBatchSize != plan.perBatch &&
        plan.perBatch > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.orange[100],
              valueColor: AlwaysStoppedAnimation<Color>(
                plan.targetReached ? Colors.green : Colors.deepOrange,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimelineNumberField(
                  controller: targetController,
                  focusNode: targetFocusNode,
                  label: 'Target £',
                  icon: Icons.flag_outlined,
                  onChanged: onTargetChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimelineNumberField(
                  controller: batchController,
                  focusNode: batchFocusNode,
                  label: 'Batch',
                  icon: Icons.inventory_2_outlined,
                  onChanged: onBatchChanged,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: Tooltip(
                  message:
                      autoBatchSize > 0
                          ? 'Use $autoBatchSize per batch for a more even '
                              'block split'
                          : 'Set a target and batch size first',
                  child: OutlinedButton.icon(
                    onPressed:
                        canAutoPlan
                            ? () => onAutoPlanBatchSize(autoBatchSize)
                            : null,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      autoBatchSize > 0 ? 'Auto $autoBatchSize' : 'Auto',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.headline,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            plan.advice,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  String _offShiftTitle(DateTime now) {
    final minute = now.hour * 60 + now.minute;
    if (minute < WorkSchedule.start.minutesAfterMidnight) {
      return 'Before shift';
    }
    return 'Shift finished';
  }
}

class _TimelineNumberField extends StatelessWidget {
  const _TimelineNumberField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: onChanged,
    decoration: InputDecoration(
      isDense: true,
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.78),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.orange[100]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.orange[100]!),
      ),
    ),
  );
}

int _suggestEvenBatchSize(WorkTimelinePlan plan) {
  if (!plan.canPlanUnits || plan.perBatch <= 0) return 0;

  const maxTableBatchSize = 150;
  final blockUnits =
      plan.segmentPlans
          .where((segmentPlan) => segmentPlan.hasFutureProduction)
          .map((segmentPlan) => segmentPlan.plannedUnits)
          .where((units) => units > 0)
          .toList();
  if (blockUnits.isEmpty) return 0;

  final preferred = plan.perBatch.clamp(1, maxTableBatchSize);
  final lowerBound = math.max(1, (preferred * 0.75).floor());
  final upperBound = math.min(maxTableBatchSize, (preferred * 1.25).ceil());
  var bestSize = preferred;
  var bestScore = double.infinity;

  for (var size = lowerBound; size <= upperBound; size++) {
    final score = _batchEvennessScore(
      blockUnits: blockUnits,
      batchSize: size,
      preferredSize: preferred,
    );
    if (score < bestScore - 0.0001 ||
        ((score - bestScore).abs() <= 0.0001 &&
            (preferred - size).abs() < (preferred - bestSize).abs())) {
      bestScore = score;
      bestSize = size;
    }
  }

  return bestSize;
}

double _batchEvennessScore({
  required List<int> blockUnits,
  required int batchSize,
  required int preferredSize,
}) {
  var splitQuality = 0.0;
  var totalBatchCount = 0;

  for (final units in blockUnits) {
    final batchCount = (units / batchSize).ceil();
    final remainder = units % batchSize;
    final lastBatchRatio =
        remainder == 0 ? 1.0 : remainder / math.max(1, batchSize);
    totalBatchCount += batchCount;

    if (batchCount < 3) {
      splitQuality += units <= batchSize ? 4 : 32;
    } else if (batchCount <= 4) {
      splitQuality += 0;
    } else {
      splitQuality += (batchCount - 4) * 12;
    }

    if (batchCount > 1 && lastBatchRatio < 0.45) {
      splitQuality += (0.45 - lastBatchRatio) * 40;
    }
  }

  final distanceFromPreferred =
      (preferredSize - batchSize).abs() / math.max(1, preferredSize);
  return (distanceFromPreferred * 100) +
      splitQuality +
      (totalBatchCount * 0.35);
}

String _clockLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Stack(
      children: [
        Container(
          width: 4,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        FractionallySizedBox(
          heightFactor: progress.clamp(0.0, 1.0),
          alignment: Alignment.topCenter,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TimelineSegmentTile extends StatelessWidget {
  const _TimelineSegmentTile({
    required this.plan,
    required this.isCurrent,
    required this.totalPlannedUnits,
  });

  final WorkTimelineSegmentPlan plan;
  final bool isCurrent;
  final int totalPlannedUnits;

  @override
  Widget build(BuildContext context) {
    final segment = plan.segment;
    final accent = _accentColor(segment.type);
    final fill =
        totalPlannedUnits > 0
            ? (plan.plannedUnits / totalPlannedUnits).clamp(0.0, 1.0)
            : 0.0;

    return Padding(
      padding: const EdgeInsets.only(left: 62, bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
        decoration: BoxDecoration(
          color:
              isCurrent
                  ? accent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? accent : Colors.orange[100]!,
            width: isCurrent ? 1.4 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 54;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        segment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${segment.start.label}-${segment.end.label}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: fill,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.7,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _planLabel(plan),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[850],
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (plan.batchLabel.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _BlockBatchChip(label: plan.batchLabel),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _planLabel(WorkTimelineSegmentPlan plan) {
    switch (plan.segment.type) {
      case WorkScheduleSegmentType.work:
        if (plan.plannedUnits > 0) return '${plan.plannedUnits} units';
        if (plan.remainingMinutes <= 0) return 'done';
        return 'ready';
      case WorkScheduleSegmentType.breakTime:
        return 'update score';
      case WorkScheduleSegmentType.cleaning:
        return 'clean';
    }
  }

  Color _accentColor(WorkScheduleSegmentType type) {
    switch (type) {
      case WorkScheduleSegmentType.breakTime:
        return Colors.blue;
      case WorkScheduleSegmentType.cleaning:
        return Colors.teal;
      case WorkScheduleSegmentType.work:
        return Colors.deepOrange;
    }
  }
}

class _BlockBatchChip extends StatelessWidget {
  const _BlockBatchChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.marker,
    required this.top,
    required this.colorScheme,
  });

  final WorkScheduleMarker marker;
  final double top;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: 23,
    child: Tooltip(
      message: '${marker.time.label} ${marker.title}: ${marker.detail}',
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(marker.icon, size: 17, color: colorScheme.primary),
      ),
    ),
  );
}

class _NowMarker extends StatelessWidget {
  const _NowMarker();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: Colors.redAccent,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: [
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.45),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    ),
  );
}
