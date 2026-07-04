// Notification wiring is app-internal; public docs would add noise here.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:ballistics_wallet_flutter/models/work_schedule.dart';
import 'package:ballistics_wallet_flutter/models/work_timeline_plan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class WorkTimelineNotificationService {
  WorkTimelineNotificationService._();

  static final WorkTimelineNotificationService instance =
      WorkTimelineNotificationService._();

  static const _channelId = 'work_timeline_reminders';
  static const _channelName = 'Work timeline reminders';
  static const _breakBaseId = 61000;
  static const _batchBaseId = 61100;
  static const _notificationSlots = 40;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _disabledStateApplied = false;
  _TimelineSyncRequest? _pendingSync;
  Future<void>? _syncLoop;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } on Object catch (error) {
      debugPrint('Work timeline notifications unavailable: $error');
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (!_initialized || kIsWeb) return false;

    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios =
        _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }

    final macos =
        _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
    if (macos != null) {
      return await macos.requestPermissions(alert: true, sound: true) ?? false;
    }

    return true;
  }

  Future<void> syncPlan({
    required WorkTimelinePlan plan,
    required bool breakReminderEnabled,
    required bool batchReminderEnabled,
    required DateTime now,
  }) {
    _pendingSync = _TimelineSyncRequest(
      plan: plan,
      breakReminderEnabled: breakReminderEnabled,
      batchReminderEnabled: batchReminderEnabled,
      now: now,
    );
    final activeLoop = _syncLoop;
    if (activeLoop != null) return activeLoop;

    late final Future<void> loop;
    loop = _drainSyncRequests().whenComplete(() {
      if (identical(_syncLoop, loop)) _syncLoop = null;
    });
    _syncLoop = loop;
    return loop;
  }

  Future<void> _drainSyncRequests() async {
    while (_pendingSync != null) {
      final request = _pendingSync!;
      _pendingSync = null;
      try {
        await _applySyncRequest(request);
      } on Object catch (error) {
        debugPrint('Work timeline reminder sync failed: $error');
      }
    }
  }

  Future<void> _applySyncRequest(_TimelineSyncRequest request) async {
    await initialize();
    if (!_initialized || kIsWeb) return;

    if (!request.breakReminderEnabled && !request.batchReminderEnabled) {
      if (_disabledStateApplied) return;
      await cancelTimelineReminders();
      _disabledStateApplied = true;
      return;
    }

    _disabledStateApplied = false;
    await cancelTimelineReminders();

    if (request.breakReminderEnabled) {
      await _scheduleBreakReminders(request.now);
    }
    if (request.batchReminderEnabled) {
      await _scheduleBatchReminders(request.plan, request.now);
    }
  }

  Future<void> cancelTimelineReminders() async {
    if (!_initialized || kIsWeb) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      final id = notification.id;
      final isBreakReminder =
          id >= _breakBaseId && id < _breakBaseId + _notificationSlots;
      final isBatchReminder =
          id >= _batchBaseId && id < _batchBaseId + _notificationSlots;
      if (isBreakReminder || isBatchReminder) {
        await _plugin.cancel(id);
      }
    }
  }

  Future<void> _scheduleBreakReminders(DateTime now) async {
    var index = 0;
    for (final marker in WorkSchedule.markers) {
      if (marker.title != 'Break') continue;
      final reminderTime = marker.time
          .onDate(now)
          .add(const Duration(minutes: 2));
      if (!reminderTime.isAfter(now.add(const Duration(minutes: 1)))) {
        continue;
      }
      await _schedule(
        id: _breakBaseId + index,
        when: reminderTime,
        title: 'Update your score',
        body: 'Break time: add what you have made so pace can be recalculated.',
      );
      index++;
    }
  }

  Future<void> _scheduleBatchReminders(
    WorkTimelinePlan plan,
    DateTime now,
  ) async {
    final limit = math.min(plan.nextBatchStarts.length, _notificationSlots);
    for (var i = 0; i < limit; i++) {
      final start = plan.nextBatchStarts[i];
      if (!start.isAfter(now.add(const Duration(minutes: 1)))) continue;
      final units =
          i == plan.nextBatchStarts.length - 1 && plan.lastBatchAmount > 0
              ? plan.lastBatchAmount
              : plan.perBatch;
      await _schedule(
        id: _batchBaseId + i,
        when: start,
        title: 'Start next batch',
        body:
            units > 0
                ? 'Plan this batch for about $units units.'
                : 'Start the next planned batch now.',
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !when.isAfter(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Break score and batch pacing reminders.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

class _TimelineSyncRequest {
  const _TimelineSyncRequest({
    required this.plan,
    required this.breakReminderEnabled,
    required this.batchReminderEnabled,
    required this.now,
  });

  final WorkTimelinePlan plan;
  final bool breakReminderEnabled;
  final bool batchReminderEnabled;
  final DateTime now;
}
