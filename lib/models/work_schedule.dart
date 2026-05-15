// ignore_for_file: public_member_api_docs

import 'dart:math';

import 'package:flutter/material.dart';

enum WorkScheduleSegmentType { work, breakTime, cleaning }

@immutable
class WorkScheduleTime {
  const WorkScheduleTime(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesAfterMidnight => hour * 60 + minute;

  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

@immutable
class WorkScheduleSegment {
  const WorkScheduleSegment({
    required this.title,
    required this.detail,
    required this.start,
    required this.end,
    required this.type,
  });

  final String title;
  final String detail;
  final WorkScheduleTime start;
  final WorkScheduleTime end;
  final WorkScheduleSegmentType type;

  int get startMinute => start.minutesAfterMidnight;
  int get endMinute => end.minutesAfterMidnight;
  int get durationMinutes => endMinute - startMinute;
}

@immutable
class WorkScheduleMarker {
  const WorkScheduleMarker({
    required this.time,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final WorkScheduleTime time;
  final String title;
  final String detail;
  final IconData icon;
}

class WorkSchedule {
  const WorkSchedule._();

  static const start = WorkScheduleTime(14, 0);
  static const finish = WorkScheduleTime(22, 0);
  static const cleaningStart = WorkScheduleTime(21, 45);

  static const segments = [
    WorkScheduleSegment(
      title: 'Start work',
      detail: 'Set up the station and begin the main production block.',
      start: WorkScheduleTime(14, 0),
      end: WorkScheduleTime(16, 0),
      type: WorkScheduleSegmentType.work,
    ),
    WorkScheduleSegment(
      title: 'Short break',
      detail: '15 minute break.',
      start: WorkScheduleTime(16, 0),
      end: WorkScheduleTime(16, 15),
      type: WorkScheduleSegmentType.breakTime,
    ),
    WorkScheduleSegment(
      title: 'Production block',
      detail: 'Back on target after the first break.',
      start: WorkScheduleTime(16, 15),
      end: WorkScheduleTime(18, 0),
      type: WorkScheduleSegmentType.work,
    ),
    WorkScheduleSegment(
      title: 'Main break',
      detail: '30 minute break.',
      start: WorkScheduleTime(18, 0),
      end: WorkScheduleTime(18, 30),
      type: WorkScheduleSegmentType.breakTime,
    ),
    WorkScheduleSegment(
      title: 'Production block',
      detail: 'Mid-shift production window.',
      start: WorkScheduleTime(18, 30),
      end: WorkScheduleTime(20, 0),
      type: WorkScheduleSegmentType.work,
    ),
    WorkScheduleSegment(
      title: 'Short break',
      detail: '15 minute break.',
      start: WorkScheduleTime(20, 0),
      end: WorkScheduleTime(20, 15),
      type: WorkScheduleSegmentType.breakTime,
    ),
    WorkScheduleSegment(
      title: 'Final production block',
      detail: 'Last target window before cleaning starts.',
      start: WorkScheduleTime(20, 15),
      end: WorkScheduleTime(21, 45),
      type: WorkScheduleSegmentType.work,
    ),
    WorkScheduleSegment(
      title: 'Cleaning time',
      detail: 'Cleaning begins and the shift is wrapping up.',
      start: WorkScheduleTime(21, 45),
      end: WorkScheduleTime(22, 0),
      type: WorkScheduleSegmentType.cleaning,
    ),
  ];

  static const markers = [
    WorkScheduleMarker(
      time: WorkScheduleTime(14, 0),
      title: 'Start',
      detail: 'Shift begins.',
      icon: Icons.play_arrow,
    ),
    WorkScheduleMarker(
      time: WorkScheduleTime(16, 0),
      title: 'Break',
      detail: '15 min',
      icon: Icons.coffee,
    ),
    WorkScheduleMarker(
      time: WorkScheduleTime(18, 0),
      title: 'Break',
      detail: '30 min',
      icon: Icons.restaurant,
    ),
    WorkScheduleMarker(
      time: WorkScheduleTime(20, 0),
      title: 'Break',
      detail: '15 min',
      icon: Icons.coffee,
    ),
    WorkScheduleMarker(
      time: WorkScheduleTime(21, 45),
      title: 'Cleaning',
      detail: 'Cleaning starts',
      icon: Icons.cleaning_services,
    ),
    WorkScheduleMarker(
      time: WorkScheduleTime(22, 0),
      title: 'Finish',
      detail: 'Shift ends.',
      icon: Icons.flag,
    ),
  ];

  static int get totalMinutes =>
      finish.minutesAfterMidnight - start.minutesAfterMidnight;

  static double progressFor(DateTime now) {
    final elapsed = _minutesAfterMidnight(now) - start.minutesAfterMidnight;
    return (elapsed / totalMinutes).clamp(0.0, 1.0);
  }

  static WorkScheduleSegment? currentSegment(DateTime now) {
    final minute = _minutesAfterMidnight(now);
    for (final segment in segments) {
      if (minute >= segment.startMinute && minute < segment.endMinute) {
        return segment;
      }
    }
    return null;
  }

  static DateTime nextEvent(DateTime now) {
    final todayEvents =
        markers
            .map((marker) => marker.time.onDate(now))
            .where((event) => event.isAfter(now))
            .toList();

    if (todayEvents.isNotEmpty) {
      return todayEvents.first;
    }

    final tomorrow = now.add(const Duration(days: 1));
    return start.onDate(tomorrow);
  }

  static String eventNameFor(DateTime event) {
    final minute = _minutesAfterMidnight(event);
    final marker = markers.firstWhere(
      (marker) => marker.time.minutesAfterMidnight == minute,
      orElse: () => markers.first,
    );
    return marker.title;
  }

  static String formatDuration(Duration duration) {
    final safeDuration = Duration(seconds: max(0, duration.inSeconds));
    final hours = safeDuration.inHours;
    final minutes = safeDuration.inMinutes.remainder(60);
    final seconds = safeDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  static int _minutesAfterMidnight(DateTime dateTime) =>
      dateTime.hour * 60 + dateTime.minute;
}
