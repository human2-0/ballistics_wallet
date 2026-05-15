import 'package:ballistics_wallet_flutter/models/work_schedule.dart';
import 'package:flutter/material.dart';

class WorkScheduleCard extends StatelessWidget {
  const WorkScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final breaks = WorkSchedule.markers
        .where((marker) => marker.title == 'Break')
        .map((marker) => '${marker.time.label} ${marker.detail}')
        .join('  |  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_timeline_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Default timeline: ${WorkSchedule.start.label} - ${WorkSchedule.finish.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ScheduleInfoRow(
            icon: Icons.coffee_outlined,
            label: 'Breaks',
            value: breaks,
          ),
          const SizedBox(height: 6),
          _ScheduleInfoRow(
            icon: Icons.cleaning_services_outlined,
            label: 'Cleaning',
            value: 'Starts ${WorkSchedule.cleaningStart.label}',
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children:
                  WorkSchedule.segments
                      .map(
                        (segment) => Expanded(
                          flex: segment.durationMinutes,
                          child: Container(
                            height: 10,
                            color: _segmentColor(segment.type),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _segmentColor(WorkScheduleSegmentType type) {
    switch (type) {
      case WorkScheduleSegmentType.breakTime:
        return Colors.blue[300]!;
      case WorkScheduleSegmentType.cleaning:
        return Colors.teal[300]!;
      case WorkScheduleSegmentType.work:
        return Colors.deepOrange[300]!;
    }
  }
}

class _ScheduleInfoRow extends StatelessWidget {
  const _ScheduleInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.blueGrey[700]),
      const SizedBox(width: 8),
      SizedBox(
        width: 64,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
    ],
  );
}
